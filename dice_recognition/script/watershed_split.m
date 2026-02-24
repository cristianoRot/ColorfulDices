function separated = watershed_split(D, region, seeds)
    [rows, cols] = find(region);
    pixel_coords = [cols, rows];
    
    dist_to_seeds = zeros(length(rows), size(seeds,1));
    for s = 1:size(seeds, 1)
        dist_to_seeds(:, s) = vecnorm(pixel_coords - seeds(s,:), 2, 2);
    end
    
    [~, assignment] = min(dist_to_seeds, [], 2);
    
    linear_idx = sub2ind(size(region), rows, cols);
    label_map = zeros(size(region));
    label_map(linear_idx) = assignment;
    
    boundaries = false(size(region));
    for s = 1:size(seeds, 1)
        seg = label_map == s;
        eroded = imerode(seg, strel('disk', 1));
        boundaries = boundaries | (seg & ~eroded);
    end
    
    separated = region & ~boundaries;
end