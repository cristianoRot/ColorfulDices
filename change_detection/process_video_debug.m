function LanciArray = process_video_debug(filename)    
    close all; 
    
    % --- 1. SETUP ---
    LanciArray = {}; % Inizializzo l'array vuoto per le immagini
    
    [~, nome_video, ~] = fileparts(filename);
    fprintf('--- ANALISI HSV (Saturazione) OTTIIMIZZATA: %s ---\n', filename);

    % --- 2. PARAMETRI ---
    box_area = [100, 0, 1080, 800];
    soglia_movimento = 0.5;  
    
    if ismac
        soglia_deviazione = 7.0; 
        fprintf('[INFO] Rilevato macOS. Soglia deviazione impostata a %.1f\n', soglia_deviazione);
    else
        soglia_deviazione = 9.1; 
        fprintf('[INFO] Sistema non-macOS. Soglia deviazione impostata a %.1f\n', soglia_deviazione);
    end
    
    % REATTIVITÀ: Ridotti per non perdere lanci rapidi e ravvicinati
    frames_attesa = 7;      
    frames_cooldown = 15;    
    
    % --- 3. INIZIALIZZAZIONE ---
    vidObj = VideoReader(filename);
    try
        bg_frame = readFrame(vidObj);
        bg_crop = imcrop(bg_frame, box_area);
        
        % MODIFICA HSV: Estraiamo la Saturazione per ignorare le ombre
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
    
    try
        hFig = figure('Name', ['Analisi: ', nome_video], 'KeyPressFcn', @kPress);
    catch
        hFig = figure('Name', 'Analisi Video', 'KeyPressFcn', @kPress);
    end
    
    fNum = 0;
    % --- 4. CICLO ---
    while hasFrame(vidObj) && not(stopVideo)
        frameRaw = readFrame(vidObj);
        fNum = fNum + 1;
        process_frame_logic(hFig, fNum, frameRaw);
    end
    
    fprintf('--- FINE. %d lanci salvati nell''array. ---\n\n', lanci_totali);

    function kPress(~, e) 
        if strcmp(e.Key, 'escape'), stopVideo = true; end 
    end 

    % --- 5. LOGICA ---
    function process_frame_logic(fig, n, frame)
        
        colore_stato = 'yellow';
        msg = 'ANALISI';
        deviazione_dadi = 0.0;
        
        if timer_pausa > 0
            timer_pausa = timer_pausa - 1;
            colore_stato = 'red';
            msg = sprintf('PAUSA (%d)', timer_pausa);
            
            tmp = imcrop(frame, box_area);
            tmp_hsv = rgb2hsv(tmp);
            prev_gray = uint8(tmp_hsv(:,:,2) * 255);
        else
            img_crop = imcrop(frame, box_area);
            curr_hsv = rgb2hsv(img_crop);
            curr_gray = uint8(curr_hsv(:,:,2) * 255);
            
            % Calcoli movimento e deviazione
            diff_mov_mat = imabsdiff(curr_gray, prev_gray);
            movimento = mean(diff_mov_mat(:));
            
            diff_bg_mat = imabsdiff(curr_gray, bg_gray);
            diff_bg_double = double(diff_bg_mat); 
            deviazione_dadi = std(diff_bg_double(:));     
            
            prev_gray = curr_gray;
            
            % Adattamento Luce (Background update)
            if movimento < soglia_movimento && deviazione_dadi < 8.0 
                bg_gray = uint8(double(bg_gray) * 0.95 + double(curr_gray) * 0.05);
            end
            
            if movimento < soglia_movimento
                counter_fermo = counter_fermo + 1;
                colore_stato = 'green';
                msg = 'FERMO';
            else
                counter_fermo = 0;
                colore_stato = 'blue';
                msg = 'MOVIMENTO';
            end
            
            % --- DECISIONE ---
            if counter_fermo >= frames_attesa

                is_dadi = (deviazione_dadi > soglia_deviazione);
                
                if is_dadi
                    % SOGLIE DINAMICHE CALIBRATE PER HSV
                    if deviazione_dadi > 25.0
                        soglia_dup_dinamica = 4.0; 
                    else
                        soglia_dup_dinamica = 3.2; 
                    end

                    [is_new_visual, diff_last] = check_duplicate(curr_gray, last_saved_img, soglia_dup_dinamica);
                    
                    delta_dev = abs(deviazione_dadi - last_dev_val);
                    is_new_structure = (delta_dev > 5.5); 

                    % --- FILTRO RIMOZIONE (Video 5) ---
                    % Se la deviazione è diminuita rispetto all'ultimo salvataggio, 
                    % probabilmente stiamo solo togliendo dadi.
                    is_removal = (deviazione_dadi < (last_dev_val - 3.0));

                    if (is_new_visual || is_new_structure) && ~is_removal
                        
                        lanci_totali = lanci_totali + 1;
                        LanciArray{end+1} = img_crop; 
                        
                        fprintf('>>> PRESO %d | DiffDup: %.2f | DeltaDev: %.2f\n', ...
                            lanci_totali, diff_last, delta_dev);
                        
                        last_saved_img = curr_gray;
                        last_dev_val = deviazione_dadi;
                        timer_pausa = frames_cooldown;
                        counter_fermo = 0;
                        
                        colore_stato = 'magenta';
                        msg = 'PRESO!';
                    else
                        % Se è una rimozione, lo marchiamo nei log per debug
                        if is_removal
                             msg = 'RIMOZIONE';
                             colore_stato = 'yellow';
                        else
                             msg = 'DUPLICATO';
                             colore_stato = 'cyan';
                        end
                    end
                else
                    % --- RESET QUANDO VUOTO ---
                    % Fondamentale: se il vassoio è vuoto, resettiamo last_dev_val
                    % così il prossimo lancio sarà sicuramente visto come nuovo.
                    last_dev_val = 0; 
                    
                    fprintf('SCARTATO: Vuoto (Dev < %.1f)\n', soglia_deviazione);
                    msg = 'VUOTO'; 
                end
            end
        end
        
        % Visualizzazione (Debug)
        if isvalid(fig) && mod(n, 2) == 0
            img_vis = insertShape(frame, 'Rectangle', box_area, 'Color', colore_stato, 'LineWidth', 3);
            txt = sprintf('L:%d | Dev:%.1f | %s', lanci_totali, deviazione_dadi, msg);
            img_vis = insertText(img_vis, [10 10], txt, 'FontSize', 18, 'BoxColor', 'black', 'TextColor', 'white');
            figure(fig); imshow(img_vis); drawnow limitrate;
        end
    end
end
