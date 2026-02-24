% validateSegmentation.m - Cristiano Rotunno 914317

function validateSegmentation()
    close all;
    
    scriptDir = fileparts(mfilename('fullpath'));
    datasetDir = fullfile(scriptDir, '..', 'dataset');
    imagesDir = fullfile(datasetDir, 'images');
    masksDir  = fullfile(datasetDir, 'masks');
    
    if ~exist(imagesDir, 'dir') || ~exist(masksDir, 'dir')
        error('Dataset folders (images/masks) not found in DigitRecognition/dataset.');
    end
    
    imgFiles = dir(fullfile(imagesDir, 'sample_*.png'));
    if isempty(imgFiles)
        fprintf('No samples found in %s\n', imagesDir);
        return;
    end
    
    hFig = figure('Name', 'Segmentation Validation', 'NumberTitle', 'off');
    set(hFig, 'Position', [100, 100, 1400, 700]);
    
    for k = 1:length(imgFiles)
        imgName = imgFiles(k).name;
        charIdx = strrep(imgName, 'sample_', '');
        charIdx = strrep(charIdx, '.png', '');
        id = str2double(charIdx);
        
        imgPath = fullfile(imagesDir, imgName);
        maskPath = fullfile(masksDir, imgName); % They share the same name
        
        if ~isfile(maskPath)
            continue;
        end
        
        diceImg = imread(imgPath);
        % We don't use the ground truth mask for segmentation, 
        % just to show what the USER manually selected as target.
        gtMask = imread(maskPath);
        
        % Run the actual segmentation pipeline
        [pred, score, out, labels, KMlabels, k_val, vector] = segmentDigit(diceImg);
        
        figure(hFig);
        clf;
        
        % 1. Original Die
        subplot(2, 4, 1);
        imshow(diceImg);
        title(sprintf('Sample ID: %d', id));
        
        % 2. Ground Truth Mask (from dataset/masks)
        subplot(2, 4, 2);
        imshow(gtMask);
        title('GT Mask (User Selected)');
        
        % 3. K-Means result
        subplot(2, 4, 3);
        imagesc(KMlabels);
        title(sprintf('K-Means (k=%d)', k_val));
        axis image;
        
        % 4. All Filtered Components
        subplot(2, 4, 4);
        imagesc(labels);
        title('Filtered Components');
        axis image;
        
        % 5. Final Selection by segmentDigit
        subplot(2, 4, 5);
        imshow(out);
        title('Auto Selection (Final)');
        
        % 6. Features Table
        % Dynamic mapping of names if vector size changes
        numFeats = length(vector);
        featNames = cell(numFeats, 1);
        for i=1:numFeats, featNames{i} = sprintf('F%d', i); end
        if numFeats >= 9
            featNames(1:9) = {'Holes', 'Solidity', 'Eccentricity', 'Circularity', 'InvExtent', ...
                              'RadialVariance', 'Hu1', 'Hu2', 'Hu3'};
        end
        
        tableData = cell(numFeats + 2, 2);
        for i=1:numFeats
            tableData{i, 1} = featNames{i};
            tableData{i, 2} = sprintf('%.4f', vector(i));
        end
        tableData{end-1, 1} = 'Confidence Score';
        tableData{end-1, 2} = sprintf('%.4f', score);
        tableData{end, 1} = 'PREDICTED';
        tableData{end, 2} = sprintf('%d', pred);
        
        uitable('Data', tableData, ...
                'ColumnName', {'Feature', 'Value'}, ...
                'RowName', [], ...
                'Units', 'normalized', ...
                'Position', [0.3, 0.05, 0.4, 0.4]);
            
        fprintf('Validating Sample %d: Predicted %d (Score: %.4f)\n', id, pred, score);
        
        % Interactive control
        w = waitforbuttonpress;
        if w == 0 % Mouse click
            % continue
        else % Key press
            key = get(hFig, 'CurrentCharacter');
            if key == 27 || key == 'q' % ESC or Q
                break;
            end
        end
    end
    fprintf('Validation ended.\n');
end
