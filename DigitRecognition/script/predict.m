% predict.m - Cristiano Rotunno 914317

function num = predict(vector)
    data = load('../model.mat');
    mdl = data.mdl;
    
    num = predict(mdl, vector);
end

