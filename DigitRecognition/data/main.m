function out = main(image, mask)
    dices = extractDices(image, mask);
    numDices = length(dices);
    
    for i = 1:numDices
        [KMlabels, KMbw, labels, out] = extractPixelsNumber(dices{i});
        [holes, pa] = extractFeatures(out);

        number = predict(holes, pa);

        fprintf('Number Predicted: %d\n', number);

        % Debug.
        
        figure;
        subplot(2, 5, 1);
        imshow(dices{i});
        title('Original Dice');

        subplot(2, 5, 2);
        imagesc(KMlabels);
        title('K-Means Labels');
        axis image;

        subplot(2, 5, 3);
        imshow(KMbw);
        title('Binary Map (Edges Removed)');

        subplot(2, 5, 4);
        imagesc(labels);
        title('Filtered Components');
        axis image;
        
        subplot(2, 5, 5);
        imshow(out);
        title('Final Selection');
        
        data = {'Holes', holes; 'P^2/A', pa};
        columnNames = {'Feature', 'Value'};

        uitable('Data', data, ...
                'ColumnName', columnNames, ...
                'RowName', [], ...
                'Units', 'normalized', ...
                'Position', [0.3, 0.1, 0.4, 0.3]);
    end
    
    out = dices;
end