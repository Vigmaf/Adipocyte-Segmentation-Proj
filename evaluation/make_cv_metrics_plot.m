clear; clc; close all;
projectRoot = "C:\Users\Admin.VIG\Desktop\MIA_DL_PROJECT";
metricPath = fullfile(projectRoot, "results", "metric_outputs", "cv_aug_metrics_summary.csv");
outDir = fullfile(projectRoot, "results", "training_plots");
if ~exist(outDir, "dir")
    mkdir(outDir);
end
T = readtable(metricPath);

% Remove final summary row if Fold == 999
Tfolds = T(T.Fold ~= 999, :);
metrics = [Tfolds.MeanDice, Tfolds.MeanJaccard, Tfolds.InstanceF1];
fig = figure("Visible", "off", "Position", [100 100 1000 600]);

bar(metrics);
grid on;

xticklabels("Fold " + string(Tfolds.Fold));
ylabel("Metric value");
ylim([0 1]);

legend(["Dice", "Jaccard / IoU", "Instance F1"], "Location", "southoutside", "Orientation", "horizontal");

title("4-Fold Cross-Validation Metrics for Augmented SOLOv2 Model");
exportgraphics(fig, fullfile(outDir, "cv_aug_metrics_barplot.png"), "Resolution", 200);

close(fig);
fprintf("Saved metrics plot to results/training_plots/cv_aug_metrics_barplot.png\n");