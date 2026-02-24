close all;
clear all;

img = imread("../../datasets/dataset_train/images/image_0003.png");
out = segment_dices(img);

figure, 
imshow(out);

dices_img = img .* uint8(cat(3, out, out, out));
figure, 
imshow(dices_img), title("final masked image");
