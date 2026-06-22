function summary = summarize_order_cancellation_benchmark(results)
%SUMMARIZE_ORDER_CANCELLATION_BENCHMARK Aggregate stage-L benchmark rows.
%   summary = SUMMARIZE_ORDER_CANCELLATION_BENCHMARK(results) groups
%   benchmark rows by dataset, scenario, time window, job category,
%   strategy mode, selected strategy, and feasibility. It is a pure summary
%   helper: it does not read files, write outputs, or run scheduling code.

if nargin < 1
    error('summarize_order_cancellation_benchmark:MissingInput', ...
        'results is required.');
end

summary = empty_summary();
if isempty(results)
    return
end

summary.by_dataset = summarize_group(results, 'dataset');
summary.by_scenario = summarize_group(results, 'scenario_id');
summary.by_time_window = summarize_group(results, 'time_window');
summary.by_job_category = summarize_group(results, 'job_category');
summary.by_strategy_mode = summarize_group(results, 'strategy_mode');
summary.by_selected_strategy = summarize_group(results, 'selected_strategy');
summary.by_feasibility = summarize_feasibility(results);
end

function rows = summarize_group(results, fieldName)
values = group_values(results, fieldName);
groupNames = unique(values, 'stable');
rows = repmat(empty_group_summary(fieldName), 1, numel(groupNames));

for i = 1:numel(groupNames)
    rowsInGroup = results(strcmp(values, groupNames{i}));
    row = build_metric_summary(rowsInGroup);
    row.(fieldName) = groupNames{i};
    rows(i) = row;
end
end

function values = group_values(results, fieldName)
values = cell(1, numel(results));
for i = 1:numel(results)
    if isfield(results, fieldName)
        value = results(i).(fieldName);
    else
        value = '';
    end

    if isnumeric(value)
        values{i} = num2str(value);
    else
        values{i} = char(string(value));
    end
end
end

function row = build_metric_summary(rows)
row = empty_metric_summary();
row.run_count = numel(rows);
row.selected_count = sum_logical(rows, 'is_selected');
row.no_feasible_candidate_count = sum_logical(rows, ...
    'no_feasible_candidate');
row.win_rate = safe_ratio(row.selected_count, row.run_count);
row.infeasible_rate = safe_ratio( ...
    row.no_feasible_candidate_count, row.run_count);

metricNames = {'Cmax_delta', 'SD', 'TD', 'energy_delta', 'Y'};
for i = 1:numel(metricNames)
    metricName = metricNames{i};
    row.([metricName, '_mean']) = mean_field(rows, metricName);
    row.([metricName, '_std']) = std_field(rows, metricName);
end
end

function rows = summarize_feasibility(results)
labels = cell(1, numel(results));
for i = 1:numel(results)
    labels{i} = feasibility_label(results(i));
end

groupNames = unique(labels, 'stable');
rows = repmat(empty_feasibility_summary(), 1, numel(groupNames));
for i = 1:numel(groupNames)
    row = empty_feasibility_summary();
    row.feasibility = groupNames{i};
    row.count = sum(strcmp(labels, groupNames{i}));
    row.rate = safe_ratio(row.count, numel(results));
    rows(i) = row;
end
end

function label = feasibility_label(row)
localFeasible = get_logical_field(row, 'local_feasible');
completeFeasible = get_logical_field(row, 'complete_feasible');

if localFeasible && completeFeasible
    label = 'both_candidates_feasible';
elseif localFeasible
    label = 'local_only';
elseif completeFeasible
    label = 'complete_only';
else
    label = 'no_candidate_feasible';
end
end

function value = mean_field(rows, fieldName)
values = numeric_values(rows, fieldName);
if isempty(values)
    value = NaN;
else
    value = mean(values);
end
end

function value = std_field(rows, fieldName)
values = numeric_values(rows, fieldName);
if numel(values) <= 1
    value = 0;
else
    value = std(values);
end
end

function values = numeric_values(rows, fieldName)
values = [];
for i = 1:numel(rows)
    if isfield(rows, fieldName)
        value = rows(i).(fieldName);
        if isnumeric(value) && isscalar(value) && isfinite(value)
            values(end + 1) = value;
        end
    end
end
end

function count = sum_logical(rows, fieldName)
count = 0;
for i = 1:numel(rows)
    count = count + double(get_logical_field(rows(i), fieldName));
end
end

function value = get_logical_field(row, fieldName)
value = false;
if isstruct(row) && isfield(row, fieldName)
    rawValue = row.(fieldName);
    if islogical(rawValue) && isscalar(rawValue)
        value = rawValue;
    elseif isnumeric(rawValue) && isscalar(rawValue)
        value = rawValue ~= 0;
    end
end
end

function value = safe_ratio(numerator, denominator)
if denominator <= 0
    value = 0;
else
    value = numerator / denominator;
end
end

function summary = empty_summary()
summary = struct();
summary.by_dataset = repmat(empty_group_summary('dataset'), 1, 0);
summary.by_scenario = repmat(empty_group_summary('scenario_id'), 1, 0);
summary.by_time_window = repmat(empty_group_summary('time_window'), 1, 0);
summary.by_job_category = repmat(empty_group_summary('job_category'), 1, 0);
summary.by_strategy_mode = repmat(empty_group_summary('strategy_mode'), 1, 0);
summary.by_selected_strategy = repmat( ...
    empty_group_summary('selected_strategy'), 1, 0);
summary.by_feasibility = repmat(empty_feasibility_summary(), 1, 0);
end

function row = empty_group_summary(fieldName)
row = empty_metric_summary();
row.(fieldName) = '';
end

function row = empty_metric_summary()
row = struct();
row.run_count = 0;
row.selected_count = 0;
row.no_feasible_candidate_count = 0;
row.win_rate = 0;
row.infeasible_rate = 0;
row.Cmax_delta_mean = NaN;
row.Cmax_delta_std = NaN;
row.SD_mean = NaN;
row.SD_std = NaN;
row.TD_mean = NaN;
row.TD_std = NaN;
row.energy_delta_mean = NaN;
row.energy_delta_std = NaN;
row.Y_mean = NaN;
row.Y_std = NaN;
end

function row = empty_feasibility_summary()
row = struct();
row.feasibility = '';
row.count = 0;
row.rate = 0;
end
