function tray_masked_img = remove_bg_tray(img)
    
    hsv = rgb2hsv(img);
    S = hsv(:,:,2);
    
    S_inv = 1 - S;
    tray_rough = S_inv > 0.8;

    tray_mask = imclose(tray_rough, strel('square', 51));

    tray_masked_img = img .* uint8(cat(3, tray_mask, tray_mask, tray_mask));
end