function mask = final_cleanup(mask)
    
    [labels, n] = bwlabel(mask);
    areas = zeros(1, n);
    for i = 1:n
        areas(i) = sum(labels(:) == i);
    end

    medianArea = median(areas);
    if medianArea > 1500
        medianArea = 1500;
    end
    
    for i = 1:n
        if areas(i) > medianArea * 1.2
            excess = areas(i) / medianArea;
            dynamicErode = round(3 * excess);
            regionMask = labels == i;
            eroded = imerode(regionMask, strel("disk", dynamicErode));
            mask(regionMask) = 0;
            mask(eroded) = 1;
        end
    end
end