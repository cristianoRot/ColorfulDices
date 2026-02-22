close all;
clear all;

addpath('./change_detection/');
addpath('./DiceRecognition/script/');
addpath('./DigitRecognition/script/');
addpath('./DigitRecognition/');

fprintf('Processing video...\n');

static_images = process_video("./videos/VIDEO-09.mp4");

num_images = numel(static_images);
masks = cell(1, num_images);

fprintf('Recognizing dices...\n');

for i = 1:num_images
    image = static_images{i};
    masks{i} = segment_dices(image);
    mask = masks{i};
        
    dices_img = image .* uint8(cat(3, mask, mask, mask));

    % X DEBUG
    %figure, imshow(dices_img);
end

fprintf('Recognizing digits...\n');

for i = 1:num_images
    image = static_images{i};
    mask = masks{i};
    
    getRollValue(image, mask);
end