clear; clc;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
%loading the entire trained detector
load(fullfile(projectRoot, "trainedSOLOV2_full_aug.mat"), "detector_full");
%loading cleaned validation split
load(fullfile(projectRoot, "folderSplit_clean.mat"), "T_val_cl");

cd(projectRoot);
addpath(genpath(projectRoot));

target_size=[1024 1024];
min_area=50;
%threshold (several)
thresholds=[0.30 0.40 0.50 0.60 0.70];
rng(1);
idx=randperm(height(T_val_cl),min(3,height(T_val_cl)));

for n=1:numel(idx)
    i=idx(n);

    I=read_and_resize_img(T_val_cl.imageFile(i), target_size);

    [~,~,~, gt_masks]= prepare_sample_for_solov2( ...
        T_val_cl.imageFile(i), ...
        T_val_cl.maskFile(i), ...
        target_size, ...
        min_area);

    fprintf("\validatrion sample %d\n", n);
    fprintf("image file: %s\n", T_val_cl.imageFile(i));
    fprintf("GT count: %d\n", size(gt_masks,3));

    figure;
    tiledlayout(1, numel(thresholds)+1, "Padding","compact","TileSpacing", "compact");

    

    %ground truth
    nexttile;
    imshow(insertObjectMask(I,gt_masks));
    title(sprintf("GT | %d", size(gt_masks,3)));


    for t = 1:numel(thresholds)
        thr = thresholds(t);
        [pred_masks, ~, pred_scores]=segmentObjects( ...
            detector_full, I, Threshold=thr, ...
            MaskThreshold=0.30, SelectStrongest=true);
        

        fprintf("thr=%.2f -> predicted=%d", thr, size(pred_masks,3));
        if ~isempty(pred_scores)
            fprintf(" | max score=%.4f | mean score= %.4f\n",max(pred_scores), ...
                mean(pred_scores));
        else
            fprintf(" | no scores\n");
        end
        nexttile;
        if isempty(pred_masks)
            imshow(I);
        else
            imshow(insertObjectMask(I,pred_masks));
        end
        title(sprintf("thr=%.2f | %d", thr, size(pred_masks,3)));
    end
end