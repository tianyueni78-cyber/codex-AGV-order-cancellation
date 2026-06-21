clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

results = make_results();
summary = summarize_order_cancellation_library_results(results);

assert(numel(summary.by_time_window) == 2, ...
    'Two time windows should be summarized.');
assert(numel(summary.by_job_category) == 2, ...
    'Two job categories should be summarized.');
assert(numel(summary.by_seed) == 2, ...
    'Two seeds should be summarized.');

early = find_group(summary.by_time_window, 'time_window', 'early');
middle = find_group(summary.by_time_window, 'time_window', 'middle');
short = find_group(summary.by_job_category, 'job_category', 'short');
long = find_group(summary.by_job_category, 'job_category', 'long');

assert(early.run_count == 3, ...
    'early time window should aggregate three rows.');
assert(early.local_feasible_count == 2, ...
    'early local feasible count mismatch.');
assert(early.complete_feasible_count == 1, ...
    'early complete feasible count mismatch.');
assert(early.no_feasible_candidate_count == 1, ...
    'early no feasible candidate count mismatch.');
assert(abs(early.local_Cmax_delta_mean - 1.5) < 1e-9, ...
    'early local Cmax_delta mean mismatch.');
assert(abs(early.complete_Y_mean - 0.6) < 1e-9, ...
    'early complete Y mean mismatch.');

assert(middle.run_count == 3, ...
    'middle time window should aggregate three rows.');
assert(middle.selected_complete_rescheduling_count == 2, ...
    'middle complete rescheduling selected count mismatch.');

assert(short.run_count == 3, ...
    'short category should aggregate three rows.');
assert(short.selected_local_repair_count == 2, ...
    'short selected local repair count mismatch.');
assert(abs(short.complete_energy_delta_mean + 4) < 1e-9, ...
    'short complete energy_delta mean mismatch.');

assert(long.run_count == 3, ...
    'long category should aggregate three rows.');
assert(long.no_feasible_candidate_count == 1, ...
    'long no feasible candidate count mismatch.');

localCount = find_count(summary.by_selected_strategy, ...
    'selected_strategy', 'local_repair');
completeCount = find_count(summary.by_selected_strategy, ...
    'selected_strategy', 'complete_rescheduling');
noneCount = find_count(summary.by_selected_strategy, ...
    'selected_strategy', 'no_feasible_candidate');
assert(localCount == 2, 'local_repair strategy count mismatch.');
assert(completeCount == 3, ...
    'complete_rescheduling strategy count mismatch.');
assert(noneCount == 1, 'no_feasible_candidate count mismatch.');

bothFeasible = find_count(summary.by_feasibility, ...
    'feasibility', 'both_feasible');
localOnly = find_count(summary.by_feasibility, ...
    'feasibility', 'local_only');
completeOnly = find_count(summary.by_feasibility, ...
    'feasibility', 'complete_only');
noneFeasible = find_count(summary.by_feasibility, ...
    'feasibility', 'none_feasible');
assert(bothFeasible == 2, 'both_feasible count mismatch.');
assert(localOnly == 1, 'local_only count mismatch.');
assert(completeOnly == 2, 'complete_only count mismatch.');
assert(noneFeasible == 1, 'none_feasible count mismatch.');

fprintf('test_order_cancellation_scenario_library_experiment_summary passed\n');

function results = make_results()
rows = {
    make_row('data_sample/Mk01.fjs', 'early', 'short', 1, ...
        true, true, 1, 0, 2, 4, -1, -2, 0.4, 0.6, ...
        'local_repair', 'smaller_Y')
    make_row('data_sample/Mk01.fjs', 'early', 'long', 2, ...
        true, false, 2, NaN, 4, NaN, -2, NaN, 0.5, NaN, ...
        'local_repair', 'only_feasible_candidate')
    make_row('data_sample/Mk01.fjs', 'early', 'long', 1, ...
        false, false, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
        '', 'no_feasible_candidate')
    make_row('data_sample/Mk01.fjs', 'middle', 'short', 2, ...
        false, true, NaN, -1, NaN, 3, NaN, -6, NaN, 0.2, ...
        'complete_rescheduling', 'only_feasible_candidate')
    make_row('data_sample/Mk01.fjs', 'middle', 'short', 1, ...
        true, true, 3, -2, 6, 8, -3, -4, 0.7, 0.3, ...
        'complete_rescheduling', 'smaller_Y')
    make_row('data_sample/Mk01.fjs', 'middle', 'long', 2, ...
        false, true, NaN, -3, NaN, 5, NaN, -5, NaN, 0.4, ...
        'complete_rescheduling', 'only_feasible_candidate')
};

results = [rows{:}];
end

function row = make_row(dataset, timeWindow, jobCategory, seed, ...
    localFeasible, completeFeasible, localCmaxDelta, completeCmaxDelta, ...
    localSd, completeSd, localEnergyDelta, completeEnergyDelta, ...
    localY, completeY, selectedStrategy, selectedReason)
row = struct();
row.dataset = dataset;
row.time_window = timeWindow;
row.job_category = jobCategory;
row.seed = seed;
row.local_isFeasible = localFeasible;
row.complete_isFeasible = completeFeasible;
row.local_Cmax_delta = localCmaxDelta;
row.complete_Cmax_delta = completeCmaxDelta;
row.local_SD = localSd;
row.complete_SD = completeSd;
row.local_TD = 0;
row.complete_TD = 0;
row.local_energy_delta = localEnergyDelta;
row.complete_energy_delta = completeEnergyDelta;
row.local_Y = localY;
row.complete_Y = completeY;
row.selected_strategy = selectedStrategy;
row.selected_reason = selectedReason;
end

function row = find_group(rows, fieldName, value)
row = [];
for i = 1:numel(rows)
    if strcmp(rows(i).(fieldName), value)
        row = rows(i);
        return
    end
end
error('test_order_cancellation_scenario_library_experiment_summary:MissingGroup', ...
    'Group not found: %s', value);
end

function count = find_count(rows, fieldName, value)
count = 0;
for i = 1:numel(rows)
    if strcmp(rows(i).(fieldName), value)
        count = rows(i).count;
        return
    end
end
end
