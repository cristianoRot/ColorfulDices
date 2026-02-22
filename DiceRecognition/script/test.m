close all;
clear all;

img = imread("../../datasets/dataset_test/images/image_0002.png");
out = segment_dices(img);

figure, 
imshow(out);

dices_img = img .* uint8(cat(3, out, out, out));
figure, 
imshow(dices_img), title("final masked image");
