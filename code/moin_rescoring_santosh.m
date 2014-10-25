function [ds_moinONsantosh,scores_all_moinONsantosh] = moin_rescoring_santosh(model_selected,relpos_patch_normal_selected,voc_test,ds_santosh,w_sel,suffix)
% function for rescoring bounding box of santosh by parts defined by moin

addpath(genpath('bcp_release/'));

ds_moinONsantosh = ds_santosh;
%scores_all_rescored = [];
clear scores_all_moinONsantosh;

ds_adrs = [];
ds_ind = 1;
for i=1:length(ds_santosh)
    if ~isempty(ds_santosh{i})
        for j = 1:size(ds_santosh{i},1)
            ds_adrs(ds_ind,:) = [i,j];
            santosh_score(ds_ind,:) = ds_santosh{i}(j,5);
            ds_ind = ds_ind + 1;
        end
    end
end

%disp('checking Moins parts inside box');
try
    %load('data/scores_all_rescored.mat','scores_all_rescored');  
    load(['../data/result/',suffix,'.mat'],'scores_all_moinONsantosh','ds_moinONsantosh');
catch
    parfor i = 1:length(ds_santosh)%length(voc_test)
        disp([int2str(i),'/',int2str(length(voc_test))])

        if ~isempty(ds_santosh{i})

            im_current = imread(voc_test(i).im);
            gt_bbox_all = ds_santosh{i}(:,1:4);
            
%            tmp = compute_score_per_sample_IIT(ds_santosh{i},gt_bbox_all,relpos_patch_normal_selected,im_current, model_selected);
            addpath(genpath('bcp_release/'));
            tmp = compute_score_per_sample(ds_santosh{i},gt_bbox_all,relpos_patch_normal_selected,im_current, model_selected)
            
            scores_all_moinONsantosh{i} = tmp;
        end
    end

moin_score_all = vertcat(scores_all_moinONsantosh{:});
moin_score = normalize_matrix(moin_score_all);
score_all = [santosh_score,moin_score] * w_sel;
%
for ind = 1:ds_ind-1
    i = ds_adrs(ind,1);
    j = ds_adrs(ind,2);
    ds_moinONsantosh{i}(j,5) = score_all(ind);
end
%Empty results for the last examples
difference = length(ds_santosh)-length(ds_moinONsantosh);
if difference > 0
    for i = 1:difference
        ds_moinONsantosh{length(ds_moinONsantosh)+i} = [];
        scores_all_moinONsantosh{length(scores_all_moinONsantosh)+i} = [];
    end
end

    save(['../data/result/',suffix,'.mat'],'scores_all_moinONsantosh','ds_moinONsantosh');
end