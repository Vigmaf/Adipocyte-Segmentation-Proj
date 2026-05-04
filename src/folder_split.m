clear; clc;

projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
load(fullfile(projectRoot, "TAll.mat"), "TAll");
% split, manually decided by me to give somewhat good percentages
 
train_sources = ["GTEX_1024","MTC","GTEX","omental_2"];
val_sources = ["TCGA","blood_vessels"];
test_sources  = ["omental_1","MTC2"];

T_train = TAll(ismember(TAll.Source, train_sources), :);
T_val = TAll(ismember(TAll.Source, val_sources),:);
T_test = TAll(ismember(TAll.Source, test_sources),:);

% -- Print summary --
n_All = height(TAll);
n_train = height(T_train);
n_val = height(T_val); 
n_test = height(T_test);

fprintf("Total: %d\n", n_All);
fprintf("Train: %d (%.2f%%)\n", n_train, 100*n_train/n_All);
fprintf("Val: %d (%.2f%%)\n", n_val, 100*n_val/n_All);
fprintf("Test : %d (%.2f%%)\n", n_test, 100*n_test/n_All);

disp(" ");
disp("Train count by source:");
disp(groupcounts(T_train, "Source"));

disp("Validation counts by source");
disp(groupcounts(T_val, "Source"));

disp("Test counts by source");
disp(groupcounts(T_test, "Source"));

% -- Safety check: no overlap --
overlap_train_val = intersect(T_train.imageFile, T_val.imageFile);
overlap_train_test= intersect(T_train.imageFile, T_test.imageFile);
overlap_val_test = intersect(T_val.imageFile, T_test.imageFile);

fprintf("\nOverlap checks: \n");
fprintf("Train-Val overlap : %d\n", numel(overlap_train_val));
fprintf("Train-Test overlap : %d\n", numel(overlap_train_test));
fprintf("Val-Test overlap : %d\n", numel(overlap_val_test));

% -- Save the split 
save(fullfile(projectRoot, "folderSplit.mat"),"T_train","T_val","T_test","train_sources",...
    "val_sources","test_sources");

disp("Saved: folderSplit.mat");