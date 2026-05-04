function folderReport(folderPath)
% folderReport(folderPath)
% Prints file counts by extension and shows example filenames.
% Works reliably with string arrays in R2024a.

D = dir(folderPath);
D = D(~[D.isdir]);

if isempty(D)
    fprintf("Folder is empty: %s\n", folderPath);
    return;
end

names = string({D.name})';

% extension using fileparts (most reliable)
ext = strings(size(names));
for i = 1:numel(names)
    [~,~,e] = fileparts(names(i));
    if e == ""
        ext(i) = "<no_ext>";
    else
        ext(i) = lower(e); % includes dot, e.g. ".tif"
    end
end

T = table(ext);
disp("----- " + string(folderPath) + " -----");
disp(groupcounts(T,"ext"));

fprintf("\nExamples (first 15):\n");
disp(names(1:min(15,end)));
fprintf("\n");
end


%%
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
imagesRoot  = fullfile(projectRoot,"images","images");
masksRoot   = fullfile(projectRoot,"masks","masks");

% MTC2
folderReport(fullfile(imagesRoot,"images MTC2"));
folderReport(fullfile(masksRoot, "masks MTC2"));

% GTEX (non-1024)
folderReport(fullfile(imagesRoot,"images GTEX"));
folderReport(fullfile(masksRoot, "masks unet GTEX"));