clear; clc;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
load(fullfile(projectRoot, "pairedTable_full_cv.mat"));  % loads T_full
pairedTable = T_full;
rng(1);

% Shuffle first
pairedTable = pairedTable(randperm(height(pairedTable)), :);

% Stratified 4-fold CV by Source
K = 4;
cv = cvpartition(categorical(pairedTable.Source), "KFold", K);
folds = struct();
fprintf("Creating 4 cross-validation folds...\n\n");

for fold = 1:K

    trainIdx = training(cv, fold);
    valIdx   = test(cv, fold);

    trainTable = pairedTable(trainIdx, :);
    valTable   = pairedTable(valIdx, :);

    folds(fold).trainTable = trainTable;
    folds(fold).valTable   = valTable;

    fprintf("Fold %d:\n", fold);
    fprintf("Train samples: %d\n", height(trainTable));
    fprintf("Val samples:   %d\n", height(valTable));

    fprintf("Validation source distribution:\n");
    disp(tabulate(valTable.Source))

    fprintf("-----------------------------\n");
end

save(fullfile(projectRoot, "cv_folds_full_aug.mat"), "folds", "pairedTable");
fprintf("\nSaved cv_folds_full_aug.mat\n");