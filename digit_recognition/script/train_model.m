% train_model.m - Cristiano Rotunno 914317

function train_model()
    scriptDir = fileparts(mfilename('fullpath'));
    csvPath = fullfile(scriptDir, '..', 'dataset', 'train.csv');
    data = readtable(csvPath);
    
    % Check for 'id' column and exclude it
    if any(strcmp(data.Properties.VariableNames, 'id'))
        X = data{:, 2:end-1};
    else
        X = data{:, 1:end-1};
    end
    Y = data{:, end};
    
    mdl = fitcknn(X, Y, ...
        'NumNeighbors', 5, ...
        'Standardize', true, ...
        'Distance', 'euclidean', ...
        'DistanceWeight', 'squaredinverse');
   
    cvmdl = crossval(mdl);
    loss = kfoldLoss(cvmdl);
    accuracy = (1 - loss) * 100;
    
    fprintf('Estimated Model Accuracy: %.2f%%\n', accuracy);
    
    modelPath = fullfile(scriptDir, '..', 'model.mat');
    save(modelPath, 'mdl');
end