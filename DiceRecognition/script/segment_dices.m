function dices_mask = segment_dices(img)

    %RIMOSSO perchè edge detection già taglia
    %tray_masked_img = remove_bg_tray(img);

    tray_masked_img = img;

    dices_mask_initial = segment_dices_initial(tray_masked_img);
    
    morphed_mask = initial_cleanup(dices_mask_initial);
    
    [mask_ok, mask_to_separate, mean_area] = label_dices(morphed_mask);
    
    mask_separated = separate_dices(mask_to_separate, mean_area);
    
    dices_mask = mask_ok | mask_separated;

    dices_mask = final_cleanup(dices_mask);
end