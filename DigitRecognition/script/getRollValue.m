% getRollValue.m - Cristiano Rotunno 914317

function sum = getRollValue(image, mask)
    [dices, bboxes] = extractDices(image, mask);
    numDices = length(dices);

    sum = 0;
    
    figure;
    imshow(image);
    hold on;
    
    for i = 1:numDices
        [number, ~, ~, ~, ~, ~, ~] = segmentDigit(dices{i});
        
        sum = sum + number;
        
        rectangle('Position', bboxes(i, :), 'EdgeColor', 'r', 'LineWidth', 1);
        text(bboxes(i, 1), bboxes(i, 2) - 20, num2str(number), 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    end
    
    title(['Value: ' num2str(sum)], 'FontSize', 16);
    hold off;
end