function summary = summarize_order_cancellation_library_results(results)
%SUMMARIZE_ORDER_CANCELLATION_LIBRARY_RESULTS Aggregate stage-G rows.
%   summary = SUMMARIZE_ORDER_CANCELLATION_LIBRARY_RESULTS(results)
%   aggregates scenario-library experiment rows by dataset, time window, job
%   category, seed, selected strategy, and feasibility. This helper is pure:
%   it does not read files, write outputs, or run scheduling code.

if nargin < 1
    error('summarize_order_cancellation_library_results:MissingInput', ...
        'results is required.');
end

summary = empty_summary();
if isempty(results)
    return
end

summary.by_dataset = summarize_group(results, 'dataset');
summary.by_time_window = summarize_group(results, 'time_window');
summary.by_job_category = summarize_group(results, 'job_category');
summary.by_seed = summarize_numeric_group(results, 'seed');
summary.by_selected_strategy = summarize_strategy(results);
summary.by_feasibility = summarize_feasibility(results);
end

function rows = summarize_group(results, fieldName)
values = {results.(fieldName)};
groupNames = unique(values, 'stable');
rows = repmat(empty_group_summary(fieldName), 1, numel(groupNames));

for i = 1:numel(groupNames)
    rowsInGroup = results(strcmp(values, groupNames{i}));
    row = build_group_summary(rowsInGroup);
    row.(fieldName) = groupNames{i};
    rows(i) = row;
end
end

function rows = summarize_numeric_group(results, fieldName)
values = [results.(fieldName)];
groupValues = unique(values, 'stable');
rows = repmat(empty_group_summary(fieldName), 1, numel(groupValues));

for i = 1:numel(groupValues)
    rowsInGroup = results(values == groupValues(i));
    row = build_group_summary(rowsInGroup);
    row.(fieldName) = groupValues(i);
    rows(i) = row;
end
end

function row = build_group_summary(rows)
row = empty_metric_summary();
row.run_count = numel(rows);
row.local_feasible_count = sum([rows.local_isFeasible]);
row.complete_feasible_count = sum([rows.complete_isFeasible]);
row.no_feasible_candidate_count = count_no_feasible(rows);
row.local_Cmax_delta_mean = mean_numeric_field(rows, 'local_Cmax_delta');
row.complete_Cmax_delta_mean = mean_numeric_field( ...
    rows, 'complete_Cmax_delta');
row.local_SD_mean = mean_numeric_field(rows, 'local_SD');
row.complete_SD_mean = mean_numeric_field(rows, 'complete_SD');
row.local_TD_mean = mean_numeric_field(rows, 'local_TD');
row.complete_TD_mean = mean_numeric_field(rows, 'complete_TD');
row.local_energy_delta_mean = mean_numeric_field( ...
    rows, 'local_energy_delta');
row.complete_energy_delta_mean = mean_numeric_field( ...
    rows, 'complete_energy_delta');
row.local_Y_mean = mean_numeric_field(rows, 'local_Y');
row.complete_Y_mean = mean_numeric_field(rows, 'complete_Y');
row.selected_local_repair_count = sum(strcmp( ...
    {rows.selected_strategy}, 'local_repair'));
row.selected_complete_rescheduling_count = sum(strcmp( ...
    {rows.selected_strategy}, 'complete_rescheduling'));
row.selected_strategy_count = sum(~cellfun('isempty', ...
    {rows.selected_strategy}));
end

function rows = summarize_strategy(results)
labels = cell(1, numel(results));
for i = 1:numel(results)
    labels{i} = strategy_label(results(i));
end

strategyNames = unique(labels, 'stable');
rows = repmat(empty_strategy_summary(), 1, numel(strategyNames));
for i = 1:numel(strategyNames)
    row = empty_strategy_summary();
    row.selected_strategy = strategyNames{i};
    row.count = sum(strcmp(labels, strategyNames{i}));
    rows(i) = row;
end
end

function rows = summarize_feasibility(results)
labels = cell(1, numel(results));
for i = 1:numel(results)
    labels{i} = feasibility_label(results(i));
end

feasibilityNames = unique(labels, 'stable');
rows = repmat(empty_feasibility_summary(), 1, numel(feasibilityNames));
for i = 1:numel(feasibilityNames)
    row = empty_feasibility_summary();
    row.feasibility = feasibilityNames{i};
    row.count = sum(strcmp(labels, feasibilityNames{i}));
    rows(i) = row;
end
end

function count = count_no_feasible(rows)
if isfield(rows, 'selected_reason')
    count = sum(strcmp({rows.selected_reason}, 'no_feasible_candidate'));
else
    count = sum(~[rows.local_isFeasible] & ~[rows.complete_isFeasible]);
end
end

function label = strategy_label(row)
if isfield(row, 'selected_strategy') && ~isempty(row.selected_strategy)
    label = row.selected_strategy;
elseif isfield(row, 'selected_reason') && ~isempty(row.selected_reason)
    label = row.selected_reason;
else
    label = 'no_selection';
end
end

function label = feasibility_label(row)
if row.local_isFeasible && row.complete_isFeasible
    label = 'both_feasible';
elseif row.local_isFeasible
    label = 'local_only';
elseif row.complete_isFeasible
    label = 'complete_only';
else
    label = 'none_feasible';
end
end

function value = mean_numeric_field(rows, fieldName)
values = [rows.(fieldName)];
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = mean(values);
end
end

function summary = empty_summary()
summary = struct();
summary.by_dataset = repmat(empty_group_summary('dataset'), 1, 0);
summary.by_time_window = repmat(empty_group_summary('time_window'), 1, 0);
summary.by_job_category = repmat(empty_group_summary('job_category'), 1, 0);
summary.by_seed = repmat(empty_group_summary('seed'), 1, 0);
summary.by_selected_strategy = repmat(empty_strategy_summary(), 1, 0);
summary.by_feasibility = repmat(empty_feasibility_summary(), 1, 0);
end

function row = empty_group_summary(fieldName)
row = empty_metric_summary();
row.(fieldName) = [];
end

function row = empty_metric_summary()
row = struct();
row.run_count = 0;
row.local_feasible_count = 0;
row.complete_feasible_count = 0;
row.no_feasible_candidate_count = 0;
row.local_Cmax_delta_mean = NaN;
row.complete_Cmax_delta_mean = NaN;
row.local_SD_mean = NaN;
row.complete_SD_mean = NaN;
row.local_TD_mean = NaN;
row.complete_TD_mean = NaN;
row.local_energy_delta_mean = NaN;
row.complete_energy_delta_mean = NaN;
row.local_Y_mean = NaN;
row.complete_Y_mean = NaN;
row.selected_local_repair_count = 0;
row.selected_complete_rescheduling_count = 0;
row.selected_strategy_count = 0;
end

function row = empty_strategy_summary()
row = struct();
row.selected_strategy = '';
row.count = 0;
end

function row = empty_feasibility_summary()
row = struct();
row.feasibility = '';
row.count = 0;
end
