function [center_x, center_y] = estimate_number_center(crop_rgb, crop_mask)

    mask_erosa = imerode(crop_mask, strel('disk', 8));
    if any(mask_erosa(:))
        [r_m, c_m] = find(mask_erosa);
    else
        [r_m, c_m] = find(crop_mask);
    end
    ref_x = mean(c_m);
    ref_y = mean(r_m);

    img_temp = crop_rgb;
    img_temp(repmat(~crop_mask, [1, 1, 3])) = 0;
    
    hsv_crop = rgb2hsv(img_temp);
    S_smooth = imgaussfilt(hsv_crop(:,:,2), 1.5);
    V_smooth = imgaussfilt(hsv_crop(:,:,3), 1.5);
    
    edge_OR = edge(S_smooth, 'canny') | edge(V_smooth, 'canny');
    
    mask_interna = imerode(crop_mask, strel('disk', 6));
    edge_OR(~mask_interna) = 0;
    
    edge_closed = imclose(edge_OR, strel('disk', 3));
    edge_filled = imfill(edge_closed, 'holes');
    
    stats = regionprops(edge_filled, 'Area', 'Eccentricity', 'Centroid');
    
    if isempty(stats)
        center_x = ref_x;
        center_y = ref_y;
    else
        scores = zeros(1, length(stats));
        for b = 1:length(stats)
            eccentricity_penalty = 1 - stats(b).Eccentricity; 
            scores(b) = stats(b).Area * (eccentricity_penalty ^ 2); 
        end
        [~, idx_best] = max(scores);
        center_x = stats(idx_best).Centroid(1);
        center_y = stats(idx_best).Centroid(2);
        
        dist = sqrt((center_x - ref_x)^2 + (center_y - ref_y)^2);
        [h_crop, w_crop] = size(crop_mask);
        max_dist = min(h_crop, w_crop) * 0.3;
        
        if dist > max_dist
            center_x = ref_x;
            center_y = ref_y;
        end
    end
end