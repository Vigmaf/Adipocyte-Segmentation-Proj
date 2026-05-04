clear;clc;

projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
load(fullfile(projectRoot, "folderSplit.mat"), "T_train", "T_val", "T_test");

min_area=50;


%finding usable samples
[keep_train, count_train] = find_empty_samples(T_train, min_area);
[keep_val, count_val] = find_empty_samples(T_val, min_area);
[keep_test, count_test] = find_empty_samples(T_test, min_area);

%print usmmary
% Find usable samples
[keep_train, count_train] = find_empty_samples(T_train, min_area);
[keep_val,   count_val]   = find_empty_samples(T_val,   min_area);
[keep_test,  count_test]  = find_empty_samples(T_test,  min_area);

% Print summary
fprintf("Train before: %d | after: %d | removed: %d\n", ...
    height(T_train), nnz(keep_train), nnz(~keep_train));

fprintf("Val   before: %d | after: %d | removed: %d\n", ...
    height(T_val), nnz(keep_val), nnz(~keep_val));

fprintf("Test  before: %d | after: %d | removed: %d\n", ...
    height(T_test), nnz(keep_test), nnz(~keep_test));


%show removed ones
disp("Removed training samples:");
disp(T_train(~keep_train, {'imageFile','maskFile','Source'}));

disp("Removed validation samples:");
disp(T_val(~keep_val, {'imageFile','maskFile','Source'}));

disp("Removed test samples:");
disp(T_test(~keep_test, {'imageFile','maskFile','Source'}));

%keep only valiud onse
T_train_cl = T_train(keep_train, :);

T_val_cl  = T_val(keep_val, :);
T_test_cl = T_test(keep_test, :);




keep_train=keep_train(:);
keep_val=keep_val(:);
keep_test=keep_test(:);


T_train_cl=T_train(keep_train,:);
T_val_cl=T_val(keep_val,:);
T_test_cl=T_test(keep_test,:);


%save
save(fullfile(projectRoot, "folderSplit_clean_50.mat"), ...
    "T_train_cl","T_val_cl","T_test_cl");
disp("Saved: folderSplit_clean_50.mat");