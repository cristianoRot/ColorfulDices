% extractFeatures.m - Cristiano Rotunno 914317

function vector = extractFeatures(bw)
    stats = regionprops(bw, 'EulerNumber', 'Solidity', 'Extent', 'Eccentricity', 'Perimeter', 'Area');

    if isempty(stats)
        vector = zeros(1, 6);
        return;
    end

    s = stats(1);

    holes = 1 - s.EulerNumber;
    solidity = s.Solidity;
    extent = s.Extent;
    eccentricity = s.Eccentricity;
    
    if s.Perimeter > 0
        circularity = (4 * pi * s.Area) / (s.Perimeter^2);
    else
        circularity = 0;
    end
    
    centroidDist = 0;
    if s.Area > 0
        [h, w] = size(bw);
        [r, c] = find(bw);
        dist = sqrt((mean(c) - w/2)^2 + (mean(r) - h/2)^2);
        centroidDist = dist / max(h, w);
    end

    vector = [holes, solidity, extent, eccentricity, circularity, centroidDist];
end