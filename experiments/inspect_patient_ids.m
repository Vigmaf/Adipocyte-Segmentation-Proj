clear; clc;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";

load(fullfile(projectRoot, "pairedTable_full_cv.mat"));  % 
T = T_full;
patientID=string(T.Source);
for i = 1:height(T)
    [~,name,~] = fileparts(T.imageFile(i));
    source = string(T.Source(i));

    patientID(i)=extractPatientID(name,source);
end


T.PatientID=patientID(:);
T.PatientKey = T.Source + "_" + T.PatientID;

fprintf("total images: %d\n",height(T));
fprintf("unique patient/sample groups: %d\n",numel(unique(T.PatientKey)));
fprintf("\nGroups per source: \n");
sources = unique(T.Source);

for s = 1:numel(sources)
    src = sources(s)
    inx = T.Source ==src;
    fprintf("\nSource: %s\n",src);
    fprintf("Images: %d\n",sum(inx));
    fprintf("unique groups: %d\n",numel(unique(T.PatientKey(inx))));
    exampleGroups= unique(T.PatientKey(inx))
    disp(exampleGroups(1:min(10,numel(exampleGroups))));
end



save(fullfile(projectRoot, "pairedTable_full_cv_with_patientID.mat"), "T");
fprintf("\nSaved pairedTable_full_cv_with_patientID.mat\n"); %more for debug

function pid = extractPatientID(fileName, source)
    fileName = string(fileName);
    source = string(source);

    switch source
        case {"MTC","MTC2"}
            token = regexp(fileName, "^[^_]+", "match", "once");
        case "TCGA"
            
            token = regexp(fileName, "TCGA[-_A-Za-z0-9]+", "match", "once");
            if strlength(token) == 0
                token = regexp(fileName, "^[^_]+", "match", "once");
            end

        case "GTEX_1024"
            
            token = regexp(fileName, "GTEX-[A-Za-z0-9]+", "match", "once");
            if strlength(token) == 0
                token = regexp(fileName, "^[^_]+", "match", "once");
            end

        case "UNET_ORIGINAL"
            token = regexp(fileName, "GTEX-[A-Za-z0-9]+", "match", "once");
            if strlength(token) == 0
                token = regexp(fileName, "^[^_]+", "match", "once");
            end

        otherwise
            token=regexp(fileName, "^[^_]+","match","once");
    end
    if isempty(token) || strlength(token) == 0
        token = fileName;
    end

    pid = string(token);
end
