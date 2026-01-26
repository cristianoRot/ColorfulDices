% createDataset.m
function createDataset()
    % Chiudi eventuali file aperti precedentemente
    fclose('all');

    imagesDir = '../../DiceRecognition/dices/images';
    masksDir  = '../../DiceRecognition/dices/masks';
    datasetDir = '../dataset';

    if ~exist(datasetDir, 'dir')
        mkdir(datasetDir);
    end

    % Trova tutte le immagini .jpg o .png (aggiustare estensione se necessario)
    images = dir(fullfile(imagesDir, '*.jpg')); 
    if isempty(images)
         images = dir(fullfile(imagesDir, '*.png'));
    end
    
    sampleCounter = 1;

    % Setup figure once
    hFig = figure(1);
    set(hFig, 'Position', [100, 100, 1200, 600]);

    for k = 1:length(images)
        imgName = images(k).name;
        if imgName(1) == '.'
            continue; % Salta file nascosti
        end
        
        imgPath = fullfile(imagesDir, imgName);
        maskPath = fullfile(masksDir, imgName); % Assume stesso nome esatto
        
        % Verifica estensione maschera (potrebbe essere png anche se img è jpg)
        [~, ~, ext] = fileparts(imgName);
        if ~isfile(maskPath)
             % Prova a cercare maschera con estensione .png se l'originale non c'è
             [~, nameNoExt, ~] = fileparts(imgName);
             maskPathPng = fullfile(masksDir, [nameNoExt, '.png']);
             if isfile(maskPathPng)
                 maskPath = maskPathPng;
             else
                fprintf('Maschera mancante per %s, salto.\n', imgName);
                continue;
             end
        end

        fprintf('Elaborazione %s...\n', imgName);
        
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
        dices = extractDices(im, mask);
        
        for i = 1:length(dices)
            singleDice = dices{i};
            
            % Estrai features
            [KMlabels, labels, out] = extractPixelsNumber(singleDice);
            
            % Mostra il dado e l'immagine processata
            figure(hFig);
            clf; 
            subplot(2, 4, 1);
            imshow(singleDice);
            title(sprintf('Image: %s - Dice %d', imgName, i));

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
            
            vector = extractFeatures(out);

             % Table with features
            featData = {
                'Holes', vector(1);
                'Solidity', vector(2);
                'Extent', vector(3);
                'Eccentricity', vector(4);
                'Circularity', vector(5);
                'CentroidDist', vector(6)
            };
            
            uitable('Data', featData, ...
                    'ColumnName', {'Feature', 'Value'}, ...
                    'RowName', [], ...
                    'Units', 'normalized', ...
                    'Position', [0.3, 0.1, 0.4, 0.3]);
            
            % Chiedi input utente
            validInput = false;
            while ~validInput
                prompt = sprintf('Inserisci valore (1-6, 0 scarta): ');
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
            % Salva features in un unico file CSV
            csvPath = fullfile(datasetDir, 'dataset.csv');
            
            % Se il file non esiste, scrivi l'header
            if ~isfile(csvPath)
                fid = fopen(csvPath, 'w');
                if fid == -1
                    error('Impossibile creare il file CSV');
                end
                fprintf(fid, 'Holes,Solidity,Extent,Eccentricity,Circularity,CentroidDist,Label\n');
                fclose(fid);
            end
            
            % Appendi il dato corrente
            fid = fopen(csvPath, 'a');
            if fid == -1
                 error('Impossibile aprire il file CSV per appendere');
            end
            
            fprintf(fid, '%f,%f,%f,%f,%f,%f,%d\n', vector(1), vector(2), vector(3), vector(4), vector(5), vector(6), val);
            fclose(fid);
            
            fprintf('Salvato nel CSV (Label: %d)\n', val);
            
            sampleCounter = sampleCounter + 1;
        end
    end
    close(1);
    fprintf('Finito.\n');
end
