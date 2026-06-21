function summary = summarize_order_cancellation_results(results)
%SUMMARIZE_ORDER_CANCELLATION_RESULTS Aggregate stage-F result rows.
%   summary = SUMMARIZE_ORDER_CANCELLATION_RESULTS(results) returns
%   per-scenario averages and selected-strategy counts. It is a pure helper:
%   it does not read files, write outputs, or run scheduling code.

if nargin < 1
    error('summarize_order_cancellation_results:MissingInput', ...
        'results is required.');
end
if isempty(results)
    summary = empty_summary();
    return
end

summary = empty_summary();
scenarioNames = unique({results.scenario_name}, 'stable');
summary.scenarios = repmat(empty_scenario_summary(), ...
    1, numel(scenarioNames));

for i = 1:numel(scenarioNames)
    scenarioName = scenarioNames{i};
    rows = results(strcmp({results.scenario_name}, scenarioName));
    row = empty_scenario_summary();
    row.scenario_name = scenarioName;
    row.run_count = numel(rows);
    row.local_feasible_count = sum([rows.local_isFeasible]);
    row.complete_feasible_count = sum([rows.complete_isFeasible]);
    row.local_Cmax_delta_mean = mean_numeric_field( ...
        rows, 'local_Cmax_delta');
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
    summary.scenarios(i) = row;
end

strategyNames = unique({results.selected_strategy}, 'stable');
summary.strategy_counts = repmat(empty_strategy_count(), ...
    1, numel(strategyNames));
for i = 1:numel(strategyNames)
    strategyName = strategyNames{i};
    row = empty_strategy_count();
    row.selected_strategy = strategyName;
    row.count = sum(strcmp({results.selected_strategy}, strategyName));
    summary.strategy_counts(i) = row;
end
end

function summary = empty_summary()
summary = struct();
summary.scenarios = repmat(empty_scenario_summary(), 1, 0);
summary.strategy_counts = repmat(empty_strategy_count(), 1, 0);
end

function row = empty_scenario_summary()
row = struct();
row.scenario_name = '';
row.run_count = 0;
row.local_feasible_count = 0;
row.complete_feasible_count = 0;
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
end

function row = empty_strategy_count()
row = struct();
row.selected_strategy = '';
row.count = 0;
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
