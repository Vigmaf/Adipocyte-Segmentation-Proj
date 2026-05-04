function data = augment_solov2_cell(data)
%UNTITL
%   data  ={I, bboxes, labels, masks} 
I=data{1};
bboxes=data{2};
labels=data{3};
masks=data{4};


H=size(I,1);
W=size(I,2);

% If sample is already empty, return it unchanged
if isempty(bboxes) || isempty(labels) || isempty(masks) || size(masks,3) == 0
    data = {I, bboxes, labels, masks};
    return;
end

% Tryk to 
for attempt = 1:5

    % milder geometric augmentation 
    tform = randomAffine2d( ...
        "Rotation", [-15 15], ...
        "XReflection", true, ...
        "YReflection", true, ...
        "Scale", [0.95 1.05], ...
        "XTranslation", [-10 10], ...
        "YTranslation", [-10 10]);

    rout = affineOutputView([H W], tform, "BoundsStyle", "sameAsInput");

    % Warp image
    I_aug = imwarp(I, tform, "OutputView", rout);

    % Safety: keep 3 channels
    if ndims(I_aug) == 2
        I_aug = repmat(I_aug, [1 1 3]);
    end

    %  mild intensity augmentation 
    I_aug = im2single(I_aug);

    % brightness
    delta = -0.06 + 0.12*rand();
    I_aug = I_aug + delta;

    % contrast
    alpha = 0.9 + 0.2*rand();
    I_aug = (I_aug - 0.5)*alpha + 0.5;

    % clamp and convert back
    I_aug = min(max(I_aug, 0), 1);
    I_aug = im2uint8(I_aug);

    % warp masks and rebuild boxes safely 
    num_obj = size(masks, 3);

    masks_tmp  = false(H, W, num_obj);
    bboxes_tmp = zeros(num_obj, 4);
    valid      = false(num_obj, 1);

    for k = 1:num_obj
        mk = masks(:,:,k);

        mk_aug = imwarp(single(mk), tform, ...
            "OutputView", rout, ...
            "InterpolationMethod", "nearest") > 0.5;

        % Remove tiny fragments introduced by warping
        mk_aug = bwareaopen(mk_aug, 20);

        if nnz(mk_aug) == 0
            continue;
        end

        % Keep largest connected component only
        CC = bwconncomp(mk_aug, 8);
        stats = regionprops(CC, "Area", "BoundingBox");

        if isempty(stats)
            continue;
        end

        [~, best] = max([stats.Area]);

        mk_clean = false(H, W);
        mk_clean(CC.PixelIdxList{best}) = true;

        bb = stats(best).BoundingBox;

        % Reject degenerate boxes
        if bb(3) < 2 || bb(4) < 2
            continue;
        end

        masks_tmp(:,:,k) = mk_clean;
        bboxes_tmp(k,:)  = bb;
        valid(k) = true;
    end

    % Keep only valid instances
    if any(valid)
        masks_aug = masks_tmp(:,:,valid);

        % Force 3D even if only one object remains
        if ndims(masks_aug) == 2
            masks_aug = reshape(masks_aug, H, W, 1);
        end

        bboxes_aug = bboxes_tmp(valid, :);
        labels_aug = labels(valid);

        % Final consistency check
        if size(bboxes_aug,1) == size(masks_aug,3) && size(bboxes_aug,2) == 4
            data = {I_aug, bboxes_aug, labels_aug, masks_aug};
            return;
        end
    end
end

% If all augmentation attempts fail, use original sample unchanged
data = {I, bboxes, labels, masks};
end