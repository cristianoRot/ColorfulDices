function seeds = find_seeds(D, region, n_seeds, min_distance)
    D_smooth = imgaussfilt(D, 2);
    
    local_max = imregionalmax(D_smooth) & region;
    [rows, cols] = find(local_max);
    vals = arrayfun(@(r,c) D_smooth(r,c), rows, cols);
    [~, idx] = sort(vals, 'descend');
    candidates = [cols(idx), rows(idx)];
    
    seeds = candidates(1,:);
    for i = 2:size(candidates, 1)
        distances = vecnorm(seeds - candidates(i,:), 2, 2);
        if all(distances > min_distance)
            seeds = [seeds; candidates(i,:)];
        end
        if size(seeds, 1) >= n_seeds
            break;
        end
    end
end