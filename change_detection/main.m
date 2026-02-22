clear; clc; close all;

filename = 'VIDEO-04.mp4'; 

% Controlla se il file esiste prima di lanciare la funzione
if exist(filename, 'file')
    % Analisi Video
    ImmaginiLanci = process_video(filename);
    num_lanci = length(ImmaginiLanci);
    
    disp(['Ho trovato ', num2str(num_lanci), ' lanci.']);
    
    % Visualizzazione Dinamica in base a quanti lanci sono stati trovati
    if num_lanci > 0
        figure('Name', 'Risultati Rilevamento', 'NumberTitle', 'off');
        
        % Calcolo automatico righe/colonne 
        cols = ceil(sqrt(num_lanci)); 
        rows = ceil(num_lanci / cols);
        
        for i = 1:num_lanci
            subplot(rows, cols, i); 
            imshow(ImmaginiLanci{i});
            title(['Lancio ', num2str(i)]);
        end
    else
        disp('Nessun lancio rilevato nel video.');
    end
    
else
    error('File video non trovato nella cartella corrente.');
end
