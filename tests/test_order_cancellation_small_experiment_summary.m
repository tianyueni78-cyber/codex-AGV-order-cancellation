clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

results = make_results();
summary = summarize_order_cancellation_results(results);

assert(numel(summary.scenarios) == 3, ...
    'Three scenarios should be recognized.');
assert(numel(unique([results.seed])) == 2, ...
    'Constructed test data should contain multiple seeds.');

early = find_scenario(summary.scenarios, 'early_cancel');
middle = find_scenario(summary.scenarios, 'middle_cancel');
late = find_scenario(summary.scenarios, 'late_cancel');

assert(early.run_count == 2, ...
    'early_cancel should aggregate two seed rows.');
assert(early.local_feasible_count == 2, ...
    'early_cancel local feasible count mismatch.');
assert(early.complete_feasible_count == 1, ...
    'early_cancel complete feasible count mismatch.');
assert(abs(early.local_Cmax_delta_mean - 1.5) < 1e-9, ...
    'early_cancel local Cmax_delta mean mismatch.');
assert(abs(early.complete_Cmax_delta_mean - 0.5) < 1e-9, ...
    'early_cancel complete Cmax_delta mean mismatch.');
assert(early.selected_local_repair_count == 1, ...
    'early_cancel selected local repair count mismatch.');
assert(early.selected_complete_rescheduling_count == 1, ...
    'early_cancel selected complete rescheduling count mismatch.');

assert(middle.run_count == 2, ...
    'middle_cancel should aggregate two seed rows.');
assert(abs(middle.local_Y_mean - 0.45) < 1e-9, ...
    'middle_cancel local Y mean mismatch.');
assert(abs(middle.complete_Y_mean - 0.55) < 1e-9, ...
    'middle_cancel complete Y mean mismatch.');

assert(late.run_count == 2, ...
    'late_cancel should aggregate two seed rows.');
assert(late.complete_feasible_count == 2, ...
    'late_cancel complete feasible count mismatch.');

localCount = find_strategy_count(summary.strategy_counts, 'local_repair');
completeCount = find_strategy_count( ...
    summary.strategy_counts, 'complete_rescheduling');
assert(localCount == 3, ...
    'Selected local repair count mismatch.');
assert(completeCount == 3, ...
    'Selected complete rescheduling count mismatch.');

fprintf('test_order_cancellation_small_experiment_summary passed\n');

function results = make_results()
rows = {
    make_row('early_cancel', 1, true, true, 1, 0, 2, 4, 0.4, 0.6, ...
        'local_repair')
    make_row('early_cancel', 2, true, false, 2, 1, 4, 6, 0.6, 0.3, ...
        'complete_rescheduling')
    make_row('middle_cancel', 1, true, true, 3, 2, 6, 8, 0.5, 0.7, ...
        'local_repair')
    make_row('middle_cancel', 2, false, true, 5, 4, 8, 10, 0.4, 0.4, ...
        'complete_rescheduling')
    make_row('late_cancel', 1, true, true, 0, -1, 1, 2, 0.2, 0.1, ...
        'complete_rescheduling')
    make_row('late_cancel', 2, true, true, 0, -2, 1, 3, 0.3, 0.2, ...
        'local_repair')
};

results = [rows{:}];
end

function row = make_row(scenarioName, seed, localFeasible, completeFeasible, ...
    localCmaxDelta, completeCmaxDelta, localSd, completeSd, localY, ...
    completeY, selectedStrategy)
row = struct();
row.scenario_name = scenarioName;
row.seed = seed;
row.local_isFeasible = localFeasible;
row.complete_isFeasible = completeFeasible;
row.local_Cmax_delta = localCmaxDelta;
row.complete_Cmax_delta = completeCmaxDelta;
row.local_SD = localSd;
row.complete_SD = completeSd;
row.local_TD = 0;
row.complete_TD = 0;
row.local_energy_delta = -1;
row.complete_energy_delta = -2;
row.local_Y = localY;
row.complete_Y = completeY;
row.selected_strategy = selectedStrategy;
end

function scenario = find_scenario(scenarios, scenarioName)
scenario = [];
for i = 1:numel(scenarios)
    if strcmp(scenarios(i).scenario_name, scenarioName)
        scenario = scenarios(i);
        return
    end
end
error('test_order_cancellation_small_experiment_summary:MissingScenario', ...
    'Scenario not found: %s', scenarioName);
end

function count = find_strategy_count(strategyCounts, strategyName)
count = 0;
for i = 1:numel(strategyCounts)
    if strcmp(strategyCounts(i).selected_strategy, strategyName)
        count = strategyCounts(i).count;
        return
    end
end
end
