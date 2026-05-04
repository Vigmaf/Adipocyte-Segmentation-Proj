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

gt_count   = zeros(n,1);
pred_count = zeros(n,1);
dice_score = zeros(n,1);
jacc_score = zeros(n,1);
for i = 1:n
    I = read_and_resize_img(T_test_cl.imageFile(i), target_size);

    [~, ~, ~, gt_masks] = prepare_sample_for_solov2( ...
        T_test_cl.imageFile(i), ...
        T_test_cl.maskFile(i), ...
        target_size, ...
        min_area);

    [pred_masks, ~, ~] = segmentObjects( ...
        detector_full, I, ...
        Threshold = score_threshold, ...
        MaskThreshold = 0.30, ...
        SelectStrongest = true);

    gt_union   = any(gt_masks, 3);
    pred_union = any(pred_masks, 3);
    gt_count(i)   = size(gt_masks, 3);
    pred_count(i) = size(pred_masks, 3);
    dice_score(i) = dice(pred_union, gt_union);
    jacc_score(i) = jaccard(pred_union, gt_union);
end
results_table = table( ...
    T_test_cl.imageFile, ...
    T_test_cl.Source, ...
    gt_count, ...
    pred_count, ...
    dice_score, ...
    jacc_score, ...
    'VariableNames', {'imageFile','Source','GTcount','PredCount','Dice','Jaccard'});



disp(results_table(1:min(10, height(results_table)), :));
fprintf("\n===== TEST OVERLAP SUMMARY (thr = %.2f) =====\n", score_threshold);
fprintf("Mean Dice      : %.4f\n", mean(dice_score));
fprintf("Median Dice    : %.4f\n", median(dice_score));
fprintf("Mean Jaccard   : %.4f\n", mean(jacc_score));
fprintf("Median Jaccard : %.4f\n", median(jacc_score));



[G, source_names] =findgroups(results_table.Source);
source_summary=table(source_names, ...
    splitapply(@mean, results_table.Dice, G), ...
    splitapply(@mean, results_table.Jaccard, G), ...
    splitapply(@mean, results_table.GTcount, G), ...
    splitapply(@mean, results_table.PredCount, G), ...
    'VariableNames',{'Source','MeanDice','MeanJaccard','MeanGT','MeanPred'});
disp(source_summary);
save(fullfile(projectRoot, "solov2_test_dice_jaccard.mat"), ...
    "results_table","source_summary","score_threshold");
disp("saved solov2_test_dice_jaccard.mat");