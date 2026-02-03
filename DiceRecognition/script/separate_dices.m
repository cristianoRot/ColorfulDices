function mask_separated = separate_dices(mask_to_separate, mean_area)
    cc = bwconncomp(mask_to_separate);
    mask_separated = false(size(mask_to_separate));
    
    avg_radius = sqrt(mean_area / pi);
    min_distance = avg_radius * 0.9;
    
    for i = 1:cc.NumObjects
        region = false(size(mask_to_separate));
        region(cc.PixelIdxList{i}) = true;
        
        n_dices = max(2, min(round(length(cc.PixelIdxList{i}) / mean_area), 8));
        
        % Calcola bwdist una volta sola, passa a entrambe le funzioni
        D = bwdist(~region);
        seeds = find_seeds(D, region, n_dices, min_distance);
        
        mask_separated = mask_separated | watershed_split(D, region, seeds);
    end
end