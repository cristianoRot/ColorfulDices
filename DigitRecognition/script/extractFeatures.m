function vector = extractFeatures(bw)
    bw = logical(bw);
    
    stats = regionprops(bw, 'EulerNumber', 'Solidity', 'Eccentricity', ...
                             'Circularity', 'Perimeter', 'Area', ...
                             'MajorAxisLength', 'MinorAxisLength', ...
                             'Centroid');

    if isempty(stats)
        vector = zeros(1, 7);
        return;
    end

    s = stats(1);

    holes = 1 - s.EulerNumber;
    solidity = s.Solidity;
    eccentricity = s.Eccentricity;
    
    if s.Perimeter > 0
        circularity = (4 * pi * s.Area) / (s.Perimeter^2);
    else
        circularity = 0;
    end
    
    invExtent = s.Area / (s.MajorAxisLength * s.MinorAxisLength);
    [y, x] = find(bw);
    if ~isempty(x)
        distanze = sqrt((x - s.Centroid(1)).^2 + (y - s.Centroid(2)).^2);
        radialVariance = std(distanze) / mean(distanze);
    else
        radialVariance = 0;
    end

    % PRIMO MOMENTO DI HU
    if ~isempty(x)
        mu20 = sum((x - s.Centroid(1)).^2);
        mu02 = sum((y - s.Centroid(2)).^2);
        hu1 = (mu20 + mu02) / (s.Area^2);
    else
        hu1 = 0;
    end
    vector = [holes, solidity, eccentricity, circularity, invExtent, radialVariance, hu1];
end