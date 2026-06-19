projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'visualization'));

oldVisible = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');
cleanup = onCleanup(@() set(0, 'DefaultFigureVisible', oldVisible));

fig = figure('Visible', 'off');
plot([1, 2, 3], [3, 2, 1], 'LineWidth', 1.5);

outputDir = fullfile(tempdir, 'code_refactor_project_visualization_test');
outputPath = fullfile(outputDir, 'toy_curve.png');
save_figure_safely(fig, outputPath);

assert(exist(outputPath, 'file') == 2, 'Expected saved figure file was not created.');

close(fig);

fprintf('test_visualization_save_figure passed: figure saved to controlled temp path\n');
