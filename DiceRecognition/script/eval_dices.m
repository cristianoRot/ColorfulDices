clear all; close all;


img = imread("../dices/images/dices_8_3.png");

% Load your masks
ground_truth = logical(rgb2gray(imread("../dices/masks/dices_8_3.png")));
predicted = segment_dices(img);

% Convert to vectors and calculate confusion matrix
gt_vec = ground_truth(:);
pred_vec = predicted(:);

% MATLAB's built-in confusion matrix
C = confusionmat(gt_vec, pred_vec);

% Display confusion matrix
figure;
confusionchart(C, {'Background', 'Dice'});
title('Confusion Matrix');

% Calculate basic metrics from confusion matrix
TN = C(1,1);  % True Negatives
FP = C(1,2);  % False Positives
FN = C(2,1);  % False Negatives
TP = C(2,2);  % True Positives

% Simple metrics
accuracy = (TP + TN) / (TP + TN + FP + FN);
precision = TP / (TP + FP);
recall = TP / (TP + FN);
dice = 2*TP / (2*TP + FP + FN);

% Print results
fprintf('\nSimple Evaluation Results:\n');
fprintf('==========================\n');
fprintf('Accuracy:  %.3f\n', accuracy);
fprintf('Precision: %.3f\n', precision);
fprintf('Recall:    %.3f\n', recall);
fprintf('Dice:      %.3f\n', dice);
fprintf('\n');

% Quick visual comparison
figure;
subplot(1,3,1); imshow(ground_truth); title('Ground Truth');
subplot(1,3,2); imshow(predicted); title('Predicted');
subplot(1,3,3); imshow(predicted == ground_truth); title('Correct Pixels (white)');