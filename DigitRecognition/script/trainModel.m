% trainModel.m - Cristiano Rotunno 914317

function trainModel()
    data = readtable('../dataset/dataset.csv');
    
    X = data{:, 1:6};
    Y = data{:, 7};
    
    mdl = fitcknn(X, Y, 'NumNeighbors', 3, 'Standardize', true);
   
    save('model.mat', 'mdl');
end