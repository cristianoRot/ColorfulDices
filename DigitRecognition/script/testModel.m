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
    
    % Check for 'id' column and exclude it
    if any(strcmp(data.Properties.VariableNames, 'id'))
        X_test = data{:, 2:end-1};
    else
        X_test = data{:, 1:end-1};
    end
    Y_test = data{:, end};
    
    if isempty(Y_test)
        error('The test.csv file is empty.');
    end

    [Y_pred, scores] = predict(mdl, X_test);
    
    numCorrect = sum(Y_pred == Y_test);
    totalSamples = length(Y_test);
    accuracy = (numCorrect / totalSamples) * 100;
    
    stats = confusionmat(Y_test, Y_pred);
    precision = diag(stats) ./ sum(stats, 1)';
    recall = diag(stats) ./ sum(stats, 2);
    
    fprintf('\n--- Global Evaluation ---\n');
    fprintf('Samples analyzed: %d\n', totalSamples);
    fprintf('Correct classifications: %d\n', numCorrect);
    fprintf('Global Accuracy: %.2f%%\n', accuracy);
    
    fprintf('\n--- Detailed Analysis per Digit ---\n');
    fprintf('Digit | Precision | Recall\n');
    fprintf('---------------------------\n');
    for i = 1:6
        p_val = 0; r_val = 0;
        if i <= size(precision, 1), p_val = precision(i); end
        if i <= size(recall, 1), r_val = recall(i); end
        fprintf('  %d   |  %6.2f%%  | %6.2f%%\n', i, p_val*100, r_val*100);
    end
    
    max_scores = max(scores, [], 2);
    avg_confidence = mean(max_scores) * 100;
    
    fprintf('\n--- Prediction Quality ---\n');
    fprintf('Average model confidence: %.2f%%\n', avg_confidence);
    
    uncertain_idx = find(max_scores < 0.7);
    fprintf('Uncertain samples (<70%% confidence): %d\n', length(uncertain_idx));
    
    % Confusion Matrix
    figure('Name', 'Global Metrics', 'NumberTitle', 'off');
    cm = confusionchart(Y_test, Y_pred);
    cm.Title = sprintf('Confusion Matrix (Acc: %.2f%%)', accuracy);
    cm.ColumnSummary = 'column-normalized';
    cm.RowSummary = 'row-normalized';
    
    % Confidence Distribution
    figure('Name', 'Confidence Analysis', 'NumberTitle', 'off');
    histogram(max_scores, 10, 'FaceColor', '#EDB120');
    title('Confidence Distribution in Predictions');
    xlabel('Confidence Score'); ylabel('Sample Count');
end
