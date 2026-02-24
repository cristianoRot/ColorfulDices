% get_roll_value.m - Cristiano Rotunno 914317

function val = get_roll_value(image, mask)
    [dices, bboxes] = extract_dices(image, mask);
    numDices = length(dices);

    val = 0;
    
    figure;
    imshow(image);
    hold on;
    
    for i = 1:numDices
        [number, ~, ~, ~, ~, ~, ~] = segment_digit(dices{i});
        
        val = val + number;
        
        rectangle('Position', bboxes(i, :), 'EdgeColor', 'r', 'LineWidth', 1);
        text(bboxes(i, 1), bboxes(i, 2) - 20, num2str(number), 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    end
    
    title(['Total Value: ' num2str(val)], 'FontSize', 16);
    hold off;
end