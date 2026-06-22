clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'cancellation'));

rows = repmat(empty_row(), 1, 4);

rows(1) = make_row('data_sample/Mk01.fjs', 's1', 'early', 'short', ...
    'fixed_weight', 'local_repair', true, false, 1, 2, 3, -4, 0.2);
rows(2) = make_row('data_sample/Mk01.fjs', 's1', 'early', 'short', ...
    'fixed_weight', 'complete_rescheduling', true, false, 3, 4, 5, -6, 0.4);
rows(3) = make_row('data_sample/Mk01.fjs', 's2', 'late', 'long', ...
    'adaptive_weight', 'complete_rescheduling', true, false, 5, 6, 7, -8, 0.6);
rows(4) = make_row('data_sample/Mk01.fjs', 's2', 'late', 'long', ...
    'adaptive_weight', '', false, true, NaN, NaN, NaN, NaN, NaN);
rows(4).local_feasible = false;
rows(4).complete_feasible = false;

summary = summarize_order_cancellation_benchmark(rows);

assert(numel(summary.by_dataset) == 1, 'dataset summary count mismatch.');
dataset = summary.by_dataset(1);
assert(strcmp(dataset.dataset, 'data_sample/Mk01.fjs'), ...
    'dataset name mismatch.');
assert(dataset.run_count == 4, 'dataset run count mismatch.');
assert(abs(dataset.Cmax_delta_mean - 3) < 1e-12, ...
    'dataset Cmax_delta mean mismatch.');
assert(abs(dataset.Cmax_delta_std - 2) < 1e-12, ...
    'dataset Cmax_delta std mismatch.');
assert(abs(dataset.win_rate - 0.75) < 1e-12, ...
    'dataset win rate mismatch.');
assert(abs(dataset.infeasible_rate - 0.25) < 1e-12, ...
    'dataset infeasible rate mismatch.');

fixed = find_group(summary.by_strategy_mode, ...
    'strategy_mode', 'fixed_weight');
assert(fixed.run_count == 2, 'fixed strategy run count mismatch.');
assert(abs(fixed.Y_mean - 0.3) < 1e-12, ...
    'fixed strategy Y mean mismatch.');
assert(abs(fixed.win_rate - 1.0) < 1e-12, ...
    'fixed strategy win rate mismatch.');

adaptive = find_group(summary.by_strategy_mode, ...
    'strategy_mode', 'adaptive_weight');
assert(adaptive.run_count == 2, ...
    'adaptive strategy run count mismatch.');
assert(abs(adaptive.infeasible_rate - 0.5) < 1e-12, ...
    'adaptive strategy infeasible rate mismatch.');

scenario = find_group(summary.by_scenario, 'scenario_id', 's1');
assert(scenario.run_count == 2, 'scenario summary run count mismatch.');
assert(abs(scenario.SD_mean - 3) < 1e-12, ...
    'scenario SD mean mismatch.');

complete = find_group(summary.by_selected_strategy, ...
    'selected_strategy', 'complete_rescheduling');
assert(complete.selected_count == 2, ...
    'selected complete count mismatch.');

assert(numel(summary.by_feasibility) >= 2, ...
    'feasibility summary should contain multiple groups.');

fprintf('test_order_cancellation_benchmark_summary passed\n');

function row = make_row(dataset, scenarioId, timeWindow, jobCategory, ...
    strategyMode, selectedStrategy, isSelected, noFeasible, ...
    cmaxDelta, sd, td, energyDelta, y)
row = empty_row();
row.dataset = dataset;
row.scenario_id = scenarioId;
row.time_window = timeWindow;
row.job_category = jobCategory;
row.seed = 1;
row.strategy_mode = strategyMode;
row.selected_strategy = selectedStrategy;
row.is_selected = isSelected;
row.local_feasible = true;
row.complete_feasible = true;
row.Cmax_delta = cmaxDelta;
row.SD = sd;
row.TD = td;
row.energy_delta = energyDelta;
row.Y = y;
row.constraint_feasible = isSelected;
row.no_feasible_candidate = noFeasible;
row.runtime_seconds = 0.1;
row.error_count = 0;
row.rejected_reason_count = double(noFeasible);
end

function row = empty_row()
row = struct();
row.dataset = '';
row.scenario_id = '';
row.time_window = '';
row.job_category = '';
row.seed = NaN;
row.strategy_mode = '';
row.selected_strategy = '';
row.is_selected = false;
row.local_feasible = false;
row.complete_feasible = false;
row.Cmax_delta = NaN;
row.SD = NaN;
row.TD = NaN;
row.energy_delta = NaN;
row.Y = NaN;
row.constraint_feasible = false;
row.no_feasible_candidate = false;
row.runtime_seconds = NaN;
row.error_count = 0;
row.rejected_reason_count = 0;
end

function row = find_group(rows, fieldName, value)
matches = strcmp({rows.(fieldName)}, value);
assert(any(matches), 'Expected group not found.');
row = rows(find(matches, 1));
end
