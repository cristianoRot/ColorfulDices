% trainModel.m - Cristiano Rotunno 914317

function trainModel()
    scriptDir = fileparts(mfilename('fullpath'));
    csvPath = fullfile(scriptDir, '..', 'dataset', 'train.csv');
    data = readtable(csvPath);
    
    X = data{:, 1:end-1};
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