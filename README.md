# SOLOv2 Adipocyte Instance Segmentation in MATLAB
A MATLAB project for quantitative analysis of adipocytes using SOLOv2 instance segmentation on histological image data.
LOv2-Based Adipocyte Instance Segmentation in MATLAB

---

## Table of Contents

- [SOLOv2 Adipocyte Instance Segmentation in MATLAB](#solov2-adipocyte-instance-segmentation-in-matlab)
  - [Table of Contents](#table-of-contents)
  - [Project Objective](#project-objective)
  - [Project Overview](#project-overview)
  - [Dataset](#dataset)
  - [Methodology](#methodology)
    - [1. Pairing images and masks](#1-pairing-images-and-masks)
    - [2. Cross validation split](#2-cross-validation-split)
    - [3. Preprocessing](#3-preprocessing)
    - [4. Data augmentation](#4-data-augmentation)
    - [5. Model training](#5-model-training)
      - [6. Evaluation](#6-evaluation)
  - [Results](#results)
    - [Final averaged cross validation metrics](#final-averaged-cross-validation-metrics)
    - [Fold leve summary](#fold-leve-summary)
  - [Repository Structure](#repository-structure)
  - [Setup instructions](#setup-instructions)
    - [Requirements](#requirements)
    - [Installation](#installation)
  - [Usage](#usage)
    - [Train the 4-fold augmented SOLOv2 models](#train-the-4-fold-augmented-solov2-models)
    - [Evaluate trained models](#evaluate-trained-models)
    - [Visualize predictions](#visualize-predictions)
  - [Example Outputs](#example-outputs)
  - [Limitations](#limitations)
  - [Sources and Acknowledgements](#sources-and-acknowledgements)
  - [Author](#author)

---

## Project Objective

The objective of this project, is to create and train a DL model for automatic segmentation and detection of adipocytes in images. The model is intended to give a quantitative analysis of adipose tissue by detecting individual adipocyte instances and segmenting them using instance level metrics.

The main goals were:

- prepare image mask pairs from multiple image sources
- train a model in MATLAB
- improve results using data augmentation
- evaluating the model using 4-fold cross validation
- report quantitative metrics such as Dice, Jaccard/IoU, precision, recall, F1-score, and count error

---

## Project Overview

This project uses **SOLOv2** for instance segmentation of adipocytes. Instance segmentation separates individual objects which is important for counting and quantitative analysis of the tissues.

The final version of the project includes:

- full paired dataset table creation
- filtering of empty or invalid samples
- augmented training pipeline
- 4-fold cross validation
- validation metrics for each fold
- summary metric CSV files
- example prediction visualizations

The project was implemented in **MATLAB R2024a**

---

## Dataset

The dataset consists of histological adipocyte images and their corresponding binary mask annotations. Both images and masks are stored locally and **aren't** included in the repo. That is due to the size of the database and more importantly to protect sensitive data.

The final paired dataset was build from the following sources:

| Souirce | Paired samples |
| --- | ---:|
| MTC | 136 |
| MTC2 | 47 |
| TCGA | 60 |
| OMENTAL_1 | 60 |
| OMENTAL_2 | 100 |
| STUDENT_1024 | 191 |
| GTEX_1024 | 407 |
| UNET_ORIGINAL | 133 |
| **Total** | **1134** |

During preprocessing and evaluation, empty or invalid samples were filtered out. The final cross validation was performed on **1084 validation samples across all folds**

Expected dataset layout:
```text
MIA_DL_PROJECT/
├── images/
│   └── images/
|       ├── images MTC/
|       ├── images MTC2/
|       ├── images TCGA/
|       ├── images GTEX 1024/
|       ├── images omental part 1/
|       ├── images omental part 2/
|       ├── images student project 1024/
|       └── images Unet original/
|
└── masks/
    ├── masks MTC/
    ├── masks MTC2/
    ├── masks TCGA/
    ├── masks unet GTEX 1024/
    ├── masks omental mets part 1/
    ├── masks omental mets part 2/
    ├── masks student project 1024/
    ├── masks unet original/
```

---

## Methodology

### 1. Pairing images and masks

The script:

```text
cross_validation/build_full_paired_table_cv.m
```

Creates a table containing:

- image file path,
- mask file path
- source label

The generate table is saved as:

```text
pairedTable_full_cv.mat
```

The file is ignored by Git due to its size

---

### 2. Cross validation split

The scripts:

```text
cross_validation/create_cv_folds_full_aug.m
```

Creates a 4-fold cross validation split. The split itself is stratified by source so each fold contains approximately same number of image sources.

Each fold contains around:

- 850 training images
- 270 validation images

---

### 3. Preprocessing

Each pair is prepared for SOLOv2 using:

- resizing to the target input size
- connecting component extraction from masks
- bounding box generation
- categorical label assignment
- removal of object below the minimum area threshold

The main helper script used for that:

```text
src/prepare_sample_for_solov2.m
```

---

### 4. Data augmentation

The cross validation training script implements augmentation to the training data only. The validation data remains the same.

Used augmentation:

- random 90-degree rotation
- random horizontal flips
- random vertical flips
- light intensity jitter

The final 4-fold models were trained at a resized input of **512 x 512** in order to avoid memory errors during SOLOv2 training on the entirety of dataset.

---

### 5. Model training

The main cross validation script:

```text
cross_validation/train_solov2_cv_aug_4fold.m
```

Each of the fold trains a separate SOLOv2 model:

```text
trainedSOLOv2_cv_fold1_aug.mat
trainedSOLOv2_cv_fold2_aug.mat
trainedSOLOv2_cv_fold3_aug.mat
trainedSOLOv2_cv_fold4_aug.mat
```

The trained `.mat` files are not included in the repo because of their size. It is possible to generate them by running the training scripts locally.

---

#### 6. Evaluation 

Each model was evaluated on its corresponding validation fold:

```text
fold 1 model -> fold 1 validation set
fold 2 model -> fold 2 validation set
fold 3 model -> fold 3 validation set
fold 4 model -> fold 4 validation set
```

The evaluation script is:

```text
cross_validation/evaluate_cv_aug_models_s.m
```

Metrics calculated:

- Dice coefficient
- IoU
- instance precision
- instance recall
- instance F1-score
- GT object count
- predicted object count
- absolute count error
- percentage count error

The evaluation used:

- score threshold: `0.20`
- instance matching IoU threshold: `0.50`

---

## Results

The final 4-fold cross validation results are stored in:

```text
results/metric_outputs/cv_aug_metrics_summary.csv
```

### Final averaged cross validation metrics

| Metric | Result |
|---| ---: |
| Validation samples | 1084 |
| Score threshold | 0.20 |
| Instance IoU threshold | 0.50 |
| Mean Dice | 0.90607 |
| Mean IoU | 0.83758 |
| Instance Precision | 0.82121 |
| Instance Recall | 0.83938 |
| Instance F1-score | 0.83018 |
| GT objects | 95,359 |

### Fold leve summary

| Fold | Validation samples | Mean Dice | Mean IoU | Instance Precision | Instance Recall | Instance F1 |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 272 | 0.90966 | 0.84150 | 0.82395 | 0.83767 | 0.83075 |
| 2 | 271 | 0.90037 | 0.83091 | 0.81736 | 0.84214 | 0.82957 |
| 3 | 272 | 0.91001 | 0.84299 | 0.82352 | 0.85055 | 0.83682 |
| 4 | 269 | 0.90423 | 0.83491 | 0.82003 | 0.82718 | 0.82359 |
| **Mean** | **1084** | **0.90607** | **0.83758** | **0.82121** | **0.83938** | **0.83018** |

The results show that the augmented SOLOv2 model achieved a strong overlap segmentation performance, with the average Dice score being approximately **90.6%** and IoU of **83.8%** across the validation folds.

The instance level F1-score of approximately **83.0%** shows that the model was also pretty effective at separating and matching individual adipocyte instances.

---

## Repository Structure

```text
.
├── cross_validation/
│   ├── build_full_paired_table_cv.m
│   ├── create_cv_folds_full_aug.m
│   ├── train_solov2_cv_aug_4fold.m
│   └── evaluate_cv_aug_models_s.m
│
├── evaluation/
|   ├── count_metrics_test_full_aug.m
|   ├── dice_jaccard_test_full_aug.m
|   ├── instance_metrics_test_full_aug.m
|   ├── visualize_test_predictions_full_aug.m
|   └── visualize_val_predictions_full_aug.m
|
├── results/
|   ├── metric_outputs/
|   |   ├── cv_aug_metrics_summary.csv
|   |   ├── cv_fold1_per_image_metrics.csv
|   |   ├── cv_fold2_per_image_metrics.csv
|   |   ├── cv_fold3_per_image_metrics.csv
|   |   └── cv_fold4_per_image_metrics.csv
|   |
|   ├── prediction_examples/
|   ├── training_plots/
|   ├── final_metrics_table.csv
|   └── results_summary.md
|
├── src/
|   ├── add_source.m
|   ├── adipocyte_annotations.m
|   ├── augment_solov2_cell.m
|   ├── build_mastertable_allsources.m
|   ├── build_pairs.m
|   ├── clean_split_10_5.m
|   ├── find_empty_samples.m
|   ├── folderReport.m
|   ├── folder_split.m
|   ├── make_SOLOv2_cell.m
|   ├── prepare_sample_for_solov2.m
|   └── read_and_resize_img.m
|
├── training/
|   ├── train_solov2_full_aug.m
|   └── train_solov2_full_strong.m
|
├── .gitignore
├── .gitattributes
├── environment_notes.md
└── README.md
```

---

## Setup instructions 

### Requirements

This project was develop and tested using:

- MATLAB R2024a
- Computer Vision Toolbox
- Deep Learning Toolbox
- Image Processing Toolbox
A GPU is recommended for training. CPU execution is possible but way slower, talking from experience.

---

### Installation

1. Clone the repo:

```bash
git clone <repository-url>
cd <repository-name>
```

2. Open MATLAB and set the repository as the current folder.

3. Add all project folder to the MATLAB path:

```matlab
addpath(genpath(pwd));
```

4. Place the dataset locally, with the expected folder structure

```text
dataset/images/images/...
dataset/masks/masks/...
```

5. Build the full paired table:

```matlab
build_full_paired_table.csv
```

6. Create cross-validation folds:

```matlab
create_cv_folds_full_aug
```

---

## Usage

### Train the 4-fold augmented SOLOv2 models

Run:

```matlab
train_solov2_cv_aug_4fold
```

By default, the script can be configured to run only the selected folds:

```matlab
foldsToRun = 1;
```

or all the folds:

```matlab
foldsToRun = 1:4
```

The trained models are saved locally in: 

```text
results/cv_aug_models/
```

This folder is ignored by Git due to file size

---

### Evaluate trained models

Run: 

```matlab
evaluate_cv_aug_models_s
```

The evaluation script creates:

```text
results/metric_outputs/cv_aug_metrics_summary.csv
results/metric_outputs/cv_fold1_per_image_metrics.csv
results/metric_outputs/cv_fold2_per_image_metrics.csv
results/metric_outputs/cv_fold3_per_image_metrics.csv
results/metric_outputs/cv_fold4_per_image_metrics.csv
```
---

### Visualize predictions

Use the visualization scripts in the `evaluation/` folder:

```matlab
visualize_val_predictions_full_aug
visualize_test_predictions_full_aug
```

The output images are saved in:

```text
results/prediction_examples/
```

---

## Example Outputs

Example prediction images in:

```text
results/prediction_examples/
```

Recommended examples:

```text
fold1_prediction_example.png
fold2_prediction_example.png
fold3_prediction_example.png
fold4_prediction_example.png
```

Training progress screenshots in:

```text
results/training_plots/
```

Recommended examples:

```text
cv_fold1_training.png
cv_fold2_training.png
cv_fold3_training.png
cv_fold4_training.png
```

---

## Limitations

- The dataset is not included in the repository 
- Trained `.mat` model files are also not included due to size, but can be generated from the scripts
- The final cross validation models were trained at `512x512` input resolution due to memory limitations during SOLOv2 training
- Results depend on score threshold and instance IoU threshold settings
- Some paired samples were removed, that is because they contained no valid mask instances after preprocessing

---

## Sources and Acknowledgements

- MathWorks documentation for SOLOv2 instance segmentation in MATLAB
- Dataset and task description provided as a part of Medical Image Analysis / Bioimage Informatics / Deep Learning course
- README structure follows guidelines from:
    - Best-README-Template by Othneil Drew
    - README template by DomPizzie
    - awesome-readme curated examples by Matias Singers

---

## Author 

Kacper Grzybek

Biomedical Engineering student project