clear; clc; close all;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
metricPath = fullfile(projectRoot, "results", "metric_outputs", "learning_curve_metrics_summary.csv");
outDir = fullfile(projectRoot, "results", "training_plots");



if ~exist(outDir, "dir")
    mkdir(outDir);
end
T = readtable(metricPath);
T = sortrows(T, "TrainingSamples");
fig = figure("Visible", "off", "Position", [100 100 1000 650]);

plot(T.TrainingSamples, T.MeanDice, "-o", "LineWidth", 2);
hold on;
plot(T.TrainingSamples, T.MeanJaccard, "-o", "LineWidth", 2);
plot(T.TrainingSamples, T.InstanceF1, "-o", "LineWidth", 2);

grid on;
xlabel("Number of training images");
ylabel("Metric value");
ylim([0 1]);

title("Effect of Training Set Size on SOLOv2 Adipocyte Segmentation");
legend(["Dice", "Jaccard / IoU", "Instance F1"], ...
    "Location", "southoutside", "Orientation", "horizontal");

exportgraphics(fig, fullfile(outDir, "patient_learning_curve_metrics.png"), "Resolution", 200);
close(fig);
fprintf("Saved plot:\n%s\n", fullfile(outDir, "patient_learning_curve_metrics.png"));