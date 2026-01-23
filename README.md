# ColorfulDices: Automatic Dice Score Recognition

## Project Overview
The objective of this application is to analyze video sequences of dice rolls and automatically recognize the total score of each roll. The total score is calculated as the sum of the values of the top faces of all fully visible dice.

## Technical Implementation
The system utilizes a computer vision pipeline developed in MATLAB to segment dice, process images, and extract quantitative features for digit recognition.

### Code Structure
*   **`main.m`**: The entry point of the analysis pipeline. It orchestrates the segmentation and recognition process, generating a visualization that includes the original die crop, the binary mask of extracted pips, and a summary table of features.
*   **`extractDices.m`**: Handles the segmentation of individual dice from the input frame based on binary masks, isolating the regions of interest for further processing.
*   **`extractPixelsNumber.m`**: Implements the core image processing logic for feature enhancement. It converts images to the YCbCr color space, applies noise reduction (median filtering), and uses adaptive binarization with morphological operations to isolate the dice pips.
*   **`extractFeatures.m`**: Analyzes the binary images to compute key descriptors, specifically counting the connected components (pips) to determine the value of the die face.
