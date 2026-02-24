% segmentDigit.m - Cristiano Rotunno 914317

% k = number of clusters used in kmeans
function [prediction, score, out, labels, kmeansLabels, num_cluster, vectorFeatures] = segmentDigit(image)    
    minK = 3;
    maxK = 6;

    bestScore = -inf;
    
    for k = minK:maxK
        [pred_, score_, out_, labels_, kmeansLabels_, num_cluster_, vectorFeatures_] = segmentDigitByKMeans(image, k);

        if score_ > bestScore
            bestScore = score_;
            
            kmeansLabels = kmeansLabels_;
            labels = labels_;
            out = out_;
            prediction = pred_;
            score = score_;
            num_cluster = num_cluster_;
            vectorFeatures = vectorFeatures_;
        end
    end
end

function [prediction, score, out, labels, kmeansLabels, num_cluster, vectorFeatures] = segmentDigitByKMeans(image, k)    
    [high, width, ~] = size(image);
    image = im2double(image);
    
    data = getFeaturesVector(image);
    
    if size(data, 1) < k
        kmeansLabels = zeros(high, width);
        labels = zeros(high, width);
        out = false(high, width);
        prediction = 0; 
        score = -inf; 
        num_cluster = k;
        vectorFeatures = zeros(1, 7);
        return;
    end

    kmeansLabels = kmeans(data, k, 'Replicates', 3, 'MaxIter', 500);
    kmeansLabels = reshape(kmeansLabels, high, width);

    totalArea = high * width;
    labels = separateClusters(kmeansLabels);
    labels = getLabelsFiltered(labels, totalArea);

    bestLabel = -1;
    bestPred = -1;
    bestScore = -inf;
    bestFeatures = [];

    for i = 1:max(labels(:))
        im = labels == i;
        im = adjustNumberImage(im, 10);

        dist = getDistToCenter(im);
        features = extractFeatures(im);

        [pred_, scores_, ~] = predict(features);
        score_ = max(scores_);

        finalScore = score_ * exp(-dist / 80);

        if finalScore > bestScore
            bestScore = finalScore;
            bestLabel = i;
            bestPred = pred_;
            bestFeatures = features;
        end
    end

    if bestLabel == -1
        out = false(high, width);
        vectorFeatures = zeros(1, 7);
        prediction = 0;
        score = -inf;
        num_cluster = k;
        return;
    end
    
    out = adjustNumberImage(labels == bestLabel, 10);
    vectorFeatures = bestFeatures;
    prediction = bestPred;
    score = bestScore;
    num_cluster = k;
end

function out = separateClusters(kmeansLabels)
    [h, w] = size(kmeansLabels);
    out = zeros(h, w);
    nextID = 1;
    k = max(kmeansLabels(:));
    
    for c = 1:k
        currentClusterMask = (kmeansLabels == c);
        
        [objLabels, numObjs] = bwlabel(currentClusterMask);
        
        for n = 1:numObjs
            out(objLabels == n) = nextID;
            nextID = nextID + 1;
        end
    end
end

function labels = getLabelsFiltered(labels, totalArea)
    numLabels = max(labels(:));
    
    for i = 1:numLabels
        regionMask = (labels == i);
        adjustedMask = adjustNumberImage(regionMask, 10);
        
        currentArea = sum(adjustedMask(:));
        a = currentArea / totalArea;

        if a < 0.03 || a > 0.12
            labels(labels == i) = 0;
            continue;
        end

        vec = extractFeatures(adjustedMask);
        
        solidity = vec(2);
        eccentricity = vec(3);
        circularity = vec(4);
        invExtent = vec(5);
        radialVariance = vec(6);
        hu1 = vec(7);
        
        % Validation ranges from current datasets
        isSolidityWrong = solidity < 0.35 || solidity > 0.90;
        isEccentricityWrong = eccentricity < 0.50 || eccentricity > 0.99; 
        isCircularityWrong = circularity < 0.10 || circularity > 0.80;
        isInvExtentWrong = invExtent < 0.20 || invExtent > 0.75; 
        isRadialVarianceWrong = radialVariance < 0.25 || radialVariance > 0.60;
        isHu1Wrong = hu1 < 0.15 || hu1 > 0.65;

        if isSolidityWrong || isEccentricityWrong || isCircularityWrong || isInvExtentWrong || isRadialVarianceWrong || isHu1Wrong
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
    invBw = ~bw;
    [L, numRegions] = bwlabel(invBw, 4);
    
    stats = regionprops(L, 'Area', 'PixelIdxList');
    
    if isempty(stats), return; end
    
    areas = [stats.Area];
    [~, mainBackgroundIdx] = max(areas);
    
    for i = 1:numRegions
        if i ~= mainBackgroundIdx && stats(i).Area <= T
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