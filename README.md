# ColorfulDices

**ColorfulDices** is a complete, automated MATLAB-based pipeline designed to detect, separate, and recognize the values of colored dice thrown in a video. By taking a raw video feed of dice rolls, the system automatically pinpoints when the dice come to a rest, segments each individual die, and determines the face value pointing upwards.

---

## 🚀 Overview

The problem of recognizing dice values from video entails multiple computer vision challenges. The project is neatly divided into three primary modules, each handling a specific stage of the pipeline:

1. **Change Detection**: Analyzes video frames to identify motion, resting periods, and stable dice scenarios.
2. **Dice Recognition (Segmentation)**: Isolates the dice from the background and separates adjacent or touching dice.
3. **Digit Recognition**: Extracts features from the top face of the isolated dice and predicts the final rolled number.

---

## 🛠 Working Pipeline

The entry point of the project is the `main.m` script. The complete workflow operates as follows:

### 1. Change Detection (`change_detection/`)
The system reads the input video frame by frame.
- **Background Modeling & Updates**: It builds an adaptive reference background utilizing the HSV color space (specifically the Saturation/Value channels).
- **Motion Tracking**: Computes absolute differences between frames to calculate motion metrics and standard deviation to differentiate dice from the background.
- **Resting Frame Extraction**: When the motion falls below a defined threshold (`soglia_movimento`) for a specific number of frames, it assumes an equilibrium state (i.e., the dice have landed and stopped). At this point, it captures and saves the "static" frame for further processing.

### 2. Dice Recognition (`dice_recognition/`)
Once a stable frame containing the rolled dice is isolated, the system needs to locate each die effectively.
- **Masking & Cleanup**: A series of morphological operations (e.g., initial and final cleanup) are applied to remove background noise (like a dice tray) and keep the region of interest.
- **Watershed Segmentation**: If multiple dice land close together and touch, standard connected-components algorithms might group them as a single mass. The pipeline uses advanced separation logic (`separate_dices.m` and `watershed_split.m`) to cleanly decouple touching dice into distinct binary masks.
- **Circular Masking**: It applies circular or bounded masking to isolate the top-facing perimeter of the die, discarding sides and shadows.

### 3. Digit Recognition (`digit_recognition/`)
For each segmented die mask, the digit value must be extracted and classified.
- **Feature Extraction & K-Means Clustering**: The isolated die crop is transformed into LAB and HSV color spaces. A dynamic K-means clustering algorithm iterates to find the boundaries of the digits versus the die's background color.
- **Feature Filtering**: It calculates geometric and intensity features for the segmented digit candidates (e.g., Area, Solidity, Eccentricity, Circularity, Radial Variance, Hu Moments). Filters assert that the candidate blob structurally makes sense as a drawn digit/pip.
- **Model Prediction & Scoring**: The valid feature vectors are passed into a pre-trained machine learning classifier (`predict.m`). The best-scoring region nearest to the die's center is selected as the definitive label (1 to 6).

---

## 📂 Project Structure

```text
ColorfulDices/
├── main.m                      # Main script that combines the whole pipeline
├── create_dataset.m            # Script used to generate ML training data
├── README.md                   # Project documentation
│
├── change_detection/           # Module: Video Parsing
│   ├── process_video.m         # Core motion detection and frame grabber
│   └── ...
│
├── dice_recognition/           # Module: Dice Isolation
│   ├── script/
│   │   ├── segment_dices.m     # Main dice segmentation flow
│   │   ├── watershed_split.m   # Touching dice separation logic
│   │   └── ...
│   └── ...
│
└── digit_recognition/          # Module: Value Classification
    ├── script/
    │   ├── get_roll_value.m    # Entry point for digit evaluation
    │   ├── segment_digit.m     # Digit isolation through K-Means
    │   ├── extract_features.m  # Extraction of shape/Hu moment features
    │   ├── train_model.m       # Scripts for training the ML classifier
    │   └── ...
    └── dataset/                # Dataset directory for ML
```

## ⚙️ How to Run

1. Open MATLAB.
2. Navigate to the root directory `ColorfulDices/`.
3. Open the `main.m` file.
4. Set the path variable inside `process_video("...")` to your local `.mp4` video.
5. Run the script. The system will process the video, notify you of action states, and produce plots summarizing the total value of each distinct roll in the video.

## 📝 Details on the Machine Learning Approach

The **Digit Recognition** stage uses a robust model built directly off morphological features (such as *Hu Moments*, *Eccentricity*, and *Solidity*). These features scale well regardless of the dice color or orientation (rotation).

The project also includes scripts to custom-build data representations:
- Run `create_dataset.m` (in root) to slice videos into distinct images and dice masks.
- Run `create_dataset_digit.m` (in `digit_recognition`) to assist in interactively generating ground truth csv (`train.csv` / `test.csv`) to retrain models for new dice styles.
