clear; clc;close all;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
modelDir = fullfile(projectRoot, "results", "cv_aug_models");
outDir = fullfile(projectRoot, "results", "metric_outputs");

if ~exist(outDir, "dir")
    mkdir(outDir);
end
scoreThr=0.20;% same one as the previous thr020 metrics
iouThr=0.50; %instance matchin IoU thresodl

maxSamplesPerFold = inf;
summaryRows = [];
for fold =1:4
    fprintf("\n=======");
    fprintf("evaluating fold %d\n",fold);
    fprintf("\n=======");
    modelName = sprintf('trainedSOLOV2_cv_fold%d_aug.mat',fold);
    modelPath= fullfile(modelDir, modelName);
    fprintf("trying toload: \n%s\n",modelPath);
    if ~isfile(modelPath)
        error("Model file not found: %s",modelPath);
    end
    S=load(modelPath, "detector","T_val_cl","target_size","min_area");

    detector = S.detector;
    T_val_cl = S.T_val_cl;
    target_size=S.target_size;
    min_area=S.min_area;
    nSamples= height(T_val_cl);

    if isfinite(maxSamplesPerFold)
        nEval = min(maxSamplesPerFold, nSamples);
    else
        nEval =nSamples;
    end

    diceVals = nan(nEval,1);
    jaccVals = nan(nEval,1);
    gtCounts = zeros(nEval,1);
    predCounts = zeros(nEval,1);
    tpVals = zeros(nEval,1);
    fpVals = zeros(nEval,1);
    fnVals = zeros(nEval,1);

    for i = 1:nEval
        data=make_SOLOv2_cell(i, T_val_cl, target_size, min_area);
        I=data{1};
        gtMasks=data{4};
        gtUnion=any(gtMasks,3);
        gtCounts(i)= size(gtMasks,3);

        try
            [predMasks, ~, scores]= segmentObjects(detector, I, Threshold=scoreThr);
        catch ME
            fprintf("Prediction failed fold %d samples %d: %s\n",fold , i, ME.message);
            predMasks = false([target_size 01]);
            scores = [];
        end

        if isempty(predMasks)
            predMasks = false([target_size 0]);
        end

        predCounts(i) = size(predMasks,3);
        predUnion=any(predMasks,3);

        %dice/jaccard on union mask
        intersection = nnz(gtUnion & predUnion);
        unionArea = nnz(gtUnion | predUnion);

        denomDice= nnz(gtUnion) +nnz(predUnion);
        if denomDice > 0
            diceVals(i) = 2 * intersection / denomDice;
        end

        if unionArea > 0
            jaccVals(i) = intersection / unionArea;
        end
        %instance level matching
        [tp,fp,fn] = instanceMatchCounts(gtMasks, predMasks, iouThr);

        tpVals(i)=tp;
        fpVals(i)= fp;
        fnVals(i)= fn;

        if mod(i,10)==0
            fprintf("Fold %d: evaluated %d / %d\n", fold, i, nEval);
        end
    end

    totalTP=sum(tpVals);
    totalFP= sum(fpVals);
    totalFN = sum(fnVals);

    precision = totalTP / max(totalTP + totalFP, eps);
    recall = totalTP / max(totalTP + totalFN, eps);
    f1 = 2 * precision * recall / max(precision + recall, eps);

    meanDice = mean(diceVals, "omitnan");
    meanJaccard = mean(jaccVals, "omitnan");

    gtTotal =sum(gtCounts);
    predTotal =sum(predCounts);
    countErrorAbs=abs(predTotal - gtTotal);
    countErrorPct=100*countErrorAbs / max(gtTotal, eps);



    foldSummary = table( ...
        fold, nEval, scoreThr, iouThr, ...
        meanDice, meanJaccard, ...
        precision, recall, f1, ...
        gtTotal, predTotal, countErrorAbs, countErrorPct, ...
        'VariableNames', { ...
        'Fold','ValidationSamples','ScoreThreshold','InstanceIoUThreshold', ...
        'MeanDice','MeanJaccard', ...
        'InstancePrecision','InstanceRecall','InstanceF1', ...
        'GroundTruthCount','PredictedCount','AbsCountError','PercentCountError'});

    summaryRows = [summaryRows; foldSummary];

    perImageTable = table( ...
        (1:nEval)', diceVals, jaccVals, gtCounts, predCounts, tpVals, fpVals, fnVals, ...
        'VariableNames', {'SampleIndex','Dice','Jaccard','GT_Count','Pred_Count','TP','FP','FN'});

    writetable(perImageTable, fullfile(outDir, sprintf("cv_fold%d_per_image_metrics.csv", fold)));
    fprintf("\nFold %d summary:\n",fold);
    disp(foldSummary);
    clear detector
end

meanRow = table( ...
    0, sum(summaryRows.ValidationSamples), scoreThr, iouThr, ...
    mean(summaryRows.MeanDice, "omitnan"), ...
    mean(summaryRows.MeanJaccard, "omitnan"), ...
    mean(summaryRows.InstancePrecision, "omitnan"), ...
    mean(summaryRows.InstanceRecall, "omitnan"), ...
    mean(summaryRows.InstanceF1, "omitnan"), ...
    sum(summaryRows.GroundTruthCount), ...
    sum(summaryRows.PredictedCount), ...
    sum(summaryRows.AbsCountError), ...
    mean(summaryRows.PercentCountError, "omitnan"), ...
    'VariableNames', summaryRows.Properties.VariableNames);
meanRow.Fold = 999; % mean/total row
summaryTable = [summaryRows; meanRow];
writetable(summaryTable, fullfile(outDir, "cv_aug_metrics_summary.csv"));
save(fullfile(outDir, "cv_aug_metrics_summary.mat"), "summaryTable");
disp("Final CV summary:");
disp(summaryTable);
fprintf("\nSaved:\n%s\n", fullfile(outDir, "cv_aug_metrics_summary.csv"));


function [tp, fp, fn] = instanceMatchCounts(gtMasks, predMasks, iouThr)

    nGT = size(gtMasks, 3);
    nPred = size(predMasks, 3);

    if nGT == 0 && nPred == 0
        tp = 0; fp = 0; fn = 0;
        return;
    end

    if nGT == 0
        tp = 0; fp = nPred; fn = 0;
        return;
    end

    if nPred == 0
        tp = 0; fp = 0; fn = nGT;
        return;
    end

    iouMat = zeros(nPred, nGT);

    for p = 1:nPred
        P = predMasks(:,:,p);

        for g = 1:nGT
            G = gtMasks(:,:,g);

            interArea = nnz(P & G);
            unionArea = nnz(P | G);

            if unionArea > 0
                iouMat(p,g) = interArea / unionArea;
            else
                iouMat(p,g) = 0;
            end
        end
    end

    tp = 0;
    matchedPred = false(nPred,1);
    matchedGT = false(nGT,1);

    while true

        % stop if empty
        if isempty(iouMat)
            break;
        end

        [bestIoU, linearIdx] = max(iouMat(:));

        % stopping condition
        if isempty(bestIoU) || ~isscalar(bestIoU) || ~isfinite(bestIoU) || bestIoU < iouThr
            break;
        end

        [pIdx, gIdx] = ind2sub(size(iouMat), linearIdx);

        if ~matchedPred(pIdx) && ~matchedGT(gIdx)
            tp = tp + 1;
            matchedPred(pIdx) = true;
            matchedGT(gIdx) = true;
        end

        % Removing the matcher pred and GT from further matching
        iouMat(pIdx,:) = -inf;
        iouMat(:,gIdx) = -inf;
    end

    fp = nPred - tp;
    fn = nGT - tp;
end