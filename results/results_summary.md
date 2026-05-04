# Results Summary
## Final selected model
The final selected model was an augmented SOLOv2 model trained using geometric and intensity augmentation.  
The final confidence threshold used for evaluation was 0.20.

## Final test results
| Metric | Value |

| Mean absolute count error | 5.39 |
| Median absolute count error | 4.00 |
| Mean percent error | 13.00% |
| Median percent error | 6.02% |
| Mean Dice | 0.9295 |
| Median Dice | 0.9425 |
| Mean Jaccard | 0.8718 |
| Median Jaccard | 0.8912 |
| mAP@0.5 | 0.8572 |

## Baseline vs augmented model
| Model | Threshold | Mean Abs Count Error | Mean Dice | Mean Jaccard | mAP@0.5 |
|---|---:|---:|---:|---:|---:|
| Baseline SOLOv2 | 0.40 | 8.42 | 0.9331 | 0.8769 | 0.8559 |
| Augmented SOLOv2 | 0.20 | 5.39 | 0.9295 | 0.8718 | 0.8572 |

## Size-stratified AP
| Object size | Baseline AP | Augmented AP |
|---|---:|---:|
| Small objects | 0.1032 | 0.1091 |
| Medium objects | 0.7438 | 0.7329 |
| Large objects | 0.9592 | 0.9642 |

## Interpretation
The augmented SOLOv2 model at threshold 0.20 achieved the best result for quantitative adipocyte counting.  
Compared with the baseline model, the mean absolute count error decreased from 8.42 to 5.39 objects per image.

The baseline model had slightly higher Dice and Jaccard scores, but the difference was small. The augmented model preserved high segmentation quality while improving counting accuracy and slightly improving mAP@0.5.

The main remaining weakness is detection of very small adipocytes.