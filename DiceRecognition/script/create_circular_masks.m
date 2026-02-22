function new_mask = create_circular_masks(img, dices_mask_full)
    [h_img, w_img, ~] = size(img);
    [labels, num_dadi] = bwlabel(dices_mask_full);
    
    if num_dadi == 0
        new_mask = false(h_img, w_img);
        return;
    end

    centers = zeros(num_dadi, 2);
    circle_radius = 25;

    for i = 1:num_dadi
        mask_dado = (labels == i);
        [r, c] = find(mask_dado);
        
        min_r = min(r); max_r = max(r);
        min_c = min(c); max_c = max(c);
        crop_rgb = img(min_r:max_r, min_c:max_c, :);
        crop_mask = mask_dado(min_r:max_r, min_c:max_c);
        
        [cx_loc, cy_loc] = estimate_number_center(crop_rgb, crop_mask);
        
        centers(i, 1) = min_c + cx_loc - 1;
        centers(i, 2) = min_r + cy_loc - 1;
    end

    dist_map = inf(h_img, w_img);
    label_map = zeros(h_img, w_img);

    for i = 1:num_dadi
        c_abs = centers(i, 1);
        r_abs = centers(i, 2);
        
        x_range = max(1, round(c_abs-circle_radius)):min(w_img, round(c_abs+circle_radius));
        y_range = max(1, round(r_abs-circle_radius)):min(h_img, round(r_abs+circle_radius));
        
        [X, Y] = meshgrid(x_range, y_range);
        dist_to_center = sqrt((X - c_abs).^2 + (Y - r_abs).^2);
        
        valid_pixels = dist_to_center <= circle_radius;
        
        for row_idx = 1:length(y_range)
            for col_idx = 1:length(x_range)
                if valid_pixels(row_idx, col_idx)
                    curr_r = y_range(row_idx);
                    curr_c = x_range(col_idx);
                    d = dist_to_center(row_idx, col_idx);
                    
                    if d < dist_map(curr_r, curr_c)
                        dist_map(curr_r, curr_c) = d;
                        label_map(curr_r, curr_c) = i;
                    end
                end
            end
        end
    end

    boundaries = boundarymask(label_map);
    new_mask = (label_map > 0) & ~boundaries;
end