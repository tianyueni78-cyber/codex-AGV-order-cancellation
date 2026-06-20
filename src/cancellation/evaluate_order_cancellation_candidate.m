function evaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, candidate, cancel, machineData, agvData, config, ...
    strategyName)
%EVALUATE_ORDER_CANCELLATION_CANDIDATE Evaluate one cancellation candidate.
%   The function combines Cmax_delta, SD, TD, energy_delta, and Y for a
%   single already-feasible candidate. It does not compare candidates or
%   select a strategy.

if nargin < 7
    error('evaluate_order_cancellation_candidate:MissingInput', ...
        ['baselineSchedule, candidate, cancel, machineData, agvData, ', ...
        'config, and strategyName are required.']);
end

evaluation = empty_evaluation(strategyName);

if ~isstruct(candidate)
    evaluation.report.errors{end + 1} = 'candidate must be a struct.';
    evaluation.report.rejectedReasons{end + 1} = 'invalid_candidate';
    return
end

if ~isfield(candidate, 'isFeasible') || ~candidate.isFeasible
    evaluation.report.rejectedReasons{end + 1} = 'candidate_infeasible';
    evaluation.report.errors{end + 1} = ...
        'candidate.isFeasible must be true before evaluation.';
    return
end

candidateSchedule = candidate;

[cmaxMetrics, cmaxReport] = evaluate_candidate_cmax( ...
    baselineSchedule, candidateSchedule);
[sdMetrics, sdReport] = evaluate_candidate_sd( ...
    baselineSchedule, candidateSchedule, cancel);
[tdMetrics, tdReport] = evaluate_candidate_td( ...
    baselineSchedule, candidateSchedule, cancel);
[energyMetrics, energyReport] = evaluate_candidate_energy( ...
    baselineSchedule, candidateSchedule, machineData, agvData);

evaluation.report.metricReports.Cmax = cmaxReport;
evaluation.report.metricReports.SD = sdReport;
evaluation.report.metricReports.TD = tdReport;
evaluation.report.metricReports.energy = energyReport;
evaluation.report.errors = collect_metric_errors( ...
    evaluation.report.errors, cmaxReport, 'Cmax');
evaluation.report.errors = collect_metric_errors( ...
    evaluation.report.errors, sdReport, 'SD');
evaluation.report.errors = collect_metric_errors( ...
    evaluation.report.errors, tdReport, 'TD');
evaluation.report.errors = collect_metric_errors( ...
    evaluation.report.errors, energyReport, 'energy');
evaluation.report.warnings = collect_metric_warnings( ...
    evaluation.report.warnings, energyReport, 'energy');

evaluation.report.metricStatus.Cmax = cmaxMetrics.isFeasible;
evaluation.report.metricStatus.SD = sdMetrics.isFeasible;
evaluation.report.metricStatus.TD = tdMetrics.isFeasible;
evaluation.report.metricStatus.energy = energyMetrics.isFeasible;

if ~isempty(evaluation.report.errors)
    evaluation.report.rejectedReasons{end + 1} = 'metric_evaluation_failed';
    return
end

evaluation.metrics.Cmax = cmaxMetrics.Cmax;
evaluation.metrics.Cmax_delta = cmaxMetrics.Cmax_delta;
evaluation.metrics.SD = sdMetrics.SD;
evaluation.metrics.TD = tdMetrics.TD;
evaluation.metrics.energy = energyMetrics.energy;
evaluation.metrics.energy_delta = energyMetrics.energy_delta;
evaluation.metrics.detail = struct();
evaluation.metrics.detail.baseline_Cmax = cmaxMetrics.baseline_Cmax;
evaluation.metrics.detail.baseline_energy = energyMetrics.baseline_energy;
evaluation.metrics.detail.machine_energy = energyMetrics.machine_energy;
evaluation.metrics.detail.agv_energy = energyMetrics.agv_energy;
evaluation.metrics.detail.agv_energy_source = ...
    energyMetrics.agv_energy_source;

[Y, normalizedMetrics, yReport] = calculate_y(evaluation.metrics, config);
evaluation.report.y = yReport;
evaluation.report.errors = [evaluation.report.errors, yReport.errors];

if ~isempty(evaluation.report.errors)
    evaluation.report.rejectedReasons{end + 1} = 'y_evaluation_failed';
    return
end

evaluation.metrics.normalized = normalizedMetrics;
evaluation.metrics.Y = Y;
evaluation.metrics.isFeasible = true;
evaluation.report.isFeasible = true;
end

function [Y, normalizedMetrics, report] = calculate_y(metrics, config)
Y = [];
normalizedMetrics = struct();
report = empty_y_report();

[weights, weightReport] = read_weights(config);
[normalization, normalizationReport] = read_normalization(config);
report.errors = [report.errors, weightReport.errors, ...
    normalizationReport.errors];
if ~isempty(report.errors)
    return
end

metricNames = {'Cmax_delta', 'SD', 'TD', 'energy_delta'};
Y = 0;
for i = 1:numel(metricNames)
    metricName = metricNames{i};
    normalizedValue = normalize_metric_value( ...
        metrics.(metricName), normalization.(metricName), metricName);
    normalizedMetrics.(metricName) = normalizedValue;
    Y = Y + weights.(metricName) * normalizedValue;
end

report.weights = weights;
report.normalization = normalization;
report.isFeasible = true;
end

function [weights, report] = read_weights(config)
weights = struct();
report = empty_y_report();

if ~isstruct(config) || ~isfield(config, 'weights')
    report.errors{end + 1} = 'config.weights is required.';
    return
end

metricNames = {'Cmax_delta', 'SD', 'TD', 'energy_delta'};
for i = 1:numel(metricNames)
    metricName = metricNames{i};
    if ~isfield(config.weights, metricName)
        report.errors{end + 1} = sprintf( ...
            'config.weights.%s is required.', metricName);
        continue
    end

    value = config.weights.(metricName);
    if ~isnumeric(value) || ~isscalar(value) || value < 0
        report.errors{end + 1} = sprintf( ...
            'config.weights.%s must be a non-negative numeric scalar.', ...
            metricName);
        continue
    end
    weights.(metricName) = value;
end

report.isFeasible = isempty(report.errors);
end

function [normalization, report] = read_normalization(config)
normalization = struct();
report = empty_y_report();

if ~isstruct(config) || ~isfield(config, 'normalization')
    report.errors{end + 1} = 'config.normalization is required.';
    return
end

metricNames = {'Cmax_delta', 'SD', 'TD', 'energy_delta'};
for i = 1:numel(metricNames)
    metricName = metricNames{i};
    if ~isfield(config.normalization, metricName)
        report.errors{end + 1} = sprintf( ...
            'config.normalization.%s is required.', metricName);
        continue
    end

    bounds = config.normalization.(metricName);
    if ~isstruct(bounds) || ~isfield(bounds, 'min') || ...
            ~isfield(bounds, 'max')
        report.errors{end + 1} = sprintf( ...
            'config.normalization.%s.min and .max are required.', ...
            metricName);
        continue
    end
    if ~isnumeric(bounds.min) || ~isscalar(bounds.min) || ...
            ~isnumeric(bounds.max) || ~isscalar(bounds.max) || ...
            bounds.max < bounds.min
        report.errors{end + 1} = sprintf( ...
            ['config.normalization.%s min/max must be numeric scalars ', ...
            'with max >= min.'], metricName);
        continue
    end

    normalization.(metricName) = bounds;
end

report.isFeasible = isempty(report.errors);
end

function normalizedValue = normalize_metric_value(value, bounds, metricName)
if ~isnumeric(value) || ~isscalar(value)
    error('evaluate_order_cancellation_candidate:InvalidMetric', ...
        'metrics.%s must be a numeric scalar.', metricName);
end

denominator = bounds.max - bounds.min;
if denominator == 0
    normalizedValue = 0;
else
    normalizedValue = (value - bounds.min) / denominator;
end
end

function errors = collect_metric_errors(errors, metricReport, metricName)
if ~isfield(metricReport, 'errors')
    return
end
for i = 1:numel(metricReport.errors)
    errors{end + 1} = sprintf('%s: %s', metricName, ...
        metricReport.errors{i});
end
end

function warnings = collect_metric_warnings(warnings, metricReport, metricName)
if ~isfield(metricReport, 'warnings')
    return
end
for i = 1:numel(metricReport.warnings)
    warnings{end + 1} = sprintf('%s: %s', metricName, ...
        metricReport.warnings{i});
end
end

function evaluation = empty_evaluation(strategyName)
evaluation = struct();
evaluation.strategyName = strategyName;
evaluation.metrics = struct();
evaluation.metrics.Cmax = [];
evaluation.metrics.Cmax_delta = [];
evaluation.metrics.SD = [];
evaluation.metrics.TD = [];
evaluation.metrics.energy = [];
evaluation.metrics.energy_delta = [];
evaluation.metrics.Y = [];
evaluation.metrics.isFeasible = false;
evaluation.report = struct();
evaluation.report.errors = {};
evaluation.report.warnings = {};
evaluation.report.rejectedReasons = {};
evaluation.report.metricStatus = struct();
evaluation.report.metricReports = struct();
evaluation.report.y = struct();
evaluation.report.isFeasible = false;
end

function report = empty_y_report()
report = struct();
report.errors = {};
report.warnings = {};
report.weights = struct();
report.normalization = struct();
report.isFeasible = false;
end
