% createDataset.m
function createDataset()
    % Chiudi eventuali file aperti precedentemente
    fclose('all');

    % Risolvi i percorsi in modo dinamico in base alla posizione dello script
    scriptDir = fileparts(mfilename('fullpath'));
    baseDatasetsDir = fullfile(scriptDir, '..', '..', 'datasets');
    datasetDir = fullfile(scriptDir, '..', 'dataset');

    if ~exist(datasetDir, 'dir')
        mkdir(datasetDir);
    end

    % I due set da processare
    phases = {'train', 'test'};

    % Setup figure once
    hFig = figure(1);
    set(hFig, 'Position', [100, 100, 1200, 600]);

    for p = 1:length(phases)
        phase = phases{p};
        fprintf('\n--- Inizio elaborazione set di %s ---\n', phase);
        
        imagesDir = fullfile(baseDatasetsDir, ['dataset_' phase], 'images');
        masksDir  = fullfile(baseDatasetsDir, ['dataset_' phase], 'masks');
        csvPath   = fullfile(datasetDir, [phase '.csv']);
        
        % Rimuovi il vecchio CSV locale per ripartire da zero se si riesegue lo script
        if isfile(csvPath)
            delete(csvPath);
        end

        % Cerca le immagini (dovrebbero essere .png secondo lo script precedente, facciamo fallback .jpg)
        images = dir(fullfile(imagesDir, '*.png')); 
        if isempty(images)
             images = dir(fullfile(imagesDir, '*.jpg'));
        end
        
        sampleCounter = 1;

        for k = 1:length(images)
            imgName = images(k).name;
            if imgName(1) == '.'
                continue; % Salta file nascosti
            end
            
            imgPath = fullfile(imagesDir, imgName);
            
            % I nomi in create_dataset.m sono formattati come "image_0001.png" e "mask_0001.png"
            maskName = strrep(imgName, 'image_', 'mask_');
            maskPath = fullfile(masksDir, maskName);
            
            if ~isfile(maskPath)
                fprintf('Maschera mancante per %s, salto.\n', imgName);
                continue;
            end

            fprintf('Elaborazione %s (%s)...\n', imgName, phase);
            
            im = imread(imgPath);
            mask = imread(maskPath);

            % Gestione maschere RGB o con canali extra
            if size(mask, 3) > 1
                mask = mask(:,:,1);
            end
            
            % Ensure mask is logical
            mask = mask > 0;
            
            % Verifica dimensioni
            if size(im, 1) ~= size(mask, 1) || size(im, 2) ~= size(mask, 2)
                fprintf('Dimensioni non corrispondenti tra immagine e maschera per %s. Resize maschera.\n', imgName);
                mask = imresize(mask, [size(im, 1), size(im, 2)], 'nearest');
            end

            % Estrai i singoli dadi usando la funzione esistente
            [dices, ~] = extractDices(im, mask);
            
            for i = 1:length(dices)
                singleDice = dices{i};
                
                % Estrai features
                [number, score_val, out, labels, KMlabels, k_val, vector] = segmentDigit(singleDice);
                
                % Mostra il dado e l'immagine processata
                figure(hFig);
                clf; 
                subplot(2, 4, 1);
                imshow(singleDice);
                title(sprintf('Image: %s - Dice %d', imgName, i), 'Interpreter', 'none');

                subplot(2, 4, 2);
                imagesc(KMlabels);
                title('K-Means Labels');
                axis image;

                subplot(2, 4, 3);
                imagesc(labels);
                title('Filtered Components');
                axis image;
                
                subplot(2, 4, 4);
                imshow(out);
                title('Final Selection');

                 % Table with features
                featData = {
                    'Holes', vector(1);
                    'Solidity', vector(2);
                    'Eccentricity', vector(3);
                    'Circularity', vector(4);
                    'InvExtent', vector(5);
                    'RadialVariance', vector(6);
                    'Hu1', vector(7);
                    'K-Means Clusters', k_val;
                    'Prediction Score', score_val;
                    'Predicted', number
                };
                
                uitable('Data', featData, ...
                        'ColumnName', {'Feature', 'Value'}, ...
                        'RowName', [], ...
                        'Units', 'normalized', ...
                        'Position', [0.3, 0.1, 0.4, 0.3]);
                
                % Chiedi input utente
                validInput = false;
                while ~validInput
                    prompt = sprintf('[SET %s] Inserisci valore (1-6, 0 scarta): ', upper(phase));
                    val = input(prompt);
                    
                    if ~isempty(val) && isnumeric(val) && val >= 0 && val <= 6
                        validInput = true;
                    else
                        fprintf('Valore non valido.\n');
                    end
                end
                
                if val == 0
                    fprintf('Scartato.\n');
                    continue;
                end
                
                % Salva features
                % Se il file non esiste, scrivi l'header
                if ~isfile(csvPath)
                    fid = fopen(csvPath, 'w');
                    if fid == -1
                        error('Impossibile creare il file CSV');
                    end
                    fprintf(fid, 'Holes,Solidity,Eccentricity,Circularity,InvExtent,RadialVariance,Hu1,Label\n');
                    fclose(fid);
                end
                
                % Appendi il dato corrente
                fid = fopen(csvPath, 'a');
                if fid == -1
                     error('Impossibile aprire il file CSV per appendere');
                end
                
                fprintf(fid, '%f,%f,%f,%f,%f,%f,%f,%d\n', vector(1), vector(2), vector(3), vector(4), vector(5), vector(6), vector(7), val);
                fclose(fid);
                
                fprintf('Salvato nel CSV di %s (Label: %d)\n', phase, val);
                
                sampleCounter = sampleCounter + 1;
            end
        end
    end
    close(1);
    fprintf('Finito.\n');
end
