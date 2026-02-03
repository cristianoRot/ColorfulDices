function dices_mask = segment_dices(img)

    tray_masked_img = remove_bg_tray(img);

    dices_mask_initial = segment_dices_initial(tray_masked_img);
    
    morphed_mask = morph_cleanup(dices_mask_initial);
    
    [mask_ok, mask_to_separate, mean_area] = label_dices(morphed_mask);
    
    mask_separated = separate_dices(mask_to_separate, mean_area);
    
    dices_mask = mask_ok | mask_separated;
end