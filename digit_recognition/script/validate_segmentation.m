% validate_segmentation.m - Cristiano Rotunno 914317
function validate_segmentation()
    close all;
    
    scriptDir = fileparts(mfilename('fullpath'));
    datasetDir = fullfile(scriptDir, '..', 'dataset');
    phases = {'train', 'test'};
    imgFiles = [];
    
    for p = 1:length(phases)
        pName = phases{p};
        pImagesDir = fullfile(datasetDir, pName, 'images');
        pMasksDir  = fullfile(datasetDir, pName, 'masks');
        
        if exist(pImagesDir, 'dir')
            files = dir(fullfile(pImagesDir, 'sample_*.png'));
            for f = 1:length(files)
                files(f).phase = pName;
                files(f).fullImgPath = fullfile(pImagesDir, files(f).name);
                files(f).fullMaskPath = fullfile(pMasksDir, files(f).name);
            end
            imgFiles = [imgFiles; files];
        end
    end

    numFiles = length(imgFiles);
    if numFiles == 0
        fprintf('No samples found in digit_recognition/dataset/{train,test}/images\n');
        return;
    end
    
    hFig = figure('Name', 'Segmentation Validation', 'NumberTitle', 'off');
    set(hFig, 'Position', [100, 100, 1400, 700]);
    
    k = 1;
    while k >= 1 && k <= numFiles
        imgName = imgFiles(k).name;
        phaseName = imgFiles(k).phase;
        charIdx = strrep(imgName, 'sample_', '');
        charIdx = strrep(charIdx, '.png', '');
        id = str2double(charIdx);
        
        imgPath = imgFiles(k).fullImgPath;
        maskPath = imgFiles(k).fullMaskPath;
        
        if ~isfile(maskPath)
            k = k + 1;
            continue;
        end
        
        diceImg = imread(imgPath);
        gtMask = imread(maskPath);
        
        [pred, score, out, labels, KMlabels, k_val, vector] = segment_digit(diceImg);
        
        figure(hFig);
        clf;
        
        subplot(2, 4, 1); imshow(diceImg); title(sprintf('[%s] Sample [%d/%d] ID: %d', phaseName, k, numFiles, id));
        subplot(2, 4, 2); imshow(gtMask); title('GT Mask (User Selected)');
        subplot(2, 4, 3); imagesc(KMlabels); title(sprintf('K-Means (k=%d)', k_val)); axis image;
        subplot(2, 4, 4); imagesc(labels); title('Filtered Components'); axis image;
        subplot(2, 4, 5); imshow(out); title('Auto Selection (Final)');

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
        
        uitable('Data', tableData, 'ColumnName', {'Feature', 'Value'}, 'RowName', [], ...
                'Units', 'normalized', 'Position', [0.3, 0.05, 0.4, 0.4]);
            
        fprintf('Validating [%d/%d] ID %d: Predicted %d (Score: %.4f)\n', k, numFiles, id, pred, score);
        
        % Interaction Logic
        validKey = false;
        while ~validKey
            waitforbuttonpress;
            key = get(hFig, 'CurrentKey');
            
            if strcmp(key, 'rightarrow') || strcmp(key, 'space')
                k = k + 1;
                validKey = true;
            elseif strcmp(key, 'leftarrow')
                k = k - 1;
                if k < 1, k = 1; end
                validKey = true;
            elseif strcmp(key, 'escape') || strcmp(key, 'q')
                k = numFiles + 1; % Exit
                validKey = true;
            end
        end
    end
    fprintf('Validation ended.\n');
end
