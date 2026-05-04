function [keep_mask, objcount] = find_empty_samples(T_split, min_area)
% check each sample and count how many object remain after preprocessing

if nargin < 2
    min_area=200;
end
n=height(T_split);
keep_mask=false(n,1);
objcount=zeros(n,1);
tic;
for i = 1:n
    [~,~,masks] = adipocyte_annotations(T_split.maskFile(i), min_area);
    objcount(i)=size(masks,3);
    keep_mask(i)=objcount(i)>0;

    if mod(i,10)==0||i==n
        elapsed=toc;
        fprintf("Processed %d/%d samples (%.1f%%) | elapsed: %.1f s\n", ...
            i,n,100*i/n, elapsed);
    end






end