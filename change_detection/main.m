clear; clc;

filename = 'VIDEO-01.mp4'; 
% ---------------------------------------

% Controlla se il file esiste prima di lanciare la funzione
if exist(filename, 'file')
    process_video(filename);
else
    error('File video "%s" non trovato! Controlla il nome o la cartella.', filename);
end
