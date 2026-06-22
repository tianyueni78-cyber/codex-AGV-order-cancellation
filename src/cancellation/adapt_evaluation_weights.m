function [weights, report] = adapt_evaluation_weights(features, baseConfig)
%ADAPT_EVALUATION_WEIGHTS Build rule-based adaptive evaluation weights.
%   [weights, report] = ADAPT_EVALUATION_WEIGHTS(features, baseConfig)
%   adjusts the fixed baseline weights using stage K rule-based features.
%   It does not evaluate candidates or replace feasibility checks.

if nargin < 1
    error('adapt_evaluation_weights:MissingInput', ...
        'features is required.');
end

if nargin < 2
    baseConfig = struct();
end

report = empty_report();
weights = read_baseline_weights(baseConfig);
weights = normalize_weights(weights);
baselineWeights = weights;

if get_logical_field(features, 'unsupported_flag')
    report.reason = 'unsupported_state_keep_baseline';
    report.applied_rules{end + 1} = 'unsupported_state';
    report.baseline_weights = baselineWeights;
    report.weights = weights;
    return
end

localFeasible = get_logical_field(features, 'local_repair_feasible');
completeFeasible = get_logical_field(features, ...
    'complete_rescheduling_feasible');

if ~localFeasible && completeFeasible
    weights = make_efficiency_focused_weights();
    report.applied_rules{end + 1} = ...
        'local_infeasible_prefer_complete_rescheduling';
    report.reason = 'local_infeasible_trigger_complete';
    report.preferred_strategy = 'complete_rescheduling';
    report.isAdaptive = true;
    report.baseline_weights = baselineWeights;
    report.weights = weights;
    return
end

if localFeasible && ~completeFeasible
    weights = make_stability_focused_weights();
    report.applied_rules{end + 1} = ...
        'complete_infeasible_prefer_local_repair';
    report.reason = 'complete_infeasible_trigger_local';
    report.preferred_strategy = 'local_repair';
    report.isAdaptive = true;
    report.baseline_weights = baselineWeights;
    report.weights = weights;
    return
end

if ~localFeasible && ~completeFeasible
    report.applied_rules{end + 1} = 'both_candidates_infeasible';
    report.reason = 'no_feasible_candidate_keep_baseline';
    report.baseline_weights = baselineWeights;
    report.weights = weights;
    return
end

cancelTimeRatio = get_numeric_field(features, 'cancel_time_ratio', 0.5);
if cancelTimeRatio < 0.33
    weights.Cmax_delta = weights.Cmax_delta + 0.15;
    weights.energy_delta = weights.energy_delta + 0.15;
    report.applied_rules{end + 1} = 'early_cancel_efficiency_focus';
elseif cancelTimeRatio < 0.67
    report.applied_rules{end + 1} = 'middle_cancel_balanced';
else
    weights.SD = weights.SD + 0.15;
    weights.TD = weights.TD + 0.15;
    report.applied_rules{end + 1} = 'late_cancel_stability_focus';
end

frozenRatio = get_numeric_field(features, 'frozen_operation_ratio', 0);
if frozenRatio >= 0.67
    weights.SD = weights.SD + 0.10;
    weights.TD = weights.TD + 0.10;
    report.applied_rules{end + 1} = 'high_frozen_ratio_stability_focus';
end

remainingThreshold = read_adaptive_threshold( ...
    baseConfig, 'remaining_operation_count_high', 3);
remainingCount = get_numeric_field(features, 'remaining_operation_count', 0);
if remainingCount >= remainingThreshold
    weights.Cmax_delta = weights.Cmax_delta + 0.10;
    weights.energy_delta = weights.energy_delta + 0.10;
    report.applied_rules{end + 1} = 'many_remaining_operations_efficiency_focus';
end

weights = normalize_weights(weights);
report.isAdaptive = has_weight_changed(weights, baselineWeights);
if report.isAdaptive
    report.reason = 'rule_based_adaptive_weights';
else
    report.reason = 'baseline_weights';
end
report.baseline_weights = baselineWeights;
report.weights = weights;
end

function weights = read_baseline_weights(baseConfig)
metricNames = {'Cmax_delta', 'SD', 'TD', 'energy_delta'};
weights = default_weights();

if ~isstruct(baseConfig) || ~isfield(baseConfig, 'weights') || ...
        ~isstruct(baseConfig.weights)
    return
end

for idx = 1:numel(metricNames)
    metricName = metricNames{idx};
    if isfield(baseConfig.weights, metricName)
        value = baseConfig.weights.(metricName);
        if isnumeric(value) && isscalar(value) && isfinite(value) && value >= 0
            weights.(metricName) = value;
        end
    end
end
end

function weights = default_weights()
weights = struct();
weights.Cmax_delta = 0.25;
weights.SD = 0.25;
weights.TD = 0.25;
weights.energy_delta = 0.25;
end

function weights = make_efficiency_focused_weights()
weights = struct();
weights.Cmax_delta = 0.45;
weights.SD = 0.05;
weights.TD = 0.05;
weights.energy_delta = 0.45;
end

function weights = make_stability_focused_weights()
weights = struct();
weights.Cmax_delta = 0.10;
weights.SD = 0.45;
weights.TD = 0.35;
weights.energy_delta = 0.10;
end

function weights = normalize_weights(weights)
metricNames = {'Cmax_delta', 'SD', 'TD', 'energy_delta'};
total = 0;
for idx = 1:numel(metricNames)
    metricName = metricNames{idx};
    value = weights.(metricName);
    if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value < 0
        value = 0;
    end
    weights.(metricName) = value;
    total = total + value;
end

if total <= 0
    weights = default_weights();
    return
end

for idx = 1:numel(metricNames)
    metricName = metricNames{idx};
    weights.(metricName) = weights.(metricName) / total;
end
end

function threshold = read_adaptive_threshold(baseConfig, fieldName, defaultValue)
threshold = defaultValue;
if isstruct(baseConfig) && isfield(baseConfig, 'adaptive') && ...
        isstruct(baseConfig.adaptive) && isfield(baseConfig.adaptive, fieldName)
    value = baseConfig.adaptive.(fieldName);
    if isnumeric(value) && isscalar(value) && isfinite(value)
        threshold = value;
    end
end
end

function changed = has_weight_changed(weights, baselineWeights)
metricNames = {'Cmax_delta', 'SD', 'TD', 'energy_delta'};
changed = false;
for idx = 1:numel(metricNames)
    metricName = metricNames{idx};
    if abs(weights.(metricName) - baselineWeights.(metricName)) > 1e-12
        changed = true;
        return
    end
end
end

function value = get_numeric_field(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && isnumeric(s.(fieldName)) && ...
        isscalar(s.(fieldName)) && isfinite(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = get_logical_field(s, fieldName)
value = false;
if isstruct(s) && isfield(s, fieldName)
    rawValue = s.(fieldName);
    if islogical(rawValue) && isscalar(rawValue)
        value = rawValue;
    elseif isnumeric(rawValue) && isscalar(rawValue)
        value = rawValue ~= 0;
    end
end
end

function report = empty_report()
report = struct();
report.reason = '';
report.applied_rules = {};
report.isAdaptive = false;
report.preferred_strategy = '';
report.baseline_weights = struct();
report.weights = struct();
end
