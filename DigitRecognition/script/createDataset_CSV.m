% createDataset_CSV.m - Cristiano Rotunno 914317

function createDataset_CSV()
    scriptDir = fileparts(mfilename('fullpath'));
    datasetDir = fullfile(scriptDir, '..', 'dataset');
    
    filesToUpdate = {'train.csv', 'test.csv'};
    
    for f = 1:length(filesToUpdate)
        csvName = filesToUpdate{f};
        csvPath = fullfile(datasetDir, csvName);
        
        if ~isfile(csvPath)
            fprintf('%s not found, skipping.\n', csvName);
            continue;
        end

        % Determine phase name from csv file name
        phaseName = strrep(csvName, '.csv', '');
        currentMasksDir = fullfile(datasetDir, phaseName, 'masks');
        
        fprintf('Updating %s using masks in %s/...\n', csvName, phaseName);
        T = readtable(csvPath);
        
        if ~any(strcmp(T.Properties.VariableNames, 'id')) || ~any(strcmp(T.Properties.VariableNames, 'Label'))
            fprintf('Error: %s must have "id" and "Label" columns.\n', csvName);
            continue;
        end
        
        ids = T.id;
        labels = T.Label;
        numRows = height(T);
        
        testVec = extractFeatures(ones(10,10));
        numFeatures = length(testVec);
        allFeatures = zeros(numRows, numFeatures);
        
        for i = 1:numRows
            currentId = ids(i);
            maskName = sprintf('sample_%04d.png', currentId);
            maskPath = fullfile(currentMasksDir, maskName);
            
            if isfile(maskPath)
                mask = imread(maskPath);
                if size(mask, 3) > 1
                    mask = mask(:,:,1);
                end
                mask = mask > 0;
                allFeatures(i, :) = extractFeatures(mask);
            else
                fprintf('Warning: Mask %s not found in phase folder %s for id %d.\n', maskName, phaseName, currentId);
            end
        end
        
        featNames = cell(1, numFeatures);
        for k = 1:numFeatures
            featNames{k} = sprintf('F%d', k);
        end
        
        if numFeatures == 7
            featNames = {'Holes', 'Solidity', 'Eccentricity', 'Circularity', 'InvExtent', 'RadialVariance', 'Hu1'};
        end
        
        newT = table(ids, 'VariableNames', {'id'});
        featTable = array2table(allFeatures, 'VariableNames', featNames);
        newT = [newT, featTable];
        newT.Label = labels;
        
        writetable(newT, csvPath);
        fprintf('Updated %s (%d features).\n', csvName, numFeatures);
    end
    fprintf('Done.\n');
end
