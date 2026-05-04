projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
cd(projectRoot);
addpath(genpath(projectRoot));

load(fullfile(projectRoot, "trainedSOLOV2_full_aug.mat"), "detector_full");
load(fullfile(projectRoot, "folderSplit_clean.mat"), "T_test_cl");

target_size = [1024 1024];
min_area = 50;
score_threshold = 0.20;
overlap_threshold = 0.50;

ads_truth = arrayDatastore((1:height(T_test_cl))', "IterationDimension", 1);
ads_pred  = arrayDatastore((1:height(T_test_cl))', "IterationDimension", 1);

ds_truth = transform(ads_truth, @(idx) make_truth_cell(idx, T_test_cl, target_size, min_area));
ds_pred  = transform(ads_pred,  @(idx) make_prediction_cell(idx, T_test_cl, detector_full, target_size, score_threshold));



% quick  check
truth_sample = read(ds_truth);
pred_sample  = read(ds_pred);
reset(ds_truth);
reset(ds_pred);

disp("Truth sample:");
disp(size(truth_sample{1}));
disp(class(truth_sample{2}));
disp("Prediction sample:");
disp(size(pred_sample{1}));
disp(class(pred_sample{2}));
disp(size(pred_sample{3}));




tic
metrics = evaluateInstanceSegmentation(ds_pred, ds_truth, overlap_threshold, Verbose=true);
toc

summary_tbl = summarize(metrics);
ap_tbl = averagePrecision(metrics);
area_ranges = [0 32^2; 32^2 96^2; 96^2 inf];
area_tbl = metricsByArea(metrics, area_ranges);
disp(" Sumary");
disp(summary_tbl);
disp(" AP ");
disp(ap_tbl);
disp(" METRICS BY AREA ");
disp(area_tbl);