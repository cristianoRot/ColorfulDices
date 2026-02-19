function morphed_mask = morph_cleanup(mask)

    closedMask = imclose(mask, strel("disk", 9));
    openedMask = imopen(closedMask, strel("disk", 15));
    morphed_mask = imerode(openedMask, strel("disk", 3));
end