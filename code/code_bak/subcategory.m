%function [I bbox gtbox relpos_patch deform_param models models_all ps_detect sp_consist_mat sp_consis_score img_part] = demo_subcategory(VOCopts, ps, numPatches,coverage_thershold,dir_class,dir_neg,finalresdir,comp)
function [patch_per_comp] = subcategory(VOCopts, ps, numPatches,dir_class,dir_neg,voc_ng,category,component)
%
%by Moin
 
%Select random "patches" on each Positive image (belongs to this subcategory)
disp('auto_get_part_fast');
[I bbox gtbox] = auto_get_part_fast(VOCopts, ps, numPatches,0.25,0.75);

%Find relative position and Deformation Parameter for each Query patch
for i = 1:numPatches
    gt_bbox = gtbox{i}; part_bbox = bbox{i}(1:4);
    relpos_patch_normal{i} = relative_position(gt_bbox,part_bbox,1); %1 means normalized (regionlet)
end

%Train Examplar-LDA for each patch (Query)
addpath(genpath('bcp_release/'));
VOCopts.localdir = '/home/moin/Desktop/UW/all_UW/eccv14/data/bcp_elda/';
disp('orig_train_elda');
models = orig_train_elda(VOCopts, I, bbox, dir_class, dir_neg , 0, 1);
for mod = 1:length(models)
    models_all{mod} = models{1,mod}.model;
end

%Compute Deformation Parameter for each Query patch
for i = 1:numPatches
    mdl = models_all{i};
    im = imread(I{i});
     deform_param_patch{i} = deform_param(im,mdl,1); %MISSING: Now is fixed for all!!! [0.3 0.3]
end


%Run the fixed position detector on all Positive images and find Pos_score
disp('doing part inference on positive samples in Subcategory');
%par
for i = 1:length(ps)
    disp([int2str(i),'/',int2str(length(ps))])
    im_current = imread(ps{1,i}.I);
    gt_bbox = ps{1,i}.bbox;

    bbox_current = inverse_relative_position_all(gt_bbox,relpos_patch_normal,1);
    [detection_loc , ap_score , sp_score ] = part_inference_inbox(im_current, models_all, bbox_current);
    ps_detect{i}.scores = num2cell(horzcat(ap_score{:}).*horzcat(sp_score{:}));
    ps_detect{i}.parts = detection_loc;
end

ps_score = zeros(length(ps),numPatches);
for prt = 1:numPatches
    for img = 1:length(ps)
        ps_score(img,prt) = ps_detect{img}.scores{prt};
    end
end

disp('Hard Negative mining');
model_tmp = load('/projects/grail/santosh/objectNgrams/results/ngram_models/horse/kmeans_6/mountain_horse_super/mountain_horse_super_parts.mat','models');
model_santosh = model_tmp.models{component};
thresh = model_santosh.thresh;
[ng_detect] = run_patches_inside_santosh_on_negative(model_santosh,models_all,voc_ng_train,relpos_patch_normal,thresh);

ng_score = zeros(length(voc_ng_train),numPatches);
%
for img = 1:length(voc_ng_train)
    if  ~isempty(ng_detect{img})
        for prt = 1:numPatches
            ng_score(img,prt) = ng_detect{img}.scores{prt};
        end
    end
end

disp('Scoring parts based on spatial/appearence consistancy')

top_num_part = 10;

[part_selected, score_all, discriminantion_score ,representation_score] = select_patch_inbox(ps_score,ng_score,top_num_part);
%%Visualization 
% % score_all = patch_per_comp.score_all; part_selected= patch_per_comp.part_selected; 
% % I=patch_per_comp.I; bbox=patch_per_comp.bbox; gtbox=patch_per_comp.gtbox; top_num_part = 50;
% % discriminantion_score = patch_per_comp.discriminantion_score; representation_score=patch_per_comp.representation_score;
% visualization_score = score_all; 
% [sortedValues_part,sortIndex_part] = sort(visualization_score,'descend'); 
% maxIndex_part = sortIndex_part(1:top_num_part);
% close all; 
% figure; clf; 
% part_selected_ind = find(part_selected); 
% for part=1:min(25,length(part_selected_ind))
%     pa = maxIndex_part(part); 
%     subplot(sqrt(25),sqrt(25),part); showboxes(imread(I{pa}), [bbox{pa}(1:4); gtbox{pa}]); 
%     str1 = {['DIS:',num2str(discriminantion_score(pa),2),',REP:',num2str(representation_score(pa),2)]}; text(1,1,str1)
% end
% savehere = ['/projects/grail/moinnabi/eccv14/data/part_selected/',category,'/',dir_class,'/',num2str(component),'/'];
% mkdir([savehere,'figures/']);
% saveas(gcf, [savehere,'figures/','queryPatches_.jpg']);
% %close all;
% % 
% for part = 1:top_num_part
%     close all;
%     pa = maxIndex_part(part);
%     %pa = sortIndex_part(part);
% % for pa = 1:numPatches
%     figure;
%     figsize = 5;
%     top_num_img = min(figsize*(figsize-1),length(ps));
%     
%     [~,sortIndex_img] = sort([ps_score(:,pa);ng_score(:,pa)],'descend');
%     
%     %[sortedValues_img,sortIndex_img] = sort([ps_score(:,prt);ng_score(:,prt)],'descend');
%     maxIndex_img = sortIndex_img(1:top_num_img);
% 
%     subplot(figsize,figsize,1); showboxes(imread(I{pa}), [bbox{pa}(1:4); gtbox{pa}]); %rectangle('Position',[1,1,size(imread(I{pa}),2),size(imread(I{pa}),1)],'EdgeColor','b','linewidth', 5);
%     subplot(figsize,figsize,2); visualizeHOGpos(models_all{pa}.w)
%     subplot(figsize,figsize,3); visualizeHOGneg(models_all{pa}.w)
%     sp_consist_binary = ones(length(ps),numPatches);
%     for imgind = 1:top_num_img
%         
%         if maxIndex_img(imgind) <= length(ps)
%             img = imread(ps{1,maxIndex_img(imgind)}.I);
%             gt_bbox = ps{1,maxIndex_img(imgind)}.bbox(1:4);
%             part_bbox = ps_detect{max
Index_img(imgind)}.parts{pa}(1:4);
%             if sp_consist_binary(maxIndex_img(imgind),pa)
%                 subplot(figsize,figsize,imgind+figsize);
%                 showboxes(img,[part_bbox;gt_bbox]); rectangle('Position',[1,1,size(img,2),size(img,1)],'EdgeColor','g','linewidth', 3);
%             else
%                 subplot(figsize,figsize,imgind+figsize);
%                 showboxes(img,[part_bbox;gt_bbox]); rectangle('Position',[1,1,size(img,2),size(img,1)],'EdgeColor','r','linewidth', 3);
%             end
%         else
%             img = imread(voc_ng_train(maxIndex_img(imgind)-length(ps)).im);
%             %gt_bbox = ps{1,maxIndex_img(imgind)}.bbox(1:4);
%             part_bbox = ng_detect{maxIndex_img(imgind)-length(ps)}.parts{pa}(1:4);
%             subplot(figsize,figsize,imgind+figsize);
%             showboxes(img,part_bbox); rectangle('Position',[1,1,size(img,2),size(img,1)],'EdgeColor','y','linewidth', 3);
%         end
%     end
%     savehere = ['/projects/grail/moinnabi/eccv14/data/part_selected/',category,'/',dir_class,'/',num2str(component),'/'];
%     mkdir([savehere,'figures/']);
%     saveas(gcf, [savehere,'figures/','detectedPatches_part_fixedpos',num2str(part),'.png']);
% end


%
patch_per_comp.I = I;
patch_per_comp.bbox = bbox;
patch_per_comp.gtbox = gtbox;
patch_per_comp.relpos_patch_normal = relpos_patch_normal;
%patch_per_comp.relpos_patch_fixed = relpos_patch_fixed;
patch_per_comp.deform_param_patch = deform_param_patch;
patch_per_comp.models = models;
patch_per_comp.models_all =models_all;
%
patch_per_comp.ps = ps;            
patch_per_comp.ps_detect = ps_detect;
patch_per_comp.ng_detect = ng_detect;
% patch_per_comp.sp_consistant_parts = sp_consistant_parts;
% patch_per_comp.sp_consist_binary = sp_consist_binary;
% patch_per_comp.sp_consist_score = sp_consist_score;
% patch_per_comp.sp_consist_score_all = sp_consist_score_all;
% patch_per_comp.app_consist_score = app_consist_score;
% patch_per_comp.app_consist_binary = app_consist_binary;
% patch_per_comp.ng_score = ps_app_score;
patch_per_comp.ps_score = ps_score;
patch_per_comp.ng_score = ng_score;
patch_per_comp.discriminantion_score = discriminantion_score;
patch_per_comp.representation_score = representation_score;
patch_per_comp.part_selected = part_selected;
patch_per_comp.score_all = score_all;

