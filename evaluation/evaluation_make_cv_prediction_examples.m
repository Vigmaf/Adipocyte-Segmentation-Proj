clear;clc;close all;

projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";

modelDir = fullfile(projectRoot, "results", "cv_aug_models");
outDir = fullfile(projectRoot, "results", "prediction_examples");

if ~exist(outDir,"dir")
    mkdir(outDir);
end

scrthr=0.20;
% how many examples
experfold = 10;
for fold = 1:4
    fprintf("\nGenerating examples for fold %d...\n", fold);
    modelPath = fullfile(modelDir, sprintf("trainedSOLOV2_cv_fold%d_aug.mat", fold));

    S = load(modelPath, "detector", "T_val_cl", "target_size", "min_area");

    detector = S.detector;
    T_val_cl = S.T_val_cl;
    target_size = S.target_size;
    min_area = S.min_area;


    %using spaced samples from validation set
    sampleIdx = round(linspace(1,height(T_val_cl),experfold));

    for k =1:numel(sampleIdx)
        idx = sampleIdx(k);
        data=make_SOLOv2_cell(idx, T_val_cl,target_size,min_area);

        I=data{1};
        gtMasks = data{4};
        gtUnion = any(gtMasks,3 );
        
        try 
            [predMasks, ~, scores] = segmentObjects(detector, I, Threshold=scrthr);
        catch ME
            fprintf("Prediction failed fold %d sample %d: %s\n", fold, idx, ME.message);
            predMasks = false([target_size 0]);
            scores = [];
        end

        if isempty(predMasks)
            predMasks = false([target_size 0]);
        end


        predUnion = any(predMasks, 3);
        gtCount = size(gtMasks,3);
        predCount = size(predMasks,3);

        comparison = makeComparisonOverlay(I,gtUnion,predUnion);

         fig = figure("Visible", "off", "Position", [100 100 1400 900]);

        tiledlayout(2,2, "Padding", "compact", "TileSpacing", "compact");


        nexttile;
        imshow(I);
        title(sprintf("Original image | Fold %d | Sample %d", fold, idx));

        nexttile;
        imshow(labeloverlay(I, gtUnion));
        title(sprintf("Ground truth mask | GT count: %d", gtCount));

        nexttile;
        imshow(labeloverlay(I, predUnion));
        title(sprintf("Predicted mask | Predicted count: %d", predCount));

        nexttile;
        imshow(comparison);
        title("Comparison overlay: green = TP, red = missed, blue = false positive");

        outName = sprintf("fold%d_sample%d_prediction_example.png", fold, idx);
        exportgraphics(fig, fullfile(outDir, outName), "Resolution", 150);
        close(fig);
        fprintf("saved: %s\n",outName);
    end
    clear detector
end

fprintf("\nFinished generating prediciton examples.\n");
function overlay = makeComparisonOverlay(I, gtMask, predMask)

    I = im2double(I);
    if size(I,3)==1
        I = repmat(I,[1 1 3]);
    end
    overlay=I;
    tp=gtMask & predMask;
    fn = gtMask & ~predMask;
    fp = ~gtMask & predMask;

    alpha = 0.45;

    % green = true positive
    overlay(:,:,1) = overlay(:,:,1) .* (1 - alpha * tp);
    overlay(:,:,2) = overlay(:,:,2) .* (1 - alpha * tp) + alpha * tp;
    overlay(:,:,3) = overlay(:,:,3) .* (1 - alpha * tp);

    % red = missed ground truth
    overlay(:,:,1) = overlay(:,:,1) .* (1 - alpha * fn) + alpha * fn;
    overlay(:,:,2) = overlay(:,:,2) .* (1 - alpha * fn);
    overlay(:,:,3) = overlay(:,:,3) .* (1 - alpha * fn);

    % blue = false positive
    overlay(:,:,1) = overlay(:,:,1) .* (1 - alpha * fp);
    overlay(:,:,2) = overlay(:,:,2) .* (1 - alpha * fp);
    overlay(:,:,3) = overlay(:,:,3) .* (1 - alpha * fp) + alpha * fp;
end