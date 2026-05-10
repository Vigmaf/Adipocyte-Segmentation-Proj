clear; clc;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
load(fullfile(projectRoot, "cv_folds_full_aug.mat"));  % loads folds + pairedTable
target_size = [512 512];
min_area = 20;
class_name = "adipocyte";
input_size = [512 512 3];
detector_name = "light-resnet18-coco";

outputDir = fullfile(projectRoot, "results", "cv_aug_models");
if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

% For first test use 1.
% After fold 1 works, change this to 1:4 or 2:4.
foldsToRun = 2:4;

for fold = foldsToRun

    fprintf("\n==============================\n");
    fprintf("Training CV fold %d\n", fold);
    fprintf("==============================\n");

    T_train_cl = folds(fold).trainTable;
    T_val_cl   = folds(fold).valTable;

    fprintf("Before filtering:\n");
    fprintf("Train samples: %d\n", height(T_train_cl));
    fprintf("Val samples:   %d\n", height(T_val_cl));

    T_train_cl = filter_nonempty_solov2(T_train_cl, target_size, min_area);
    T_val_cl   = filter_nonempty_solov2(T_val_cl, target_size, min_area);

    fprintf("After filtering:\n");
    fprintf("Train samples: %d\n", height(T_train_cl));
    fprintf("Val samples:   %d\n", height(T_val_cl));

    ads_train = arrayDatastore((1:height(T_train_cl))', "IterationDimension", 1);
    ads_val   = arrayDatastore((1:height(T_val_cl))', "IterationDimension", 1);

    % Training data WITH augmentation
    ds_train = transform(ads_train, @(idx) make_SOLOv2_cell_aug(idx, T_train_cl, target_size, min_area));

    % Validation data WITHOUT augmentation
    ds_val = transform(ads_val, @(idx) make_SOLOv2_cell(idx, T_val_cl, target_size, min_area));

    % Quick sample check
    sample_train = read(ds_train);
    reset(ds_train);

    sample_val = read(ds_val);
    reset(ds_val);
    disp("Train sample OK");
    disp(size(sample_train{1}));
    disp(size(sample_train{2}));
    disp(size(sample_train{3}));
    disp(size(sample_train{4}));
    disp("Validation sample OK");
    disp(size(sample_val{1}));
    disp(size(sample_val{2}));
    disp(size(sample_val{3}));
    disp(size(sample_val{4}));

    %check
    checkpointDir = fullfile(outputDir, sprintf("checkpoints_fold%d", fold));

    if ~exist(checkpointDir, "dir")
        mkdir(checkpointDir);
    end


    % SOLOv2 network
    net = solov2(detector_name, class_name, InputSize=input_size);
    options = trainingOptions("adam", ...
    InitialLearnRate=1e-4, ...
    MaxEpochs=5, ...
    MiniBatchSize=1, ...
    Shuffle="every-epoch", ...
    ValidationData=ds_val, ...
    ValidationFrequency=25, ...
    Verbose=true, ...
    VerboseFrequency=10, ...
    Plots="training-progress", ...
    CheckpointPath=checkpointDir, ...
    ExecutionEnvironment="auto");
    % Train
    [detector, info] = trainSOLOV2(ds_train, net, options);

    saveName = sprintf("trainedSOLOV2_cv_fold%d_aug.mat", fold);
    save(fullfile(outputDir, saveName), ...
        "detector", "info", "options", ...
        "T_train_cl", "T_val_cl", ...
        "target_size", "min_area", ...
        "-v7.3");

    fprintf("Saved: %s\n", fullfile(outputDir, saveName));
    clear detector net info ds_train ds_val ads_train ads_val
end

disp("Finished selected CV folds.");

function data = make_SOLOv2_cell_aug(idx, T, target_size, min_area)

    data = make_SOLOv2_cell(idx, T, target_size, min_area);

    I      = data{1};
    boxes  = data{2};
    labels = data{3};
    masks  = data{4};

    if isempty(boxes) || isempty(masks)
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

    % Light intensity jitter, image only
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

    % Recalculate bounding boxes after augmentation
    [newBoxes, keep] = boxesFromMasks(masks);

    if isempty(newBoxes)
        data = make_SOLOv2_cell(idx, T, target_size, min_area);
        return;
    end

    masks = masks(:,:,keep);

    if size(labels,1) == numel(keep)
        labels = labels(keep,:);
    else
        labels = labels(:,keep);
    end

    data{1} = I;
    data{2} = newBoxes;
    data{3} = labels;
    data{4} = masks;
end


function [boxes, keep] = boxesFromMasks(masks)

    n = size(masks,3);
    boxes = zeros(0,4);
    keep = false(n,1);

    for i = 1:n
        M = masks(:,:,i);

        [rows, cols] = find(M);

        if isempty(rows)
            continue;
        end

        x1 = min(cols);
        x2 = max(cols);
        y1 = min(rows);
        y2 = max(rows);

        w = x2 - x1 + 1;
        h = y2 - y1 + 1;

        boxes(end+1,:) = [x1, y1, w, h];
        keep(i) = true;
    end
end



function T_clean = filter_nonempty_solov2(T, target_size, min_area)
    keep = false(height(T), 1);
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
    fprintf("Removed %d empty/broken samples.\n", sum(~keep));
end