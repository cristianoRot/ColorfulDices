clear; clc; close all;

nome_video = 'VIDEO-04.mp4'; 
cartella_video = '../videos';

filepath = fullfile(cartella_video, nome_video);

if exist(filepath, 'file')
    
    disp(['Analizzo il file: ', filepath]);
    
    ImmaginiLanci = process_video(filepath);
    num_lanci = length(ImmaginiLanci);
    
    disp(['Ho trovato ', num2str(num_lanci), ' lanci.']);
    
    if num_lanci > 0
        figure('Name', ['Risultati: ', nome_video], 'NumberTitle', 'off');
        
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
    error('File video non trovato! Verifica che la cartella "videos" esista e contenga il file.');
end
