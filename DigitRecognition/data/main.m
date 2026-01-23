function out = main(image, mask)
    dices = extractDices(image, mask);
    numDices = length(dices);
    
    for i = 1:numDices
        bw = extractPixelsNumber(dices{i});
        [holes] = extractFeatures(bw);
        
        figure;
        subplot(1, 3, 1);
        imshow(dices{i});
        title('Original Dice');
        
        subplot(1, 3, 2);
        imshow(bw);
        title('Extracted Pixels');
        
        % Table with features
        h = subplot(1, 3, 3);
        pos = get(h, 'Position');
        delete(h);
        
        data = {'Holes', holes};
        columnNames = {'Feature', 'Value'};
        
        uitable('Data', data, ...
                'ColumnName', columnNames, ...
                'RowName', [], ...
                'Units', 'normalized', ...
                'Position', pos);
    end
    
    out = dices;
end