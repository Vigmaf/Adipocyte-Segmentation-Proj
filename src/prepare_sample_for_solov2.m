function[Iout, bboxes_out, labels_out, masks_out]=prepare_sample_for_solov2(image_file, mask_file, target_size, min_area)
%prepare one image/ask pair for SOLOv2

if nargin < 3
    target_size = [1024 1024];
end
if nargin < 4
    min_area=50;
end

%read the image
I=imread(image_file);
%read annotation from mask
[bboxes, labels_out,masks]=adipocyte_annotations(mask_file,min_area);


origH=size(I,1);
origW=size(I,2);

newH=target_size(1);
newW=target_size(2);

%resize image
Iout=imresize(I,[newH newW]);
%converting grayscale to 3-channel
if ndims(Iout) == 2
    Iout=repmat(Iout, [1 1 3]);
end
num_obj =size(masks,3);

%handling empty cases
if num_obj ==0
    bboxes_out= zeros(0,4);
    labels_out=categorical(strings(0,1),"adipocyte");
    mask_out= false(newH,newW,0);
    return;
end

%resizins masks again (pls work this time)
masks_out=false(newH,newW, num_obj);
for k= 1:num_obj
    mk=masks(:,:,k);
    %convert to single resize and threshold back to logical
    mk_resized= imresize(single(mk), [newH newW], "nearest") >0.5;

    masks_out(:,:,k)= mk_resized;
end

%rescaling boxes
scaleX=newW/origW;
scaleY=newH/origH;


bboxes_out=bboxes;
bboxes_out(:,1)=bboxes(:,1)*scaleX;
bboxes_out(:,2) = bboxes(:,2) * scaleY;
bboxes_out(:,3) = bboxes(:,3) * scaleX;
bboxes_out(:,4) = bboxes(:,4) * scaleY;

%check, resized union should not be empty
if nnz(any(masks, 3))>0&&nnz(any(masks_out,3))==0
    error("prepare_sample_for_solov2 gave emplty masks");
end
end