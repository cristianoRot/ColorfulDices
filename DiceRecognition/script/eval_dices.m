%% Script di Valutazione Dataset Maschere
clear all; close all; clc;

% --- CONFIGURAZIONE CARTELLE ---
img_folder = '../../datasets/dataset_test/images/';
mask_folder = '../../datasets/dataset_test/masks/';
file_ext = '*.png';

% Recupera la lista dei file
files = dir(fullfile(img_folder, file_ext));
num_files = length(files);

if num_files == 0
    error('Nessun file trovato in: %s', img_folder);
end

% Inizializzazione
total_TP = 0; total_FP = 0; total_FN = 0; total_TN = 0;

fprintf('Inizio elaborazione di %d immagini...\n', num_files);
fprintf('----------------------------------------\n');

for i = 1:num_files
    % Caricamento Immagine e GT
    img_name = files(i).name;
    img = imread(fullfile(img_folder, img_name));
    
    mask_name = strrep(img_name, 'image_', 'mask_');
    gt_path = fullfile(mask_folder, mask_name);
    if ~exist(gt_path, 'file')
        fprintf('[-] Salto %s: Maschera non trovata.\n', img_name);
        continue;
    end
    
    % Conversione
    gt = logical(rgb2gray(imread(gt_path)));
    
    pred = logical(segment_dices(img)); 
    
    % Calcolo metriche
    tp_curr = sum(gt & pred, 'all');
    fp_curr = sum(~gt & pred, 'all');
    fn_curr = sum(gt & ~pred, 'all');
    tn_curr = sum(~gt & ~pred, 'all');
    
    % Accumulo per la media globale
    total_TP = total_TP + tp_curr;
    total_FP = total_FP + fp_curr;
    total_FN = total_FN + fn_curr;
    total_TN = total_TN + tn_curr;
    
    fprintf('[+] Processata: %s\n', img_name);
end

% --- CALCOLO METRICHE FINALI ---
accuracy  = (total_TP + total_TN) / (total_TP + total_TN + total_FP + total_FN);
precision = total_TP / (total_TP + total_FP);
recall    = total_TP / (total_TP + total_FN);
dice      = 2 * total_TP / (2 * total_TP + total_FP + total_FN);

if isnan(precision), precision = 0; end
if isnan(recall), recall = 0; end

% --- OUTPUT RISULTATI ---
fprintf('\n========================================\n');
fprintf('   RISULTATI VALUTAZIONE DATASET\n');
fprintf('========================================\n');
fprintf('Totale immagini:  %d\n', num_files);
fprintf('Accuracy:         %.4f\n', accuracy);
fprintf('Precision:        %.4f\n', precision);
fprintf('Recall:           %.4f\n', recall);
fprintf('Dice Score (F1):  %.4f\n', dice);
fprintf('----------------------------------------\n');
