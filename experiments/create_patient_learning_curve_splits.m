clear; clc;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
load(fullfile(projectRoot, "pairedTable_full_cv_with_patientID.mat")); % loads T
rng(1);

T.Source = string(T.Source);
T.PatientID = string(T.PatientID);
T.PatientKey = string(T.PatientKey);

missingRows = ismissing(T.PatientID) | ismissing(T.PatientKey);
for i = find(missingRows)'
    [~, name, ~] = fileparts(T.imageFile(i));
    T.PatientID(i) = string(name);
    T.PatientKey(i) = string(T.Source(i)) + "_" + string(name);
end

%fixed 
testFraction = 0.20;
sources = unique(T.Source);
testGroups = strings(0,1);
trainPoolGroups= strings(0,1);


for s =1:numel(sources)
    src = sources(s);
    idx = T.Source==src;
    groups = unique(T.PatientKey(idx));
    groups= groups(randperm(numel(groups)));

    nTest = max(1,round(testFraction * numel(groups)));
    testGroups=[testGroups; groups(1:nTest)];
    trainPoolGroups= [trainPoolGroups; groups(nTest+1:end)];
end

T_test = T(ismember(T.PatientKey, testGroups),:);
T_train_pool = T(ismember(T.PatientKey, trainPoolGroups),:);
%learncurve tra size
trainFractions = [0.25 0.50 1.00];

splits =struct();
for f =1:numel(trainFractions)
    frac= trainFractions(f);
    selectGroups= strings(0,1);
    for s = 1:numel(sources)
        src = sources(s);

        srcGroups = unique(T_train_pool.PatientKey(T_train_pool.Source == src));
        srcGroups= srcGroups(randperm(numel(srcGroups)));
        nSelect = max(1, round(frac * numel(srcGroups)));
        selectGroups =[selectGroups; srcGroups(1:nSelect)];
    end
    T_train = T_train_pool(ismember(T_train_pool.PatientKey, selectGroups),:);

    splits(f).fraction=frac;
    splits(f).name = sprintf("train_%d_percent", round(frac*100));
    splits(f).trainTable = T_train;
    splits(f).testTable= T_test;
    overlap = intersect(unique(T_train.PatientKey),unique(T_test.PatientKey));

    fprintf("\nSplit: %s\n", splits(f).name);
    fprintf("Training samples: %d\n", height(T_train));
    fprintf("Fixed test samples: %d\n", height(T_test));
    fprintf("Training patient groups: %d\n", numel(unique(T_train.PatientKey)));
    fprintf("Test patient groups: %d\n", numel(unique(T_test.PatientKey)));
    fprintf("Patient overlap train/test: %d\n", numel(overlap));




    if ~isempty(overlap)
        warning("patien leak");
        disp(overlap);
    end
end
save(fullfile(projectRoot, "patient_learning_curve_splits.mat"), ...
    "splits", "T_train_pool", "T_test", "testGroups", "trainPoolGroups");

fprintf("\nSaved patient_learning_curve_splits.mat\n");