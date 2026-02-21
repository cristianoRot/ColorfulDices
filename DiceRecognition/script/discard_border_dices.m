function mask = discard_border_dices(mask)
    margin = 2;
    
    [h, w] = size(mask);
    [labels, n] = bwlabel(mask);
    
    for i = 1:n
        [rows, cols] = find(labels == i);
        if min(rows) <= margin || max(rows) >= h - margin || min(cols) <= margin || max(cols) >= w - margin
            mask(labels == i) = 0;
        end
    end
end