function separated = watershed_split(D, region, seeds)
    [rows, cols] = find(region);
    pixel_coords = [cols, rows];
    
    % Calcola distanza di ogni pixel da ogni seme
    dist_to_seeds = zeros(length(rows), size(seeds,1));
    for s = 1:size(seeds, 1)
        dist_to_seeds(:, s) = vecnorm(pixel_coords - seeds(s,:), 2, 2);
    end
    
    % Ogni pixel va al seme più vicino (Voronoi)
    [~, assignment] = min(dist_to_seeds, [], 2);
    
    % Costruisci mappa delle label
    linear_idx = sub2ind(size(region), rows, cols);
    label_map = zeros(size(region));
    label_map(linear_idx) = assignment;
    
    % Trova i confini: pixel che hanno un vicino con label diversa
    boundaries = false(size(region));
    for s = 1:size(seeds, 1)
        seg = label_map == s;
        % Il bordo della regione è dove il segmento si tocca con altri
        eroded = imerode(seg, strel('disk', 1));
        boundaries = boundaries | (seg & ~eroded);
    end
    
    % Rimuovi i confini dalla regione originale
    separated = region & ~boundaries;
end