function data  = make_SOLOv2_cell(idx, T_split, target_size, min_area)
%return one SOLOv2 training sample as:
% {image, bboxes, labels, masks}

if iscell(idx) %if input is cell array
    idx = idx{1};
end

[I,bboxes, labels, masks] = prepare_sample_for_solov2(...
    T_split.imageFile(idx), T_split.maskFile(idx),target_size,min_area);

data ={I,bboxes,labels,masks};



end
%%
% This function packages one sample into the exact form SOLOv2 wants, that is: [I, bboxes, labels, masks]
% SOLOv2 wants: the image, when the objects are, what class they belong to, the object masks
% so this function is like a little packer taking all pieces and putting htem into one box