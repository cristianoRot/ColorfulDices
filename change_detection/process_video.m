function LanciArray = process_video(filename)    
    LanciArray = {};
    [~, nome_video, ~] = fileparts(filename);

    % --- PARAMETRI ---
    box_area = [100, 0, 1080, 800];
    soglia_movimento = 0.5;  
    
    if ismac
        soglia_deviazione = 7.0; 
    else
        soglia_deviazione = 9.1; 
    end
    
    frames_attesa = 7;      
    frames_cooldown = 15;    
    
    % --- INIZIALIZZAZIONE ---
    vidObj = VideoReader(filename);
    try
        bg_frame = readFrame(vidObj);
        bg_crop = imcrop(bg_frame, box_area);
        bg_hsv = rgb2hsv(bg_crop);
        bg_gray = uint8(bg_hsv(:,:,2) * 255); 
    catch
        error('Errore lettura video.');
    end
    
    prev_gray = bg_gray;       
    last_saved_img = [];
    last_dev_val = 0;
    
    counter_fermo = 0;
    lanci_totali = 0;
    timer_pausa = 0;
    stopVideo = false;
    
    fNum = 0;
    while hasFrame(vidObj) && not(stopVideo)
        frameRaw = readFrame(vidObj);
        fNum = fNum + 1;
        process_frame_logic(fNum, frameRaw);
    end

    % --- LOGICA FRAME (senza visualizzazione/debug) ---
    function process_frame_logic(~, frame)
        
        deviazione_dadi = 0.0;
        
        if timer_pausa > 0
            timer_pausa = timer_pausa - 1;
            tmp = imcrop(frame, box_area);
            tmp_hsv = rgb2hsv(tmp);
            prev_gray = uint8(tmp_hsv(:,:,2) * 255);
        else
            img_crop = imcrop(frame, box_area);
            curr_hsv = rgb2hsv(img_crop);
            curr_gray = uint8(curr_hsv(:,:,2) * 255);
            
            diff_mov_mat = imabsdiff(curr_gray, prev_gray);
            movimento = mean(diff_mov_mat(:));
            
            diff_bg_mat = imabsdiff(curr_gray, bg_gray);
            deviazione_dadi = std(double(diff_bg_mat(:)));     
            
            prev_gray = curr_gray;
            
            % Aggiornamento adattivo del background
            if movimento < soglia_movimento && deviazione_dadi < 8.0 
                bg_gray = uint8(double(bg_gray) * 0.95 + double(curr_gray) * 0.05);
            end
            
            if movimento < soglia_movimento
                counter_fermo = counter_fermo + 1;
            else
                counter_fermo = 0;
            end
            
            if counter_fermo >= frames_attesa

                is_dadi = (deviazione_dadi > soglia_deviazione);
                
                if is_dadi
                    if deviazione_dadi > 25.0
                        soglia_dup_dinamica = 4.0; 
                    else
                        soglia_dup_dinamica = 3.2; 
                    end

                    [is_new_visual, ~] = check_duplicate(curr_gray, last_saved_img, soglia_dup_dinamica);
                    
                    delta_dev = abs(deviazione_dadi - last_dev_val);
                    is_new_structure = (delta_dev > 5.5); 
                    is_removal = (deviazione_dadi < (last_dev_val - 3.0));

                    if (is_new_visual || is_new_structure) && ~is_removal
                        lanci_totali = lanci_totali + 1;
                        LanciArray{end+1} = img_crop; 
                        last_saved_img = curr_gray;
                        last_dev_val = deviazione_dadi;
                        timer_pausa = frames_cooldown;
                        counter_fermo = 0;
                    end
                else
                    last_dev_val = 0; 
                end
            end
        end
    end
end