% extractPixelsNumber.m - Cristiano Rotunno 914317

function [KMlabels, labels, out] = extractPixelsNumber(image)    
    [high, width, ~] = size(image);
    image = im2double(image);
    
    data = getFeaturesVector(image);

    k = 6;

    KMlabels = kmeans(data, k, 'Replicates', 3, 'MaxIter', 500);
    KMlabels = reshape(KMlabels, high, width);

    labels = separateClusters(KMlabels);
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
    out = adjustNumberImage(out, 20);
end

function out = separateClusters(KMlabels)
    [h, w] = size(KMlabels);
    out = zeros(h, w);
    nextID = 1;
    k = max(KMlabels(:));
    
    for c = 1:k
        currentClusterMask = (KMlabels == c);
        
        [objLabels, numObjs] = bwlabel(currentClusterMask);
        
        for n = 1:numObjs
            out(objLabels == n) = nextID;
            nextID = nextID + 1;
        end
    end
end

function labels = getLabelsFiltered(labels)
    [h, w] = size(labels);
    totArea = h * w;
    
    stats = regionprops(labels, 'Area', 'Solidity');
    
    for i = 1:numel(stats)
        if stats(i).Area == 0, continue; end
        
        regionArea = stats(i).Area;
        solidity = stats(i).Solidity;

        isAreaWrong = regionArea < (totArea * 0.02) || regionArea > (totArea * 0.08);
        isNotSolid = solidity < 0.3; 

        if isAreaWrong || isNotSolid
            labels(labels == i) = 0;
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

function bw = adjustNumberImage(bw, T)
    filledAll = imfill(bw, 'holes');
    holesMask = filledAll & ~bw;

    stats = regionprops(holesMask, 'Area', 'PixelIdxList');
    
    for i = 1:length(stats)
        if stats(i).Area <= T
            bw(stats(i).PixelIdxList) = 1;
        end
    end
end

function data = getFeaturesVector(image)
    lab = rgb2lab(image);
    hsv = rgb2hsv(image);
    
    lab_vec = reshape(lab, [], 3);
    s_vec = reshape(hsv(:,:,2), [], 1);
    
    data = [lab_vec, s_vec];

    min_val = min(data);
    max_val = max(data);
    range_val = max_val - min_val;
    
    range_val(range_val == 0) = 1;

    data = (data - min_val) ./ range_val;
end