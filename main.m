close all;
clear all;

addpath('./change_detection/');
addpath('./DiceRecognition/script/');
addpath('./DigitRecognition/script/');

static_images = process_video("./videos/VIDEO-04.mp4");

num_images = numel(static_images);

for i = 1:num_images
    image = static_images{i};
    mask = segment_dices(image);
    
    
    dices_img = image .* uint8(cat(3, mask, mask, mask));
    figure, imshow(dices_img);
end