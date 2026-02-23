% predict.m - Cristiano Rotunno 914317

function [pred, scores, loss] = predict(vector)
    scriptDir = fileparts(mfilename('fullpath'));
    modelPath = fullfile(scriptDir, '..', 'model.mat');
    
    if ~isfile(modelPath)
        error('Model (model.mat) not found.');
    end
    
    data = load(modelPath);
    mdl = data.mdl;
    
    [pred, scores, loss] = predict(mdl, vector);
end

