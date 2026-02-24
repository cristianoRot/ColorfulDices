close all;
clear all;

addpath('./change_detection/');
addpath('./dice_recognition/script/');
addpath('./digit_recognition/script/');
addpath('./digit_recognition/');

base_dir = './datasets';
train_img_dir = fullfile(base_dir, 'dataset_train', 'images');
train_mask_dir = fullfile(base_dir, 'dataset_train', 'masks');
test_img_dir = fullfile(base_dir, 'dataset_test', 'images');
test_mask_dir = fullfile(base_dir, 'dataset_test', 'masks');

if ~exist(train_img_dir, 'dir'), mkdir(train_img_dir); end
if ~exist(train_mask_dir, 'dir'), mkdir(train_mask_dir); end
if ~exist(test_img_dir, 'dir'), mkdir(test_img_dir); end
if ~exist(test_mask_dir, 'dir'), mkdir(test_mask_dir); end

% Parameters
train_ratio = 0.9;
rng(42); % For reproducibility

videos_dir = './videos';
video_files = dir(fullfile(videos_dir, '*.mp4'));

all_images = {};
all_masks = {};

fprintf('Extracting images and masks from videos...\n');
for v = 1:length(video_files)
    video_path = fullfile(videos_dir, video_files(v).name);
    fprintf('Processing %s...\n', video_files(v).name);
    
    static_images = process_video(video_path);
    num_images = numel(static_images);
    
    for i = 1:num_images
        img = static_images{i};
        mask = segment_dices(img);
        
        all_images{end+1} = img; %#ok<AGROW>
        all_masks{end+1} = mask; %#ok<AGROW>
    end
end

total_samples = length(all_images);
idx_perm = randperm(total_samples);

num_train = round(train_ratio * total_samples);

fprintf('Saving %d training and %d test samples...\n', num_train, total_samples - num_train);

for i = 1:total_samples
    idx = idx_perm(i);
    img = all_images{idx};
    mask = all_masks{idx};
    
    if islogical(mask)
        mask = uint8(mask) * 255;
    end
    
    if i <= num_train
        img_path = fullfile(train_img_dir, sprintf('image_%04d.png', i));
        mask_path = fullfile(train_mask_dir, sprintf('mask_%04d.png', i));
    else
        test_idx = i - num_train;
        img_path = fullfile(test_img_dir, sprintf('image_%04d.png', test_idx));
        mask_path = fullfile(test_mask_dir, sprintf('mask_%04d.png', test_idx));
    end
    
    imwrite(img, img_path);
    imwrite(mask, mask_path);
end
