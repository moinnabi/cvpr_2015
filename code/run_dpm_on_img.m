function ds = run_dpm_on_img(model_santosh,im_current,thresh)

    addpath(genpath('dpm-voc-release5/'));
    [ds, bs] = imgdetect(im_current, model_santosh, thresh);
    if ~isempty(bs)
      %unclipped_ds = ds(:,1:4);
      [ds, ~, ~] = clipboxes(im_current, ds, bs);
      %unclipped_ds(rm,:) = [];

      % NMS
      ds = nms_tomasz(ds, 0.5);
      %ds = ds(I,:);
    end