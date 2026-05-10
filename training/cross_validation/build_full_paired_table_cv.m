clear; clc;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
imageRoot = fullfile(projectRoot, "images", "images");
maskRoot  = fullfile(projectRoot, "masks", "masks");

% Clean canonical folder pairs.
folderPairs = [
    "images MTC",                  "masks MTC",                  "MTC"
    "images MTC2",                 "masks MTC2",                 "MTC2"
    "images TCGA",                 "masks TCGA",                 "TCGA"
    "images omental part 1",       "masks omental mets part 1",  "OMENTAL_1"
    "images omental part 2",       "masks omental mets part 2",  "OMENTAL_2"
    "images student project 1024", "masks student project 1024", "STUDENT_1024"
    "images GTEX 1024",            "masks unet GTEX 1024",      "GTEX_1024"
    "images Unet original",        "masks unet original",       "UNET_ORIGINAL"
];

T_full = table(strings(0,1), strings(0,1), strings(0,1), ...
    'VariableNames', {'imageFile','maskFile','Source'});
fprintf("Building full paired table...\n\n");

for k = 1:size(folderPairs,1)
    imgFolder  = fullfile(imageRoot, folderPairs(k,1));
    maskFolder = fullfile(maskRoot,  folderPairs(k,2));
    sourceName = folderPairs(k,3);

    P = makePairs(imgFolder, maskFolder, sourceName);
    fprintf("%-15s paired samples = %d\n", sourceName, height(P));
    T_full = [T_full; P];
end

fprintf("\nTotal paired samples: %d\n", height(T_full));

missingImages = sum(~isfile(T_full.imageFile));
missingMasks  = sum(~isfile(T_full.maskFile));
fprintf("Missing images: %d\n", missingImages);
fprintf("Missing masks:  %d\n", missingMasks);

disp(tabulate(T_full.Source))
save(fullfile(projectRoot, "pairedTable_full_cv.mat"), "T_full");
fprintf("\nSaved: pairedTable_full_cv.mat\n");


function P = makePairs(imgFolder, maskFolder, sourceName)

    imgT  = listFilesWithBase(imgFolder,  [".tif", ".tiff", ".png", ".jpg", ".jpeg"], "imageFile");
    maskT = listFilesWithBase(maskFolder, [".png", ".tif", ".tiff"], "maskFile");

    P = innerjoin(imgT, maskT, "Keys", "base");
    P.Source = repmat(sourceName, height(P), 1);
    P = P(:, {'imageFile','maskFile','Source'});
end


function T = listFilesWithBase(folderPath, extensions, fileColumnName)

    files = strings(0,1);
    bases = strings(0,1);
    for e = 1:numel(extensions)
        d = dir(fullfile(folderPath, "*" + extensions(e)));
        for i = 1:numel(d)
            fullPath = string(fullfile(d(i).folder, d(i).name));
            [~, baseName, ~] = fileparts(fullPath);
            files(end+1,1) = fullPath;
            bases(end+1,1) = string(baseName);
        end
    end

    T = table(bases, files, 'VariableNames', ["base", string(fileColumnName)]);
end