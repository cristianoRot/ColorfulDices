clear; close all; clc;

% CONFIGURAZIONE
filename = 'VIDEO-10.mp4'; % video da analizzare
video = VideoReader(filename);

% Creazione cartelle per salvare le foto se non ci sono già
[~, nome_video, ~] = fileparts(filename); 
cartella_output = 'RISULTATI_ANALISI';
cartella_specifica = fullfile(cartella_output, nome_video);

% Controllo esistenza cartelle
if ~exist(cartella_output, 'dir')
    mkdir(cartella_output);
end
if ~exist(cartella_specifica, 'dir')
    mkdir(cartella_specifica);
end

fprintf('Analisi avviata: %s\nSalvato in: %s\n', filename, cartella_specifica);

% PARAMETRI 
% Coordinate trovate manualmente guardando il primo frame
area_rettangolo = [100, 0, 1080, 800];  

soglia_movimento = 0.5;   % Se la differenza è minore di questo, considero l'immagine FERMA
soglia_differenza = 3.5;    % Se la differenza sfondo è maggiore, ci sono i DADI
frames_attesa = 12;        % Bastano pochi frame di stabilità
frames_cooldown = 30;     % Pausa dopo lo scatto 

video.CurrentTime = 0;
bg_raw = readFrame(video);
bg_cropped = imcrop(bg_raw, area_rettangolo); 
bg_gray = rgb2gray(bg_cropped);
prev_gray = bg_gray;

frame_count = 0;
counter_statico = 0;
lanci = 0;

% Variabile per il timer di pausa
timer_pausa = 0; 
h = waitbar(0, ['Elaborazione ' nome_video '...']);

while hasFrame(video)
    frame_raw = readFrame(video);
    frame_count = frame_count + 1;
    
    % GESTIONE PAUSA
    % Se ho appena scattato, aggiorno solo lo sfondo precedente e salto il resto
    if timer_pausa > 0
        timer_pausa = timer_pausa - 1;
        frame_cropped = imcrop(frame_raw, area_rettangolo);
        prev_gray = rgb2gray(frame_cropped); 
        continue; 
    end
    
    % Ritaglio e conversione scala di grigi
    frame_cropped = imcrop(frame_raw, area_rettangolo);
    curr_gray = rgb2gray(frame_cropped);
    
    % 1. Calcolo quanto si è mosso rispetto a prima
    diff_mov = imabsdiff(curr_gray, prev_gray);
    val_mov = mean(diff_mov(:)); 
    
    % 2. Calcolo quanto è diverso dallo sfondo vuoto
    diff_bg = imabsdiff(curr_gray, bg_gray);
    val_diff = mean(diff_bg(:));
    
    prev_gray = curr_gray;
    
    % Controllo se l'immagine è praticamente ferma
    if val_mov < soglia_movimento
        counter_statico = counter_statico + 1;
    else
        % Se si muove (mani, dadi che rotolano), resetto il contatore
        counter_statico = 0;
    end
    
    % Se è fermo da un po' (dadi posati) E c'è qualcosa sul tavolo
    if counter_statico >= frames_attesa
        if val_diff > soglia_differenza
            
            lanci = lanci + 1;
            fprintf('Lancio %d trovato al frame %d (Diff: %.2f)\n', lanci, frame_count, val_diff);
            
            % Salvataggio
            nome_file = fullfile(cartella_specifica, sprintf('Lancio_%02d.jpg', lanci));
            imwrite(frame_cropped, nome_file);            
           
            % Attivo il cooldown per non salvare troppe foto doppie
            timer_pausa = frames_cooldown; 
            counter_statico = 0; % Resetto per sicurezza
        end
    end
    
    if mod(frame_count, 50) == 0
        waitbar(video.CurrentTime/video.Duration, h);
    end
end
close(h);
fprintf('Completato: %d lanci salvati.\n', lanci);