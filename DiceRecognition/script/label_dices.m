function [mask_ok, mask_to_separate, mean_area] = label_dices(mask)
    
    max_expected_dice_area = 2000;
    
    label = logical(mask);

    stats = regionprops(label, 'Area', 'PixelIdxList');

    areas = [stats.Area];
    
    q75 = prctile(areas, 75);
    areas_normal = areas(areas <= q75);
    mean_area = mean(areas_normal);

    if isnan(mean_area) || mean_area > max_expected_dice_area
        mean_area = max_expected_dice_area;
    end

    area_threshold = 1.5 * mean_area;

    mask_to_separate = false(size(mask));
    mask_ok = false(size(mask));



    for i = 1:length(stats)
        if stats(i).Area > area_threshold
            mask_to_separate(stats(i).PixelIdxList) = true;
        else
            mask_ok(stats(i).PixelIdxList) = true;
        end
    end
end