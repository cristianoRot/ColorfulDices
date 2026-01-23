% extractPixelsNumber.m - Cristiano Rotunno 914317

function [im1, imalabel, bw] = extractPixelsNumber(image)        
    ycbcr = rgb2ycbcr(image);
    Y = ycbcr(:,:,1);

    H = [ -1 -1 -1; 
          -1  9 -1; 
          -1 -1 -1 ];
    Y = imfilter(Y, H, 'replicate');

    im1 = Y;

    if mean(Y) > 0.5
        Y = 1 - Y;
    end
        
    BW = imbinarize(Y, 'adaptive', 'Sensitivity', 0.5);
    BW = imopen(BW, strel('disk', 1));

    borderPixels = [BW(1,:), BW(end,:), BW(:,1)', BW(:,end)'];

    if mean(borderPixels) > 0.5
        BW = ~BW;
    end
        
    labels = bwlabel(BW);

    imalabel = labels;

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

    bw = labels == numLabelIndex; 

    bw = imclose(bw, strel('disk', 3));
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