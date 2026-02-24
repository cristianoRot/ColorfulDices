% create_dataset_digit.m - Cristiano Rotunno 914317

function create_dataset_digit()
    fclose('all');

    scriptDir = fileparts(mfilename('fullpath'));
    baseDatasetsDir = fullfile(scriptDir, '..', '..', 'datasets');
    datasetDir = fullfile(scriptDir, '..', 'dataset');
    
    phases = {'train', 'test'};

    hFig = figure(1);
    set(hFig, 'Position', [100, 100, 1400, 600]);

    for p = 1:length(phases)
        phase = phases{p};
        fprintf('\n--- Processing %s set ---\n', phase);
        
        % Paths for saving images and masks for the current phase
        phaseDir = fullfile(datasetDir, phase);
        saveImagesDir = fullfile(phaseDir, 'images');
        saveMasksDir  = fullfile(phaseDir, 'masks');
        
        if ~exist(saveImagesDir, 'dir'), mkdir(saveImagesDir); end
        if ~exist(saveMasksDir, 'dir'), mkdir(saveMasksDir); end

        % Counter for unique filenames within the current phase
        phaseCounter = 1;
        
        imagesDir = fullfile(baseDatasetsDir, ['dataset_' phase], 'images');
        masksDir  = fullfile(baseDatasetsDir, ['dataset_' phase], 'masks');
        csvPath   = fullfile(datasetDir, [phase '.csv']);
        
        if isfile(csvPath)
            delete(csvPath);
        end

        images = dir(fullfile(imagesDir, '*.png')); 
        if isempty(images)
             images = dir(fullfile(imagesDir, '*.jpg'));
        end
        
        for k = 1:length(images)
            imgName = images(k).name;
            if imgName(1) == '.'
                continue; 
            end
            
            imgPath = fullfile(imagesDir, imgName);
            maskName = strrep(imgName, 'image_', 'mask_');
            maskPath = fullfile(masksDir, maskName);
            
            if ~isfile(maskPath)
                fprintf('Missing mask for %s, skipping.\n', imgName);
                continue;
            end

            fprintf('Processing %s (%s)...\n', imgName, phase);
            
            im = imread(imgPath);
            mask = imread(maskPath);

            if size(mask, 3) > 1
                mask = mask(:,:,1);
            end
            mask = mask > 0;
            
            if size(im, 1) ~= size(mask, 1) || size(im, 2) ~= size(mask, 2)
                mask = imresize(mask, [size(im, 1), size(im, 2)], 'nearest');
            end

            [dices, ~] = extract_dices(im, mask);
            
            for i = 1:length(dices)
                singleDice = dices{i};
                
                % Standard processing to get candidate regions
                k_val = 5; 
                [high, width, ~] = size(singleDice);
                data = getFeaturesVector(singleDice);
                
                kmeansLabels = kmeans(data, k_val, 'Replicates', 3, 'MaxIter', 500);
                kmeansLabels = reshape(kmeansLabels, high, width);
                
                labels = separateClusters(kmeansLabels);
                totalArea = high * width;
                labels = getLabelsFiltered(labels, totalArea);

                % Graphics setup
                figure(hFig);
                clf; 
                
                subplot(1, 4, 1);
                imshow(singleDice);
                title(sprintf('%s - Dice %d', imgName, i), 'Interpreter', 'none');

                subplot(1, 4, 2);
                imagesc(kmeansLabels);
                title('K-Means Labels');
                axis image;

                subplot(1, 4, 3);
                imagesc(labels);
                title('CLICK on the digit region');
                axis image;
                
                % Manual selection
                selectedLabel = 0;
                while selectedLabel == 0
                    try
                        [x, y] = ginput(1);
                    catch
                        fprintf('Interaction interrupted.\n');
                        return;
                    end
                    x = round(x); y = round(y);
                    if x >= 1 && x <= width && y >= 1 && y <= high
                        selectedLabel = labels(y, x);
                    end
                end
                
                selectedMask = (labels == selectedLabel);
                selectedMask = adjustNumberImage(selectedMask, 10);
                
                subplot(1, 4, 4);
                imshow(selectedMask);
                title('Selected Mask');

                vector = extract_features(selectedMask);
                
                % Ask for ground truth
                validInput = false;
                while ~validInput
                    prompt = sprintf('[SET %s] Value (1-6, 0 skip): ', upper(phase));
                    val = input(prompt);
                    if ~isempty(val) && isnumeric(val) && val >= 0 && val <= 6
                        validInput = true;
                    else
                        fprintf('Invalid value.\n');
                    end
                end
                
                if val == 0
                    fprintf('Skipped.\n');
                    continue;
                end
                
                % Save Image and Mask
                saveName = sprintf('sample_%04d.png', phaseCounter);
                imwrite(singleDice, fullfile(saveImagesDir, saveName));
                imwrite(selectedMask, fullfile(saveMasksDir, saveName));
                
                % Save Features to CSV
                if ~isfile(csvPath)
                    fid = fopen(csvPath, 'w');
                    fprintf(fid, 'id,Holes,Solidity,Eccentricity,Circularity,InvExtent,RadialVariance,Hu1,Hu2,Hu3,Label\n');
                    fclose(fid);
                end
                fid = fopen(csvPath, 'a');
                fprintf(fid, '%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d\n', phaseCounter, vector(1), vector(2), vector(3), vector(4), vector(5), vector(6), vector(7), vector(8), vector(9), val);
                fclose(fid);
                
                fprintf('Saved Sample %04d (Label: %d)\n', phaseCounter, val);
                phaseCounter = phaseCounter + 1;
            end
        end
    end
    close(hFig);
    fprintf('Done. Dataset saved in digit_recognition/dataset/\n');
end

function data = getFeaturesVector(image)
    image = im2double(image);
    lab = rgb2lab(image);
    hsv = rgb2hsv(image);
    data = [reshape(lab, [], 3), reshape(hsv(:,:,2), [], 1)];
    min_val = min(data); max_val = max(data);
    range_val = max_val - min_val;
    range_val(range_val == 0) = 1;
    data = (data - min_val) ./ range_val;
end

function out = separateClusters(kmeansLabels)
    [h, w] = size(kmeansLabels);
    out = zeros(h, w);
    nextID = 1;
    k = max(kmeansLabels(:));
    for c = 1:k
        [objLabels, numObjs] = bwlabel(kmeansLabels == c);
        for n = 1:numObjs
            out(objLabels == n) = nextID;
            nextID = nextID + 1;
        end
    end
end

function labels = getLabelsFiltered(labels, totalArea)
    numLabels = max(labels(:));
    for i = 1:numLabels
        area = sum(labels(:) == i);
        if area / totalArea < 0.01 || area / totalArea > 0.20
            labels(labels == i) = 0;
        end
    end
end

function bw = adjustNumberImage(bw, T)
    invBw = ~bw;
    [L, numRegions] = bwlabel(invBw, 4);
    stats = regionprops(L, 'Area', 'PixelIdxList');
    if isempty(stats), return; end
    areas = [stats.Area];
    [~, mainIdx] = max(areas);
    for i = 1:numRegions
        if i ~= mainIdx && stats(i).Area <= T
            bw(stats(i).PixelIdxList) = 1;
        end
    end
end
