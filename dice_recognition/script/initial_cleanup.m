function morphed_mask = initial_cleanup(mask)
    cleanedMask = discard_border_dices(mask);
    closedMask = imclose(cleanedMask, strel("disk", 11));
    openedMask = imopen(closedMask, strel("disk", 13));
    morphed_mask = imerode(openedMask, strel("disk", 3));
end