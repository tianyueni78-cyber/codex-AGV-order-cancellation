function fig = plot_convergence_curve(curve, options)
%PLOT_CONVERGENCE_CURVE Plot convergence curves from result.curve data.

if ~isstruct(curve) || ~isfield(curve, 'min')
    error('plot_convergence_curve:InvalidCurve', ...
        'curve must be a struct containing curve.min.');
end

validate_visual_matrix(curve.min, 'curve.min');

if nargin < 2 || isempty(options)
    options = struct();
end

visible = get_option(options, 'visible', 'on');
fig = figure('Visible', visible);
hold on;

objectiveNames = get_option(options, 'objectiveNames', {});
for objectiveIndex = 1:size(curve.min, 1)
    label = get_objective_label(objectiveNames, objectiveIndex, 'min');
    plot(curve.min(objectiveIndex, :), 'LineWidth', 1.5, 'DisplayName', label);
end

if isfield(curve, 'avg') && ~isempty(curve.avg)
    validate_visual_matrix(curve.avg, 'curve.avg');
    if ~isequal(size(curve.avg), size(curve.min))
        error('plot_convergence_curve:CurveSizeMismatch', ...
            'curve.avg must have the same size as curve.min.');
    end
    for objectiveIndex = 1:size(curve.avg, 1)
        label = get_objective_label(objectiveNames, objectiveIndex, 'avg');
        plot(curve.avg(objectiveIndex, :), '--', 'LineWidth', 1.2, 'DisplayName', label);
    end
end

hold off;
grid on;
box on;
xlabel(get_option(options, 'xLabel', 'Generation'));
ylabel(get_option(options, 'yLabel', 'Objective value'));
title(get_option(options, 'title', 'Convergence curve'));
legend('Location', 'best');
end

function label = get_objective_label(objectiveNames, objectiveIndex, kind)
if iscell(objectiveNames) && numel(objectiveNames) >= objectiveIndex
    label = [objectiveNames{objectiveIndex} ' ' kind];
else
    label = ['objective ' num2str(objectiveIndex) ' ' kind];
end
end
