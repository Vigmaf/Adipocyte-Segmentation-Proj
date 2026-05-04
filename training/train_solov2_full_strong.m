clear;clc;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
%loading cleafed full split
load(fullfile(projectRoot, "folderSplit_clean.mat"),"T_train_cl","T_val_cl");
target_size=[1024 1024];
min_area=50;

%1full train /validation sets
T_train_full=T_train_cl;
T_val_full=T_val_cl;

fprintf("Full train samples: %d\n", height(T_train_full));
fprintf("Full val samples  : %d\n", height(T_val_full));

% 2)Building datastores
ads_train = arrayDatastore((1:height(T_train_full))', "IterationDimension", 1);
ads_val   = arrayDatastore((1:height(T_val_full))',   "IterationDimension", 1);
ds_train = transform(ads_train, @(idx) make_SOLOv2_cell(idx, T_train_full, target_size, min_area));
ds_val   = transform(ads_val,   @(idx) make_SOLOv2_cell(idx, T_val_full,   target_size, min_area));

%check
sample_train = read(ds_train);
reset(ds_train);
sample_val = read(ds_val);
reset(ds_val);

disp("Train sample OK");
disp(size(sample_train{1}));
disp(size(sample_train{2}));
disp(class(sample_train{3}));
disp(size(sample_train{4}));

disp("Validation sample OK");
disp(size(sample_val{1}));
disp(size(sample_val{2}));
disp(class(sample_val{3}));
disp(size(sample_val{4}));
%solov22 mod
class_names = "adipocyte";
input_size = [1024 1024 3];
detector_name = "resnet50-coco";

net = solov2(detector_name, class_names, InputSize=input_size);
%4  options
options = trainingOptions("sgdm", ...
    InitialLearnRate = 1e-3, MaxEpochs = 10, ...
    MiniBatchSize = 1, ...
    GradientThreshold = 35, ...
    Shuffle = "every-epoch", ...
    ValidationData = ds_val, ValidationFrequency = 25, Verbose = true, ...
    VerboseFrequency = 10, ...
    Plots = "training-progress", ExecutionEnvironment = "auto", ...
    ResetInputNormalization = false);
%train 5
[detector_full, info_full] = trainSOLOV2( ...
    ds_train, net, options, ...
    FreezeSubNetwork = "none");
%sav
save(fullfile(projectRoot, "trainedSOLOV2_full_strong.mat"), ...
    "detector_full", "info_full", "options");

disp("Saved: trainedSOLOV2_full_strong.mat");