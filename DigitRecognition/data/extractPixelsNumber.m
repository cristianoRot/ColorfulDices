% extractPixelsNumber.m - Cristiano Rotunno 914317

function out = extractPixelsNumber(image)        
    ycbcr = rgb2ycbcr(image);
    Y = ycbcr(:,:,1);

    if mean(Y) > 0.5
        Y = 1 - Y;
    end
    
    Y_denoised = medfilt2(Y, [3 3]);
        
    BW = imbinarize(Y_denoised, 'adaptive', 'Sensitivity', 0.5);

    BW = imopen(BW, strel('disk', 1));

    borderPixels = [BW(1,:), BW(end,:), BW(:,1)', BW(:,end)'];

    if mean(borderPixels) > 0.5
        BW = ~BW;
    end
        
    labels = bwlabel(BW);

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

    out = imclose(out, strel('disk', 2));
end

function v = getDistToCenter(label)
    [h, w] = size(label);
    centerImg = [w / 2, h / 2];
    
    [r, c] = find(label);
    
    if isempty(r) || length(r) < (h * w * 0.02)
        v = inf;
        return;
    end

    distances = sqrt((c - centerImg(1)).^2 + (r - centerImg(2)).^2);
    v = min(distances);
end