close all;
clear all;

%% 1. CARICAMENTO IMMAGINE
img_path = "../datasets/dataset_train/images/image_0031.png"; 
img = imread(img_path);
figure, imshow(img), title("1. Immagine Originale");

%% 2. SEGMENTAZIONE INIZIALE (segment_dices_initial)
hsv = rgb2hsv(img);
S = hsv(:,:,2);
V = hsv(:,:,3);

t1 = graythresh(S); 
S_bin = imbinarize(S, t1);  

S_med = medfilt2(S, [9 9]); 
V_med = medfilt2(V, [9 9]);

S_smooth = imgaussfilt(S_med, 1.5);
V_smooth = imgaussfilt(V_med, 1.5);

edges_S = edge(S_smooth, 'prewitt');
edges_V = edge(V_smooth, 'prewitt');
edges_combined = edges_S | edges_V;

dices_mask_initial = S_bin | edges_combined;

figure, 
subplot(1,3,1), imshow(S_bin), title("S Binarizzato");
subplot(1,3,2), imshow(edges_combined), title("Edges (S+V)");
subplot(1,3,3), imshow(dices_mask_initial), title("2. Maschera Iniziale (Unita)");

%% 3. PULIZIA MORFOLOGICA E RIMOZIONE BORDI
margin = 2;
[h, w] = size(dices_mask_initial);
[labels_borders, n_borders] = bwlabel(dices_mask_initial);
cleanedMask = dices_mask_initial;

for i = 1:n_borders
    [rows, cols] = find(labels_borders == i);
    if min(rows) <= margin || max(rows) >= h - margin || min(cols) <= margin || max(cols) >= w - margin
        cleanedMask(labels_borders == i) = 0;
    end
end

closedMask = imclose(cleanedMask, strel("disk", 11));
openedMask = imopen(closedMask, strel("disk", 13));
morphed_mask = imerode(openedMask, strel("disk", 3));

figure, 
subplot(1,3,1), imshow(closedMask), title("Closing (11)");
subplot(1,3,2), imshow(openedMask), title("Opening (11)");
subplot(1,3,3), imshow(morphed_mask), title("3. Dopo Pulizia (Erode 5)");

%% 4. ETICHETTATURA E CALCOLO AREE
max_expected_dice_area = 2000;
    
label = logical(morphed_mask);
stats = regionprops(label, 'Area', 'PixelIdxList');
areas = [stats.Area];
    
q75 = prctile(areas, 75);
areas_normal = areas(areas <= q75);
mean_area = mean(areas_normal);

if isnan(mean_area) || mean_area > max_expected_dice_area
    mean_area = max_expected_dice_area;
end

area_threshold = 1.5 * mean_area;

mask_to_separate = false(size(morphed_mask));
mask_ok = false(size(morphed_mask));

for i = 1:length(stats)
    if stats(i).Area > area_threshold
        mask_to_separate(stats(i).PixelIdxList) = true;
    else
        mask_ok(stats(i).PixelIdxList) = true;
    end
end

figure, 
subplot(1,2,1), imshow(mask_ok), title(sprintf("Dadi OK (Area media usata: %.1f)", mean_area));
subplot(1,2,2), imshow(mask_to_separate), title("Da Separare");

%% 5. SEPARAZIONE WATERSHED/VORONOI
cc = bwconncomp(mask_to_separate);
mask_separated = false(size(mask_to_separate));

avg_radius = sqrt(mean_area / pi);
min_distance = avg_radius * 0.9;

for i = 1:cc.NumObjects
    region = false(size(mask_to_separate));
    region(cc.PixelIdxList{i}) = true;
    
    n_dices = max(2, min(round(length(cc.PixelIdxList{i}) / mean_area), 8));
    
    D = bwdist(~region);
    D_smooth = imgaussfilt(D, 2);
    local_max = imregionalmax(D_smooth) & region;
    [rows, cols] = find(local_max);
    vals = arrayfun(@(r,c) D_smooth(r,c), rows, cols);
    [~, idx] = sort(vals, 'descend');
    candidates = [cols(idx), rows(idx)];
    
    if isempty(candidates)
        mask_separated = mask_separated | region;
        continue;
    end
    
    seeds = candidates(1,:);
    for j = 2:size(candidates, 1)
        distances = vecnorm(seeds - candidates(j,:), 2, 2);
        if all(distances > min_distance)
            seeds = [seeds; candidates(j,:)];
        end
        if size(seeds, 1) >= n_dices
            break;
        end
    end
    
    [r_reg, c_reg] = find(region);
    pixel_coords = [c_reg, r_reg];
    dist_to_seeds = zeros(length(r_reg), size(seeds,1));
    for s = 1:size(seeds, 1)
        dist_to_seeds(:, s) = vecnorm(pixel_coords - seeds(s,:), 2, 2);
    end
    
    [~, assignment] = min(dist_to_seeds, [], 2);
    linear_idx = sub2ind(size(region), r_reg, c_reg);
    label_map = zeros(size(region));
    label_map(linear_idx) = assignment;
    
    boundaries = false(size(region));
    for s = 1:size(seeds, 1)
        seg = label_map == s;
        eroded = imerode(seg, strel('disk', 1));
        boundaries = boundaries | (seg & ~eroded);
    end
    
    separated_region = region & ~boundaries;
    mask_separated = mask_separated | separated_region;
end

%% 6. FINAL CLEANUP
dices_mask_combined = mask_ok | mask_separated;
dices_mask_final = dices_mask_combined;

[labels_final, n_final] = bwlabel(dices_mask_final);
areas_final = zeros(1, n_final);
for i = 1:n_final
    areas_final(i) = sum(labels_final(:) == i);
end

medianArea = median(areas_final);
if medianArea > 1500
    medianArea = 1500;
end

for i = 1:n_final
    if areas_final(i) > medianArea * 1.2
        excess = areas_final(i) / medianArea;
        dynamicErode = round(3 * excess);
        regionMask = labels_final == i;
        eroded = imerode(regionMask, strel("disk", dynamicErode));
        dices_mask_final(regionMask) = 0;
        dices_mask_final(eroded) = 1;
    end
end

final_labels = bwlabel(dices_mask_final);
dices_img = img .* uint8(cat(3, dices_mask_final, dices_mask_final, dices_mask_final));

figure, 
subplot(1,2,1), imshow(label2rgb(final_labels, 'jet', 'k', 'shuffle')), title("Labeling Finale");
subplot(1,2,2), imshow(dices_img), title("Immagine Mascherata Finale");

%% 7. STIMA CENTRO E DISCO FINALE
num_dadi = max(final_labels(:));

fixed_size = 64; 
half_size = floor(fixed_size / 2);
circle_radius = 22;

for i = 1:num_dadi
    mask_dado = (final_labels == i);
    [r, c] = find(mask_dado);
    if isempty(r), continue; end
    
    min_r = min(r); max_r = max(r);
    min_c = min(c); max_c = max(c);
    
    crop_rgb = img(min_r:max_r, min_c:max_c, :);
    crop_mask = mask_dado(min_r:max_r, min_c:max_c);
    
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
    
    % Centro di riferimento dalla maschera erosa
    mask_erosa = imerode(crop_mask, strel('disk', 8));
    if any(mask_erosa(:))
        [r_m, c_m] = find(mask_erosa);
    else
        [r_m, c_m] = find(crop_mask);
    end
    ref_x = mean(c_m);
    ref_y = mean(r_m);

    if isempty(stats)
        center_x_local = ref_x;
        center_y_local = ref_y;
    else
        scores = zeros(1, length(stats));
        for b = 1:length(stats)
            eccentricity_penalty = 1 - stats(b).Eccentricity; 
            scores(b) = stats(b).Area * (eccentricity_penalty ^ 2); 
        end
        [~, idx_best] = max(scores);
        center_x_local = stats(idx_best).Centroid(1);
        center_y_local = stats(idx_best).Centroid(2);

        % Controlla distanza dal centro di riferimento
        dist = sqrt((center_x_local - ref_x)^2 + (center_y_local - ref_y)^2);
        [h_crop, w_crop] = size(crop_mask);
        max_dist = min(h_crop, w_crop) * 0.3;

        if dist > max_dist
            center_x_local = ref_x;
            center_y_local = ref_y;
        end
    end
    
    center_x_abs = round(min_c + center_x_local - 1);
    center_y_abs = round(min_r + center_y_local - 1);
    
    x_start = max(1, center_x_abs - half_size);
    y_start = max(1, center_y_abs - half_size);
    x_end = min(size(img, 2), center_x_abs + half_size - 1);
    y_end = min(size(img, 1), center_y_abs + half_size - 1);
    
    fixed_square_crop = img(y_start:y_end, x_start:x_end, :);
    
    if size(fixed_square_crop,1) ~= fixed_size || size(fixed_square_crop,2) ~= fixed_size
        fixed_square_crop = imresize(fixed_square_crop, [fixed_size, fixed_size]);
    end
    
    [X, Y] = meshgrid(1:fixed_size, 1:fixed_size);
    center_c = fixed_size / 2 + 0.5;
    center_r = fixed_size / 2 + 0.5;
    circle_mask = (X - center_c).^2 + (Y - center_r).^2 <= circle_radius^2;
    
    final_masked_crop = fixed_square_crop;
    final_masked_crop(repmat(~circle_mask, [1, 1, 3])) = 0;
    
    figure('Name', sprintf('Dado %d', i), 'NumberTitle', 'off', 'Position', [300, 300, 900, 300]);
    
    subplot(1, 4, 1); imshow(crop_rgb); 
    hold on; plot(center_x_local, center_y_local, 'r+', 'MarkerSize', 10, 'LineWidth', 2); hold off;
    title('Originale + Centro Stimato');
    
    subplot(1, 4, 2); imshow(edge_filled); 
    hold on; plot(center_x_local, center_y_local, 'r+', 'MarkerSize', 10, 'LineWidth', 2); hold off;
    title('Blob Selezionato');
    
    subplot(1, 4, 3); imshow(fixed_square_crop); 
    title(sprintf('Quadrato Fisso (%dx%d)', fixed_size, fixed_size));
    
    subplot(1, 4, 4); imshow(final_masked_crop); 
    title(sprintf('Disco Finale (R=%d)', circle_radius));
end