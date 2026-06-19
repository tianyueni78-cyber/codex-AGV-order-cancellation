function fig = plot_pareto_front(objMatrix, options)
%PLOT_PARETO_FRONT Plot a 2-D Pareto objective matrix.

validate_visual_matrix(objMatrix, 'objMatrix');

if size(objMatrix, 2) ~= 2
    error('plot_pareto_front:OnlyTwoObjectives', ...
        'plot_pareto_front currently supports two objectives.');
end

if nargin < 2 || isempty(options)
    options = struct();
end

visible = get_option(options, 'visible', 'on');
fig = figure('Visible', visible);
scatter(objMatrix(:, 1), objMatrix(:, 2), 42, 'filled', ...
    'MarkerFaceColor', [0.10 0.45 0.70], ...
    'MarkerEdgeColor', [0.05 0.20 0.30]);
grid on;
box on;

xlabel(get_option(options, 'xLabel', 'Makespan'));
ylabel(get_option(options, 'yLabel', 'Total energy'));
title(get_option(options, 'title', 'Pareto front'));
end
