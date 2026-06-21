clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = make_problem();
baselineSchedule = make_baseline_schedule();
config = make_config();

[scenarios, summary] = build_order_cancellation_scenarios( ...
    problem, baselineSchedule, config);
[scenariosAgain, summaryAgain] = build_order_cancellation_scenarios( ...
    problem, baselineSchedule, config);

expectedCount = numel(config.datasets) * numel(config.time_windows) * ...
    numel(config.job_categories) * numel(config.seeds);

assert(numel(scenarios) == expectedCount, ...
    'Scenario count should match dataset*time_window*job_category*seed.');
assert(summary.total_count == expectedCount, ...
    'summary.total_count should match scenario count.');
assert(summary.skipped_count == 0, ...
    'No scenario should be skipped for the constructed baseline.');
assert(summaryAgain.total_count == summary.total_count, ...
    'Repeated scenario generation should have the same count.');

assert_unique_scenario_ids(scenarios);
assert_all_cancel_fields(scenarios, problem);
assert_summary_counts(summary, config);
assert_random_jobs_reproducible(scenarios, scenariosAgain);
assert_job_categories(scenarios);

fprintf('test_order_cancellation_scenario_library passed\n');

function problem = make_problem()
problem = struct();
problem.jobNum = 3;
problem.machineNum = 2;
problem.operaNumVec = [1, 3, 2];
problem.jobInfo = {
    zeros(1, 2)
    zeros(3, 2)
    zeros(2, 2)
};
end

function schedule = make_baseline_schedule()
schedule = struct();
schedule.machineTable = cell(1, 2);
schedule.machineTable{1} = [
    make_machine_block(0, 5, 1, 1)
    make_machine_block(5, 9, 2, 3)
];
schedule.machineTable{2} = [
    make_machine_block(0, 3, 3, 2)
    make_machine_block(3, 7, 2, 2)
];
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end

function config = make_config()
config = struct();
config.datasets = {'data_sample/Mk01.fjs'};
config.cancel_policy = 'cancel_unstarted_operations_only';
config.time_windows = repmat(struct('name', '', ...
    'cancel_time_ratio', NaN), 1, 3);
config.time_windows(1).name = 'early';
config.time_windows(1).cancel_time_ratio = 0.25;
config.time_windows(2).name = 'middle';
config.time_windows(2).cancel_time_ratio = 0.50;
config.time_windows(3).name = 'late';
config.time_windows(3).cancel_time_ratio = 0.75;
config.job_categories = {'random', 'short', 'long', ...
    'critical', 'noncritical'};
config.seeds = [1, 2];
config.output_base_dir = 'outputs/order_cancellation_scenario_library';
end

function assert_unique_scenario_ids(scenarios)
scenarioIds = {scenarios.scenario_id};
assert(numel(unique(scenarioIds)) == numel(scenarioIds), ...
    'Each scenario_id should be unique.');
for i = 1:numel(scenarioIds)
    assert(~isempty(scenarioIds{i}), ...
        'scenario_id should not be empty.');
end
end

function assert_all_cancel_fields(scenarios, problem)
for i = 1:numel(scenarios)
    scenario = scenarios(i);
    assert(isfield(scenario, 'cancel'), ...
        'scenario.cancel is required.');
    assert(isfield(scenario.cancel, 'job_id'), ...
        'scenario.cancel.job_id is required.');
    assert(isfield(scenario.cancel, 'cancel_time'), ...
        'scenario.cancel.cancel_time is required.');
    assert(isfield(scenario.cancel, 'policy'), ...
        'scenario.cancel.policy is required.');
    assert(scenario.cancel.job_id >= 1 && ...
        scenario.cancel.job_id <= problem.jobNum, ...
        'scenario.cancel.job_id should be in range.');
    assert(scenario.cancel.cancel_time >= 0, ...
        'scenario.cancel.cancel_time should be nonnegative.');
    assert(strcmp(scenario.cancel.policy, ...
        'cancel_unstarted_operations_only'), ...
        'scenario.cancel.policy mismatch.');
    assert(~isempty(scenario.dataset), ...
        'scenario.dataset should be traceable.');
    assert(~isempty(scenario.time_window), ...
        'scenario.time_window should be traceable.');
    assert(~isempty(scenario.job_category), ...
        'scenario.job_category should be traceable.');
    assert(isfinite(scenario.seed), ...
        'scenario.seed should be traceable.');
end
end

function assert_summary_counts(summary, config)
assert(numel(summary.by_dataset) == numel(config.datasets), ...
    'summary.by_dataset count mismatch.');
assert(summary.by_dataset(1).count == summary.total_count, ...
    'Dataset count should equal total count for one dataset.');

expectedPerTimeWindow = numel(config.job_categories) * ...
    numel(config.seeds);
for i = 1:numel(summary.by_time_window)
    assert(summary.by_time_window(i).count == expectedPerTimeWindow, ...
        'Each time window should have the expected scenario count.');
end

expectedPerCategory = numel(config.time_windows) * numel(config.seeds);
for i = 1:numel(summary.by_job_category)
    assert(summary.by_job_category(i).count == expectedPerCategory, ...
        'Each job category should have the expected scenario count.');
end

expectedPerSeed = numel(config.time_windows) * ...
    numel(config.job_categories);
for i = 1:numel(summary.by_seed)
    assert(summary.by_seed(i).count == expectedPerSeed, ...
        'Each seed should have the expected scenario count.');
end
end

function assert_random_jobs_reproducible(scenarios, scenariosAgain)
randomRows = scenarios(strcmp({scenarios.job_category}, 'random'));
randomRowsAgain = scenariosAgain(strcmp({scenariosAgain.job_category}, ...
    'random'));

assert(numel(randomRows) == numel(randomRowsAgain), ...
    'Repeated random scenario count mismatch.');
for i = 1:numel(randomRows)
    assert(randomRows(i).cancel.job_id == ...
        randomRowsAgain(i).cancel.job_id, ...
        'Random job selection should be reproducible for the same seed.');
end
end

function assert_job_categories(scenarios)
shortRows = scenarios(strcmp({scenarios.job_category}, 'short'));
longRows = scenarios(strcmp({scenarios.job_category}, 'long'));
criticalRows = scenarios(strcmp({scenarios.job_category}, 'critical'));
noncriticalRows = scenarios(strcmp({scenarios.job_category}, ...
    'noncritical'));

assert(all([shortRows.cancel].job_id == 1), ...
    'short category should select the fewest-operation job.');
assert(all([longRows.cancel].job_id == 2), ...
    'long category should select the most-operation job.');
assert(all([criticalRows.cancel].job_id == 2), ...
    'critical category should select the latest-completing job.');
assert(all([noncriticalRows.cancel].job_id == 3), ...
    'noncritical category should select the earliest-completing job.');
end
