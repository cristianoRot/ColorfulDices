function process_video(filename)    
    close all; 
    
    % --- 1. SETUP ---
    [~, nome_video, ~] = fileparts(filename); 
    nome_video = char(nome_video);
    
    cartella_out = fullfile('RISULTATI', nome_video);
    if ~exist(cartella_out, 'dir'), mkdir(cartella_out); end
    fprintf('--- ANALISI: %s ---\n', filename);

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
    
    try
        hFig = figure('Name', ['Analisi: ', nome_video], 'KeyPressFcn', @kPress);
    catch
        hFig = figure('Name', 'Analisi Video', 'KeyPressFcn', @kPress);
    end
    
    vidObj.CurrentTime = 0;
    fNum = 0;

    % --- 4. CICLO ---
    while hasFrame(vidObj) && not(stopVideo)
        frameRaw = readFrame(vidObj);
        fNum = fNum + 1;
        process_frame_logic(hFig, fNum, frameRaw);
    end
    
    fprintf('--- FINE. %d lanci salvati. ---\n\n', lanci_totali);

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
            
            % Adattamento luce
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
                
                % Check se è VUOTO?
                is_dadi = (deviazione_dadi > soglia_deviazione);
                
                if is_dadi
                    
                    % --- LOGICA SOGLIA DINAMICA per la gestione di tutti i video, i quali hanno soglie differenti ---
                    if deviazione_dadi < 13.0
                        % Nel CASO del VIDEO 4: Dadi trasparenti, molti riflessi.
                        % Serve soglia altissima per non fare doppi scatti (salvataggi).
                        soglia_dup_dinamica = 7.5;
                        
                    elseif deviazione_dadi > 25.0
                        % Nel CASO del VIDEO 3: Contrasto estremo.
                        % I duplicati qui sono forti (4.8).
                        soglia_dup_dinamica = 6.0;
                        
                    else
                        % CASO STANDARD 
                        % se i lanci veri sono simili (4.9 - 5.5).
                        % Dobbiamo abbassare la soglia per salvarli
                        soglia_dup_dinamica = 4.0;
                    end
                    % -----------------------------------------------------

                    % Check se è DUPLICATO?
                    [is_new_visual, diff_last] = check_duplicate(curr_gray, last_saved_img, soglia_dup_dinamica);
                    
                    delta_dev = abs(deviazione_dadi - last_dev_val);
                    is_new_structure = (delta_dev > 6.0); 
                    
                    if is_new_visual || is_new_structure
                        
                        lanci_totali = lanci_totali + 1;
                        fprintf('>>> PRESO LANCIO %d (F:%d) | Dev: %.2f | Diff: %.2f (Soglia: %.1f)\n', ...
                            lanci_totali, n, deviazione_dadi, diff_last, soglia_dup_dinamica);
                        
                        imwrite(img_crop, fullfile(cartella_out, sprintf('Lancio_%02d.jpg', lanci_totali)));
                        
                        last_saved_img = curr_gray;
                        last_dev_val = deviazione_dadi;
                        timer_pausa = frames_cooldown;
                        counter_fermo = 0;
                        
                        colore_stato = 'magenta';
                        msg = 'PRESO!';
                    else
                        if mod(n, 20) == 0 % Stampo meno spesso i duplicati, faccio un debug per capire cosa viene fatto per ogni lancio
                            fprintf('[DEBUG] F:%d | Dev:%.2f | Ignorato Duplicato (Diff: %.2f < %.1f)\n', ...
                                n, deviazione_dadi, diff_last, soglia_dup_dinamica);
                        end
                        msg = 'DUPLICATO';
                        colore_stato = 'cyan'; 
                    end
                else
                    msg = 'VUOTO'; 
                end
            end
        end
        
        if isvalid(fig) && mod(n, 2) == 0
            img_vis = insertShape(frame, 'Rectangle', box_area, 'Color', colore_stato, 'LineWidth', 3);
            txt = sprintf('L:%d | Dev:%.1f | %s', lanci_totali, deviazione_dadi, msg);
            img_vis = insertText(img_vis, [10 10], txt, 'FontSize', 18, 'BoxColor', 'black', 'TextColor', 'white');
            figure(fig); imshow(img_vis); drawnow limitrate;
        end
    end
end
