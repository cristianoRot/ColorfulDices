function LanciArray = process_video(filename)    
    close all; 
    
    % --- 1. SETUP ---
    LanciArray = {}; % Inizializzo l'array vuoto per le immagini
    
    [~, nome_video, ~] = fileparts(filename);

    % --- 2. PARAMETRI ---
    box_area = [100, 0, 1080, 800]; 
    soglia_movimento = 0.5;   
    soglia_deviazione = 9.1;  
    frames_attesa = 10;       
    frames_cooldown = 50;     
    
    % --- 3. INIZIALIZZAZIONE ---
    vidObj = VideoReader(filename);
    try
        bg_frame = readFrame(vidObj);
        bg_crop = imcrop(bg_frame, box_area); 
        bg_gray = rgb2gray(bg_crop);
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
    
    % No figure or visualization requested; remove GUI creation and keypress handling.
    fNum = 0;

    % --- 4. CICLO ---
    while hasFrame(vidObj) && not(stopVideo)
        frameRaw = readFrame(vidObj);
        fNum = fNum + 1;
        process_frame_logic(fNum, frameRaw);
    end
    

    function kPress(~, ~) 
        % Empty placeholder to keep compatibility if ever referenced.
    end 

    % --- 5. LOGICA ---
    function process_frame_logic(n, frame)
        
        deviazione_dadi = 0.0; 
        
        if timer_pausa > 0
            timer_pausa = timer_pausa - 1;
            tmp = imcrop(frame, box_area);
            prev_gray = rgb2gray(tmp);
        else
            img_crop = imcrop(frame, box_area);
            curr_gray = rgb2gray(img_crop);
            
            % Calcoli
            diff_mov_mat = imabsdiff(curr_gray, prev_gray);
            movimento = mean(diff_mov_mat(:));
            
            diff_bg_mat = imabsdiff(curr_gray, bg_gray);
            diff_bg_double = double(diff_bg_mat); 
            
            deviazione_dadi = std(diff_bg_double(:));     
            
            prev_gray = curr_gray;
            
            % Adattamento Luce
            if movimento < soglia_movimento && deviazione_dadi < 8.0 
                bg_gray = uint8(double(bg_gray) * 0.95 + double(curr_gray) * 0.05);
            end
            
            if movimento < soglia_movimento
                counter_fermo = counter_fermo + 1;
            else
                counter_fermo = 0;
            end
            
            % --- DECISIONE ---
            if counter_fermo >= frames_attesa

                is_dadi = (deviazione_dadi > soglia_deviazione);
                
                if is_dadi
                    
                    % --- LOGICA SOGLIA DINAMICA ---
                    if deviazione_dadi < 13.0
                        soglia_dup_dinamica = 7.5; % Video 4
                    elseif deviazione_dadi > 25.0
                        soglia_dup_dinamica = 6.0; % Video 3
                    else
                        soglia_dup_dinamica = 4.0; % Standard
                    end

                    [is_new_visual, diff_last] = check_duplicate(curr_gray, last_saved_img, soglia_dup_dinamica);
                    delta_dev = abs(deviazione_dadi - last_dev_val);
                    is_new_structure = (delta_dev > 6.0); 
                    
                    if is_new_visual || is_new_structure
                        
                        lanci_totali = lanci_totali + 1;
                        
                        % --- SALVATAGGIO NELL'ARRAY ---
                        LanciArray{end+1} = img_crop; 
                        
                        last_saved_img = curr_gray;
                        last_dev_val = deviazione_dadi;
                        timer_pausa = frames_cooldown;
                        counter_fermo = 0;
                    end
                end
            end
        end
        % No visualization or figure updates performed.
    end
end
