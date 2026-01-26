% extractPixelsNumber.m - Cristiano Rotunno 914317

function [KMlabels, KMbw, labels, out] = extractPixelsNumber(image)    
    [high, width, ~] = size(image);
    image = im2double(image);
    
    data = getFeaturesVector(image);

    k = 4;

    KMlabels = kmeans(data, k, 'Replicates', 3, 'MaxIter', 500);
    KMlabels = reshape(KMlabels, high, width);
    KMbw = getBWformLabel(KMlabels);

    labels = bwlabel(KMbw);
    labels = getLabelsFiltered(labels);

    numLabelIndex = -1;
    minDist = inf;

    for i = 1:max(labels(:))
        im = labels == i;

        dist = getDistToCenter(im);

        if minDist > dist
            numLabelIndex = i;
            minDist = dist;
        end

    end

    out = labels == numLabelIndex;
end

function bw = getBWformLabel(labels)
    [h, w] = size(labels);
    bw = zeros(h, w);

    % Add edges
    for r = 2:h - 1
        for c = 2:w - 1
            v = labels(r, c);

            v1 = labels(r, c - 1);
            v2 = labels(r, c + 1);
            v3 = labels(r + 1, c);
            v4 = labels(r - 1, c);
            
            if (v ~= v1) || (v ~= v2) || (v ~= v3) || (v ~= v4)
                bw(r, c) = 0;
            else
                bw(r, c) = 1;
            end
        end
    end

    bw = bw > 0;
end

function labels = getLabelsFiltered(labels)
    [h, w] = size(labels);
    for i = 1:max(labels(:))
        im = labels == i;
    
        regionArea = sum(im(:));
        totArea = h * w;

        minArea = totArea * 0.01;
        maxArea = totArea * 0.07;
    
        if regionArea == 0 || regionArea < minArea || regionArea > maxArea
            mask = labels ~= i;
            labels = labels .* mask;
        end
    end
end

function v = getDistToCenter(label)
    [h, w] = size(label);
    centerImg = [w / 2, h / 2];
    
    [r, c] = find(label);
    
    if isempty(r)
        v = inf;
        return;
    end

    meanC = mean(c);
    meanR = mean(r);
    
    v = sqrt((meanC - centerImg(1))^2 + (meanR - centerImg(2))^2);
end

function data = getFeaturesVector(image)
    lab = rgb2lab(image);

    rgb_vec = reshape(image, [], 3);
    lab_vec = reshape(lab, [], 3);

    data = [rgb_vec, lab_vec];

    min_val = min(data);
    max_val = max(data);
    range_val = max_val - min_val;
    
    range_val(range_val == 0) = 1;

    data = (data - min_val) ./ range_val;
end