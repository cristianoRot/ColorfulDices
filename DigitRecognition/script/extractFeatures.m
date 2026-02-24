% extractFeatures.m - Cristiano Rotunno 914317

function vector = extractFeatures(bw)
    bw = logical(bw);
    
    stats = regionprops(bw, 'EulerNumber', 'Solidity', 'Eccentricity', ...
                             'Circularity', 'Perimeter', 'Area', ...
                             'MajorAxisLength', 'MinorAxisLength', ...
                             'Centroid');

    if isempty(stats)
        vector = zeros(1, 9);
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
        
        dx = x - s.Centroid(1);
        dy = y - s.Centroid(2);
        
        % Second order central moments
        mu20 = sum(dx.^2);
        mu02 = sum(dy.^2);
        mu11 = sum(dx .* dy);
        
        % Third order central moments
        mu30 = sum(dx.^3);
        mu03 = sum(dy.^3);
        mu12 = sum(dx .* dy.^2);
        mu21 = sum(dx.^2 .* dy);
        
        % Normalized central moments
        eta20 = mu20 / (s.Area^2);
        eta02 = mu02 / (s.Area^2);
        eta11 = mu11 / (s.Area^2);
        
        eta30 = mu30 / (s.Area^2.5);
        eta03 = mu03 / (s.Area^2.5);
        eta12 = mu12 / (s.Area^2.5);
        eta21 = mu21 / (s.Area^2.5);
        
        % Hu Moments
        hu1 = eta20 + eta02;
        hu2 = (eta20 - eta02)^2 + 4 * eta11^2;
        hu3 = (eta30 - 3*eta12)^2 + (3*eta21 - eta03)^2;
    else
        radialVariance = 0;
        hu1 = 0; hu2 = 0; hu3 = 0;
    end
    
    vector = [holes, solidity, eccentricity, circularity, invExtent, radialVariance, hu1, hu2, hu3];
end