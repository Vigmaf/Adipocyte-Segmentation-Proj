clear; clc; close all;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
addpath(genpath(projectRoot));
load(fullfile(projectRoot, "patient_learning_curve_splits.mat")); % loading hte splits

target_size =[512 512];
input_size=[512 512 3];
min_area=20;
class_name = "adipocyte";
detector_name="light-resnet18-coco";

outputDir = fullfile(projectRoot, "results", "learning_curve_models");
if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

%
splitIdsToRun = 1:3;
for splitId = splitIdsToRun
    splitName = splits(splitId).name;
    T_train_cl = splits(splitId).trainTable;
    T_test_cl = splits(splitId).testTable;

    fprintf("before fiultering:\n");
    fprintf("Training samples: %d\n", height(T_train_cl));
    fprintf("Fixed test samples: %d\n", height(T_test_cl));

   T_train_cl = filter_nonempty_solov2(T_train_cl, target_size, min_area);
   T_test_cl = filter_nonempty_solov2(T_test_cl, target_size, min_area);

   fprintf("After filtering:\n");
   fprintf("Training samples: %d\n", height(T_train_cl));
   fprintf("Fixed test samples: %d\n", height(T_test_cl));

   ads_train = arrayDatastore((1:height(T_train_cl))', "IterationDimension", 1);
   ads_test  = arrayDatastore((1:height(T_test_cl))', "IterationDimension", 1);

   ds_train = transform(ads_train, @(idx) make_SOLOv2_cell_aug_lc(idx, T_train_cl, target_size, min_area));
   ds_test  = transform(ads_test,  @(idx) make_SOLOv2_cell(idx, T_test_cl, target_size, min_area));

   %check
   sample_train = read(ds_train);
   reset(ds_train);
   disp("Training sample OK");
    disp(size(sample_train{1}));
    disp(size(sample_train{2}));
    disp(size(sample_train{3}));
    disp(size(sample_train{4}));

    net = solov2(detector_name, class_name, InputSize=input_size);

    checkpointDir = fullfile(outputDir, "checkpoints_" + splitName);
    if ~exist(checkpointDir, "dir")
        mkdir(checkpointDir);
    end 

    options=trainingOptions("adam", InitialLearnRate=1e-4, MaxEpochs=5,MiniBatchSize=1, ...
        Shuffle="every-epoch",ValidationData=ds_test, ValidationFrequency=25,Verbose=true,VerboseFrequency=10,Plots="training-progress",CheckpointPath=checkpointDir, ExecutionEnvironment="auto");

    [detector, info] = trainSOLOV2(ds_train, net, options);
    saveName = sprintf("trainedSOLOV2_learning_curve_%s.mat",splitName);

    save(fullfile(outputDir, saveName), "detector","info","options","T_train_cl","T_test_cl","target_size","min_area","splitName","-v7.3");
    fprintf("Saved: %s\n", fullfile(outputDir, saveName));
    clear detector net info ds_train ds_test ads_train ads_test
end
disp("finished selectin leanr curve models");

function T_clean = filter_nonempty_solov2(T, target_size, min_area)
    keep = false(height(T),1);
    for i = 1:height(T)
        try
            data = make_SOLOv2_cell(i, T, target_size, min_area);

            boxes = data{2};
            masks = data{4};

            if ~isempty(boxes) && size(masks,3) > 0
                keep(i) = true;
            end
        catch
            keep(i) = false;
        end
    end
    T_clean = T(keep, :);
    fprintf("Removed %d empty/brokjen\n", sum(~keep));
end

function data = make_SOLOV2_cell_aug(idx, T, target_size, min_area)
    data = make_SOLOv2_cell(idx, T, target_size, min_area);
    I= data{1};
    boxes = data{2};
    labels = data{3};
    masks= data{4};

    if isempty(boxes) || isempty(masks) || size(masks,3) == 0
        return;
    end

    % Random 90-degree rotation
    k = randi([0 3]);
    if k > 0
        I = rot90(I, k);
        masks = rot90(masks, k);
    end

    % Random horizontal flip
    if rand < 0.5
        I = fliplr(I);
        masks = fliplr(masks);
    end

    % Random vertical flip
    if rand < 0.5
        I = flipud(I);
        masks = flipud(masks);
    end

    % Light intensity jitter, img only
    if rand < 0.5
        originalClass = class(I);

        I2 = im2single(I);
        factor = 0.85 + 0.30 * rand;
        offset = -0.05 + 0.10 * rand;

        I2 = I2 * factor + offset;
        I2 = min(max(I2, 0), 1);

        if originalClass == "uint8"
            I = im2uint8(I2);
        elseif originalClass == "uint16"
            I = im2uint16(I2);
        else
            I = I2;
        end
    end

    [newBoxes, keep]= boxesFromMasks(masks);
    if isempty(newBoxes)
        return;
    end
    masks = masks(:,:,keep);
    if size(labels, 1)==numel(keep)
        labels = labels(keep,:);
    end
    data{1}=I;
    data{2}=newBoxes;
    data{3}=labels;
    data{4}=masks;
end

function [boxes, keep] = boxesFromMasks(masks)

    n =  size(masks,3);
    boxes = zeros(0,4);
    keep=false(n,1);
    for i=1:n
        M=masks(:,:,i);
        [rows, cols] = find(M);
        if isempty(rows)
            continue;
        end

        x1=min(cols);
        x2=max(cols);
        y1=min(rows);
        y2=max(rows);

        w=x2-x1+1;
        h=y2-y1+1;
        boxes(end+1,:)=[x1,y1,w,h];
        keep(i)=true;
    end
end
