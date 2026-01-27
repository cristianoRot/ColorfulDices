% test.m - Cristiano Rotunno 914317

function out = test()
    close all;
    image = imread('../data/img0.png');
    mask = imread('../data/mask0.png');    
    
    [dices, ~] = extractDices(image, mask);
    numDices = length(dices);
    
    for i = 1:numDices
        [KMlabels, labels, out] = extractPixelsNumber(dices{i});
        vector = extractFeatures(out);
        number = predict(vector);

        % Debug.
        
        figure;
        subplot(2, 4, 1);
        imshow(dices{i});
        title('Original Dice');

        subplot(2, 4, 2);
        imagesc(KMlabels);
        title('K-Means Labels');
        axis image;

        subplot(2, 4, 3);
        imagesc(labels);
        title('Filtered Components');
        axis image;
        
        subplot(2, 4, 4);
        imshow(out);
        title('Final Selection');
        
        data = {
            'Holes', vector(1); 
            'Solidity', vector(2); 
            'Eccentricity', vector(3);
            'Circularity', vector(4);
            'Extent', vector(5); 
            'PerimAreaRatio', vector(6);
            'Predicted', number
        };
        columnNames = {'Feature', 'Value'};

        uitable('Data', data, ...
                'ColumnName', columnNames, ...
                'RowName', [], ...
                'Units', 'normalized', ...
                'Position', [0.3, 0.1, 0.4, 0.3]);
    end
    
    out = dices;
end