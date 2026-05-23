clear;clc;close all;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
addpath(genpath(projectRoot));
modelDir = fullfile(projectRoot, "results", "learning_curve_models");
outDir = fullfile(projectRoot, "results", "metric_outputs");

if ~exist(outDir,"dir")
    mkdir(outDir);
end

scoreThr = 0.20;
iouThr = 0.50;

maxSamplesPerModel = inf;
modelFiles = ["trainedSOLOV2_learning_curve_train_25_percent.mat"
    "trainedSOLOV2_learning_curve_train_50_percent.mat"
    "trainedSOLOV2_learning_curve_train_100_percent.mat"];

summaryRows = table();

for m = 1:numel(modelFiles)
    modelPath = fullfile(modelDir, modelFiles(m));
    fprintf("\n================================\n");
    fprintf("evalutatin model:\n%s\n", modelFiles(m));
    fprintf("\n================================\n");
    if ~isfile(modelPath)
        error("model file not found: %s", modelPath);
    end

    S = load(modelPath, "detector", "T_train_cl", "T_test_cl","target_size","min_area","splitName");

    detector = S.detector;
    T_train_cl = S.T_train_cl;
    T_test_cl = S.T_test_cl;
    target_size = S.target_size;
    min_area = S.min_area;
    splitName = string(S.splitName);

    nSamples =height(T_test_cl);
    if isfinite(maxSamplesPerModel)
        nEval = min(maxSamplesPerModel, nSamples);
    else
        nEval = nSamples;
    end

    diceVals = nan(nEval,1);
    jaccVals = nan(nEval,1);
    gtCounts = zeros(nEval,1);
    predCounts = zeros(nEval,1);
    tpVals = zeros(nEval,1);
    fpVals = zeros(nEval,1);

    fnVals = zeros(nEval,1);


    for i =1:nEval
        data = make_SOLOv2_cell(i,T_test_cl, target_size, min_area);
        I=data{1};
        gtMasks = data{4};
        gtUnion = any(gtMasks,3);
        gtCounts(i) =size(gtMasks,3);


        try
            [predMasks, ~,~]= segmentObjects(detector, I, Threshold=scoreThr);
        catch ME
            fprintf("prediction failed model %s sample %d: %s\n",splitName,i,ME.message);
            predMasks=false([target_size 0]);
        end

        if isempty(predMasks)
            predMasks=false([target_size 0]);
        end


        predCounts(i)= size(predMasks, 3);
        predUnion = any(predMasks,3);

        intersection = nnz(gtUnion & predUnion);
        unionArea =nnz(gtUnion | predUnion);
        denomDice = nnz(gtUnion) + nnz(predUnion);


        if denomDice > 0
            diceVals(i) = 2* intersection / denomDice;
        end
        if unionArea > 0
            jaccVals(i) = intersection / unionArea;
        end

        [tp, fp, fn]= instanceMatchCounts_lc(gtMasks, predMasks, iouThr);

        tpVals(i)= tp;
        fpVals(i) = fp;
        fnVals(i) = fn;

        if mod(i, 10)==0
            fprintf("%s: evaluated %d / %d\n", splitName, i ,nEval);
        end
    end

    totalTP = sum(tpVals);
    totalFP = sum(fpVals);
    totalFN = sum(fnVals);


    precision = totalTP / max(totalTP + totalFP, eps);
    recall = totalTP / max(totalTP + totalFN, eps);
    f1 = 2 * precision * recall / max(precision + recall, eps);

    meanDice = mean(diceVals, "omitnan");
    meanJaccard = mean(jaccVals, "omitnan");
    gtTotal = sum(gtCounts);
    predTotal = sum(predCounts);
    absCountError = abs(predTotal - gtTotal);
    percentCountError = 100 * absCountError / max(gtTotal, eps);
    trainFraction = extractFraction(splitName);
    summaryRow = table( ...
        splitName, trainFraction, height(T_train_cl), nEval, ...
        scoreThr, iouThr, ...
        meanDice, meanJaccard, ...
        precision, recall, f1, ...
        gtTotal, predTotal, absCountError, percentCountError, ...
        'VariableNames', { ...
        'SplitName','TrainFraction','TrainingSamples','TestSamples', ...
        'ScoreThreshold','InstanceIoUThreshold', ...
        'MeanDice','MeanJaccard', ...
        'InstancePrecision','InstanceRecall','InstanceF1', ...
        'GroundTruthCount','PredictedCount','AbsCountError','PercentCountError'});

     summaryRows = [summaryRows; summaryRow];
     perImageTable = table( ...
        (1:nEval)', diceVals, jaccVals, gtCounts, predCounts, tpVals, fpVals, fnVals, ...
        'VariableNames', {'SampleIndex','Dice','Jaccard','GT_Count','Pred_Count','TP','FP','FN'});
     writetable(perImageTable, fullfile(outDir, sprintf("learning_curve_%s_per_image_metrics.csv", splitName)));

     fprintf("\nSummaryy for %s:\n",splitName);
     disp(summaryRow);
     clear detector
end

summaryRows = sortrows(summaryRows, "TrainFraction");
writetable(summaryRows, fullfile(outDir, "learning_curve_metrics_summary.csv"));
save(fullfile(outDir, "learning_curve_metrics_summary.mat"), "summaryRows");

disp("Final learning-curve summary:");
disp(summaryRows);
fprintf("\nSaved:\n%s\n", fullfile(outDir, "learning_curve_metrics_summary.csv"));

function frac = extractFraction(splitName)

    splitName = string(splitName);

    if contains(splitName, "25")
        frac = 0.25;
    elseif contains(splitName, "50")
        frac = 0.50;
    elseif contains(splitName, "100")
        frac = 1.00;
    else
        frac = NaN;
    end
end




function [tp, fp, fn] = instanceMatchCounts_lc(gtMasks, predMasks, iouThr)

    nGT = size(gtMasks,3);
    nPred=size(predMasks,3);
    if nGT ==0&& nPred==0
        tp=0;fp=0;fn=0;
        return;
    end

    if nGT==0
        tp=0;fp=nPred;fn=0;
        return;
    end

    if nPred ==0
        tp =0; fp=0;fn=nGT;
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
            end
        end
    end

    tp = 0;
    matchedPred= false(nPred,1);
    matchedGT=false(nGT,1);

    while true
        if isempty(iouMat)
            break;
        end

        [bestIoU, linearIdx] =max(iouMat(:));
        if isempty(bestIoU) || ~isscalar(bestIoU) || ~isfinite(bestIoU) || bestIoU < iouThr
            break;
        end

        [pIdx, gIdx] = ind2sub(size(iouMat), linearIdx);

        if ~matchedPred(pIdx) && ~matchedGT(gIdx)
            tp = tp+1;
            matchedPred(pIdx)=true;
            matchedGT(gIdx)= true;
        end
        iouMat(pIdx,:)= -inf;
        iouMat(:,gIdx) = -inf;
    end
    fp=nPred - tp;
    fn = nGT - tp;
end
