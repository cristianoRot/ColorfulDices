function [is_new_throw, diff_val] = check_duplicate(img_new, img_old, threshold)
    % Confronto l'immagine attuale con l'ultimo lancio salvato.
    
    if isempty(img_old)
        is_new_throw = true;
        diff_val = 100; 
        return;
    end
    
    diff_matrix = imabsdiff(img_new, img_old);
    diff_val = mean(diff_matrix(:));
    
    if diff_val > threshold
        is_new_throw = true; % Diverso -> Nuovo lancio
    else
        is_new_throw = false; % Uguale -> Duplicato
    end
end 