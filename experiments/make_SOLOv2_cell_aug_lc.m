function data = make_SOLOv2_cell_aug_lc(idx, T, target_size, min_area)

    if istable(idx)
        idx = idx{1,1};
    elseif iscell(idx)
        idx = idx{1};
    end

    idx = double(idx);

    data = make_SOLOv2_cell(idx, T, target_size, min_area);

    I      = data{1};
    boxes  = data{2};
    labels = data{3};
    masks  = data{4};

    if isempty(boxes) || isempty(masks) || size(masks,3) == 0
        return;
    end

    % Random 90-degree rotation
    k = randi([0 3]);
    if k > 0
        I = rot90(I, k);
        masks = rot90(masks, k);
    end

    % Random horizontal flip
    if rand < 0.5
        I = fliplr(I);
        masks = fliplr(masks);
    end

    % Random vertical flip
    if rand < 0.5
        I = flipud(I);
        masks = flipud(masks);
    end

    % Light intensity jitter, image only
    if rand < 0.5
        originalClass = class(I);

        I2 = im2single(I);
        factor = 0.85 + 0.30 * rand;
        offset = -0.05 + 0.10 * rand;

        I2 = I2 * factor + offset;
        I2 = min(max(I2, 0), 1);

        if strcmp(originalClass, "uint8")
            I = im2uint8(I2);
        elseif strcmp(originalClass, "uint16")
            I = im2uint16(I2);
        else
            I = I2;
        end
    end

    % Recalculate boxes after augmentation
    [newBoxes, keep] = boxesFromMasks_lc(masks);

    if isempty(newBoxes)
        return;
    end

    masks = masks(:,:,keep);

    if size(labels,1) == numel(keep)
        labels = labels(keep,:);
    end

    data{1} = I;
    data{2} = newBoxes;
    data{3} = labels;
    data{4} = masks;
end


function [boxes, keep] = boxesFromMasks_lc(masks)

    n = size(masks,3);
    boxes = zeros(0,4);
    keep = false(n,1);

    for i = 1:n
        M = masks(:,:,i);

        [rows, cols] = find(M);

        if isempty(rows)
            continue;
        end

        x1 = min(cols);
        x2 = max(cols);
        y1 = min(rows);
        y2 = max(rows);

        w = x2 - x1 + 1;
        h = y2 - y1 + 1;
        boxes(end+1,:) = [x1, y1, w, h];
        keep(i) = true;
    end
end