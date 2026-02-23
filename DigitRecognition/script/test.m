% test.m - Cristiano Rotunno 914317

function out = test()
    close all;
    
    scriptDir = fileparts(mfilename('fullpath'));
    imgPath = fullfile(scriptDir, '..', 'data', 'img0.png');
    maskPath = fullfile(scriptDir, '..', 'data', 'mask0.png');    
    
    if ~isfile(imgPath) || ~isfile(maskPath)
        error('Image or mask not found in /data/ directory.');
    end
    
    image = imread(imgPath);
    mask = imread(maskPath);
    
    [dices, ~] = extractDices(image, mask);
    numDices = length(dices);
    
    for i = 1:numDices
        [number, score_val, out, labels, KMlabels, k_val, vector] = segmentDigit(dices{i});

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
            'InvExtent', vector(5); 
            'RadialVariance', vector(6);
            'Hu1', vector(7);
            'K-Means Clusters', k_val;
            'Prediction Score', score_val;
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