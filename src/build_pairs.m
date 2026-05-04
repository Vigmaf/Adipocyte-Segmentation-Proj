function P = build_Pairs(imagesDir, masksDir, imgExt, maskExt)
% Pair files using exact basename match, but with source-specific
% extensions

imgFiles  = dir(fullfile(imagesDir, "*" + imgExt));
maskFiles = dir(fullfile(masksDir, "*" + maskExt));

imgMap = containers.Map;

for i = 1:numel(imgFiles)
    [~, base, ~] = fileparts(imgFiles(i).name);
    imgMap(base) = fullfile(imgFiles(i).folder, imgFiles(i).name);
end

imageFile = strings(0,1);
maskFile  = strings(0,1);

for i = 1:numel(maskFiles)
    [~, base, ~] = fileparts(maskFiles(i).name);
    if isKey(imgMap, base)
        imageFile(end+1,1) = imgMap(base);
        maskFile(end+1,1)  = fullfile(maskFiles(i).folder, maskFiles(i).name);
    end
end

P = table(imageFile, maskFile);
end