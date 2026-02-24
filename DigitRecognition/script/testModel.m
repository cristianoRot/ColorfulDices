% testModel.m - Cristiano Rotunno 914317

function testModel()
    scriptDir = fileparts(mfilename('fullpath'));
    csvPath = fullfile(scriptDir, '..', 'dataset', 'test.csv');
    modelPath = fullfile(scriptDir, '..', 'model.mat');
    
    if ~isfile(csvPath)
        error('Test file (test.csv) not found.');
    end
    if ~isfile(modelPath)
        error('Model (model.mat) not found.');
    end

    loadedModel = load(modelPath);
    mdl = loadedModel.mdl;
    
    data = readtable(csvPath);
    
    X_test = data{:, 1:end-1};
    Y_test = data{:, end};
    
    if isempty(Y_test)
        error('The test.csv file is empty.');
    end

    Y_pred = predict(mdl, X_test);
    
    numCorrect = sum(Y_pred == Y_test);
    totalSamples = length(Y_test);
    accuracy = (numCorrect / totalSamples) * 100;
    
    fprintf('\n--- Model Evaluation ---\n');
    fprintf('Samples analyzed: %d\n', totalSamples);
    fprintf('Correct classifications: %d\n', numCorrect);
    fprintf('Global Accuracy: %.2f%%\n\n', accuracy);
    
    figure('Name', 'Test Evaluation', 'NumberTitle', 'off');
    cm = confusionchart(Y_test, Y_pred);
    
    cm.Title = sprintf('Confusion Matrix (Accuracy: %.2f%%)', accuracy);
    cm.ColumnSummary = 'column-normalized';
    cm.RowSummary = 'row-normalized';
    cm.XLabel = 'Predicted Class';
    cm.YLabel = 'True Class';
end
