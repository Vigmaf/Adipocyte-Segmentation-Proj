clear; clc;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
load(fullfile(projectRoot, "trainedSOLOV2_full_aug.mat"), "detector_full");
load(fullfile(projectRoot, "folderSplit_clean.mat"), "T_test_cl");

cd(projectRoot);
addpath(genpath(projectRoot));



target_size = [1024 1024];
min_area = 50;
score_threshold = 0.20;

n = height(T_test_cl);

gt_count=zeros(n,1);
pred_count=zeros(n,1);
abs_err=zeros(n,1);
pct_err=zeros(n,1);



for i =1:n
    I=read_and_resize_img(T_test_cl.imageFile(i),target_size);
    [~, ~, ~, gt_masks] = prepare_sample_for_solov2(T_test_cl.imageFile(i), ...
        T_test_cl.maskFile(i), target_size,min_area);

    [pred_masks, ~, ~] = segmentObjects(detector_full, I,Threshold = score_threshold, ...
        MaskThreshold = 0.30, SelectStrongest = true);

    gt_count(i)   = size(gt_masks, 3);
    pred_count(i) = size(pred_masks, 3);

    abs_err(i)=abs(pred_count(i)-gt_count(i));
    if gt_count(i) > 0
    pct_err(i) = 100*abs_err(i)/gt_count(i);
else
    pct_err(i)=0;
end
end

res_tab=  table( ...
    T_test_cl.imageFile, ...
    T_test_cl.Source, ...
    gt_count, ...
    pred_count, ...
    abs_err, ...
    pct_err, ...
    'VariableNames', {'imageFile','Source','GTcount','PredCount','AbsError','PctError'});


disp(res_tab(1:min(10,height(res_tab)), :));


fprintf("\n===test count suymary (thr = %.2f)===\n", score_threshold);
fprintf("Mean GT count: %.2f\n", mean(gt_count));
fprintf("Mean predicted count: %.2f\n", mean(pred_count));
fprintf("Mean absolute erro: %.2f\n", mean(abs_err));
fprintf("Median absolute error: %.2f\n", median(abs_err));
fprintf("Mean percent error: %.2f%%\n", mean(pct_err));
fprintf("Median percent error: %.2f%%\n", median(pct_err));


%source level summ
[G, source_names] = findgroups(res_tab.Source);
source_summary = table(source_names, splitapply(@mean, ...
    res_tab.GTcount, G),splitapply(@mean, res_tab.PredCount, G), ...
    splitapply(@mean, res_tab.AbsError, G),splitapply(@mean, res_tab.PctError, G), ...
    'VariableNames', {'Source','MeanGT','MeanPred','MeanAbsError','MeanPctError'});

disp(source_summary);
save(fullfile(projectRoot, "solov2_test_count_metrics.mat"), ...
    "res_tab","source_summary","score_threshold");

disp("saved solov2_test_count_metrics.mat");