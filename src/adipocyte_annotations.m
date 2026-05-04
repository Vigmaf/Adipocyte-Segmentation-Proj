function[bboxes, labels, masks]=adipocyte_annotations(mask_file,min_area)
%convert one binary mask file into:
%bboxes: Nx4
% labels:: Nx1 cat
%masks: HxWxN logical
if nargin < 2
    min_area=50;
end


M=imread(mask_file);
%convert to binary foreground
if ndims(M)==3
    BW=any(M>0,3);
else
    BW=M>0;
end
%remove tiny noise and fill the holes
BW=bwareaopen(BW, min_area);
BW=imfill(BW,"holes");

%connected components = separate adipocytes
CC=bwconncomp(BW,8);
stats=regionprops(CC,"BoundingBox","Area");

keep =find([stats.Area] >= min_area);
num_obj= numel(keep);


[h,w] =size(BW);
masks=false(h,w,num_obj);
bboxes=zeros(num_obj,4);

for k=1:num_obj
    idx=keep(k);

    tmp=false(h,w);
    tmp(CC.PixelIdxList{idx})=true;


    masks(:,:,k)=tmp;
    bboxes(k,:)=stats(idx).BoundingBox;
end

class_name="adipocyte";
labels=categorical(repmat(class_name, num_obj,1),class_name);
end
