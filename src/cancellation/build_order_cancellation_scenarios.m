function [scenarios, summary] = build_order_cancellation_scenarios( ...
    problem, baselineSchedule, config)
%BUILD_ORDER_CANCELLATION_SCENARIOS Build reproducible cancellation scenarios.
%   [scenarios, summary] = BUILD_ORDER_CANCELLATION_SCENARIOS(problem,
%   baselineSchedule, config) creates stage-G cancellation scenarios from
%   config. This function is pure: it does not read files, write outputs, run
%   scheduling experiments, or call NSGA-II.

if nargin < 3
    error('build_order_cancellation_scenarios:MissingInput', ...
        'problem, baselineSchedule, and config are required.');
end

require_problem(problem);
require_baseline_schedule(baselineSchedule);

config = apply_default_config(config);
[baselineMetrics, baselineReport] = evaluate_candidate_cmax( ...
    baselineSchedule, baselineSchedule);
if ~baselineMetrics.isFeasible
    error('build_order_cancellation_scenarios:InvalidBaselineCmax', ...
        strjoin(baselineReport.errors, newline));
end

datasets = normalize_text_list(config.datasets);
timeWindows = normalize_time_windows(config.time_windows);
jobCategories = normalize_text_list(config.job_categories);
seeds = config.seeds;
policy = config.cancel_policy;
baselineCmax = baselineMetrics.Cmax;

scenarios = repmat(empty_scenario(), 1, 0);
skipped = repmat(empty_skipped_scenario(), 1, 0);

for datasetIdx = 1:numel(datasets)
    dataset = datasets{datasetIdx};
    for timeIdx = 1:numel(timeWindows)
        timeWindow = timeWindows(timeIdx);
        cancelTime = baselineCmax * timeWindow.cancel_time_ratio;
        for categoryIdx = 1:numel(jobCategories)
            jobCategory = jobCategories{categoryIdx};
            for seedIdx = 1:numel(seeds)
                seed = seeds(seedIdx);
                [jobId, notes, isSkipped] = select_job_id( ...
                    problem, baselineSchedule, jobCategory, seed);
                if isSkipped
                    skipped(end + 1) = make_skipped_scenario( ...
                        dataset, timeWindow.name, jobCategory, seed, notes);
                    continue
                end

                scenario = empty_scenario();
                scenario.scenario_id = make_scenario_id( ...
                    dataset, timeWindow.name, jobCategory, seed);
                scenario.dataset = dataset;
                scenario.seed = seed;
                scenario.time_window = timeWindow.name;
                scenario.job_category = jobCategory;
                scenario.cancel.job_id = jobId;
                scenario.cancel.cancel_time = cancelTime;
                scenario.cancel.policy = policy;
                scenario.cancel_time_ratio = timeWindow.cancel_time_ratio;
                scenario.notes = notes;
                scenarios(end + 1) = scenario;
            end
        end
    end
end

summary = build_summary(scenarios, skipped, datasets, timeWindows, ...
    jobCategories, seeds, policy, baselineCmax);
end

function require_problem(problem)
requiredFields = {'jobNum'};
for i = 1:numel(requiredFields)
    if ~isstruct(problem) || ~isfield(problem, requiredFields{i})
        error('build_order_cancellation_scenarios:InvalidProblem', ...
            'problem.%s is required.', requiredFields{i});
    end
end
if ~isnumeric(problem.jobNum) || ~isscalar(problem.jobNum) || ...
        problem.jobNum < 1
    error('build_order_cancellation_scenarios:InvalidProblem', ...
        'problem.jobNum must be a positive scalar.');
end
end

function require_baseline_schedule(baselineSchedule)
if ~isstruct(baselineSchedule) || ~isfield(baselineSchedule, ...
        'machineTable')
    error('build_order_cancellation_scenarios:InvalidBaselineSchedule', ...
        'baselineSchedule.machineTable is required.');
end
end

function config = apply_default_config(config)
if ~isstruct(config)
    error('build_order_cancellation_scenarios:InvalidConfig', ...
        'config must be a struct.');
end
if ~isfield(config, 'datasets') || isempty(config.datasets)
    config.datasets = {'data_sample/Mk01.fjs'};
end
if ~isfield(config, 'cancel_policy') || isempty(config.cancel_policy)
    config.cancel_policy = 'cancel_unstarted_operations_only';
end
if ~isfield(config, 'time_windows') || isempty(config.time_windows)
    config.time_windows = default_time_windows();
end
if ~isfield(config, 'job_categories') || isempty(config.job_categories)
    config.job_categories = {'random', 'short', 'long', ...
        'critical', 'noncritical'};
end
if ~isfield(config, 'seeds') || isempty(config.seeds)
    config.seeds = [1, 2, 3];
end
end

function timeWindows = default_time_windows()
timeWindows = repmat(empty_time_window(), 1, 3);
timeWindows(1).name = 'early';
timeWindows(1).cancel_time_ratio = 0.25;
timeWindows(2).name = 'middle';
timeWindows(2).cancel_time_ratio = 0.50;
timeWindows(3).name = 'late';
timeWindows(3).cancel_time_ratio = 0.75;
end

function items = normalize_text_list(value)
if ischar(value)
    items = {value};
elseif isstring(value)
    items = cellstr(value);
elseif iscell(value)
    items = value;
else
    error('build_order_cancellation_scenarios:InvalidTextList', ...
        'Text list config values must be char, string, or cell.');
end

for i = 1:numel(items)
    items{i} = char(strtrim(string(items{i})));
end
end

function timeWindows = normalize_time_windows(value)
if ~isstruct(value)
    error('build_order_cancellation_scenarios:InvalidTimeWindows', ...
        'config.time_windows must be a struct array.');
end

timeWindows = repmat(empty_time_window(), 1, numel(value));
for i = 1:numel(value)
    if ~isfield(value(i), 'name') || ~isfield(value(i), ...
            'cancel_time_ratio')
        error('build_order_cancellation_scenarios:InvalidTimeWindows', ...
            'Each time window requires name and cancel_time_ratio.');
    end
    timeWindows(i).name = char(strtrim(string(value(i).name)));
    timeWindows(i).cancel_time_ratio = value(i).cancel_time_ratio;
    if ~isnumeric(timeWindows(i).cancel_time_ratio) || ...
            ~isscalar(timeWindows(i).cancel_time_ratio) || ...
            timeWindows(i).cancel_time_ratio < 0
        error('build_order_cancellation_scenarios:InvalidTimeWindows', ...
            'cancel_time_ratio must be a nonnegative scalar.');
    end
end
end

function [jobId, notes, isSkipped] = select_job_id( ...
    problem, baselineSchedule, jobCategory, seed)
notes = {};
isSkipped = false;
jobId = [];

switch jobCategory
    case 'random'
        jobId = select_random_job(problem, seed);
        notes{end + 1} = sprintf('random job selected with seed %d.', seed);
    case 'short'
        jobId = select_by_operation_count(problem, 'short');
        notes{end + 1} = 'short job selected by minimum operation count.';
    case 'long'
        jobId = select_by_operation_count(problem, 'long');
        notes{end + 1} = 'long job selected by maximum operation count.';
    case 'critical'
        [jobId, isSkipped, notes] = select_by_completion_time( ...
            problem, baselineSchedule, 'critical');
    case 'noncritical'
        [jobId, isSkipped, notes] = select_by_completion_time( ...
            problem, baselineSchedule, 'noncritical');
    otherwise
        isSkipped = true;
        notes{end + 1} = sprintf('Unsupported job category: %s.', ...
            jobCategory);
end

if ~isSkipped
    require_job_id(problem, jobId, jobCategory);
end
end

function jobId = select_random_job(problem, seed)
previousRng = rng;
rng(seed);
jobId = randi(problem.jobNum);
rng(previousRng);
end

function jobId = select_by_operation_count(problem, mode)
operationCounts = get_operation_counts(problem);
switch mode
    case 'short'
        targetCount = min(operationCounts);
    case 'long'
        targetCount = max(operationCounts);
    otherwise
        error('build_order_cancellation_scenarios:InvalidLengthMode', ...
            'Unsupported length mode.');
end
jobId = find(operationCounts == targetCount, 1, 'first');
end

function operationCounts = get_operation_counts(problem)
if isfield(problem, 'operaNumVec') && numel(problem.operaNumVec) >= ...
        problem.jobNum
    operationCounts = problem.operaNumVec(1:problem.jobNum);
elseif isfield(problem, 'jobInfo') && numel(problem.jobInfo) >= ...
        problem.jobNum
    operationCounts = zeros(1, problem.jobNum);
    for jobIdx = 1:problem.jobNum
        operationCounts(jobIdx) = size(problem.jobInfo{jobIdx}, 1);
    end
else
    error('build_order_cancellation_scenarios:MissingOperationCounts', ...
        'problem.operaNumVec or problem.jobInfo is required for short/long.');
end
end

function [jobId, isSkipped, notes] = select_by_completion_time( ...
    problem, baselineSchedule, mode)
notes = {};
isSkipped = false;
jobCompletionTimes = collect_job_completion_times(problem, baselineSchedule);

validJobIds = find(isfinite(jobCompletionTimes));
if isempty(validJobIds)
    jobId = [];
    isSkipped = true;
    notes{end + 1} = sprintf( ...
        '%s job skipped: no stable job completion times in baseline.', ...
        mode);
    return
end

switch mode
    case 'critical'
        targetTime = max(jobCompletionTimes(validJobIds));
        jobId = find(jobCompletionTimes == targetTime, 1, 'first');
        notes{end + 1} = ...
            'critical job selected by latest baseline completion time.';
    case 'noncritical'
        targetTime = min(jobCompletionTimes(validJobIds));
        jobId = find(jobCompletionTimes == targetTime, 1, 'first');
        notes{end + 1} = ...
            'noncritical job selected by earliest baseline completion time.';
    otherwise
        error('build_order_cancellation_scenarios:InvalidCompletionMode', ...
            'Unsupported completion mode.');
end
end

function completionTimes = collect_job_completion_times(problem, schedule)
completionTimes = ones(1, problem.jobNum) * NaN;
machineTable = schedule.machineTable;
if ~iscell(machineTable)
    return
end

for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    if isempty(blocks) || ~isstruct(blocks) || ...
            ~all(isfield(blocks, {'job', 'end'}))
        continue
    end
    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job <= 0 || block.job > problem.jobNum || ...
                isempty(block.end) || ~isnumeric(block.end) || ...
                ~isscalar(block.end) || ~isfinite(block.end)
            continue
        end
        if isnan(completionTimes(block.job))
            completionTimes(block.job) = block.end;
        else
            completionTimes(block.job) = max( ...
                completionTimes(block.job), block.end);
        end
    end
end
end

function require_job_id(problem, jobId, jobCategory)
if isempty(jobId) || ~isnumeric(jobId) || ~isscalar(jobId) || ...
        jobId < 1 || jobId > problem.jobNum
    error('build_order_cancellation_scenarios:InvalidJobId', ...
        'Generated job_id for category %s is out of range.', jobCategory);
end
end

function scenarioId = make_scenario_id(dataset, timeWindow, jobCategory, seed)
[~, datasetStem] = fileparts(strrep(dataset, '\', filesep));
datasetStem = sanitize_id_part(datasetStem);
scenarioId = sprintf('%s__%s__%s__seed%d', datasetStem, ...
    sanitize_id_part(timeWindow), sanitize_id_part(jobCategory), seed);
end

function value = sanitize_id_part(value)
value = char(strtrim(string(value)));
value = regexprep(value, '[^A-Za-z0-9_]+', '_');
value = regexprep(value, '_+', '_');
value = regexprep(value, '^_|_$', '');
if isempty(value)
    value = 'unknown';
end
end

function summary = build_summary(scenarios, skipped, datasets, ...
    timeWindows, jobCategories, seeds, policy, baselineCmax)
summary = struct();
summary.total_count = numel(scenarios);
summary.skipped_count = numel(skipped);
summary.dataset_count = numel(datasets);
summary.time_window_count = numel(timeWindows);
summary.job_category_count = numel(jobCategories);
summary.seed_count = numel(seeds);
summary.cancel_policy = policy;
summary.baseline_Cmax = baselineCmax;
summary.by_dataset = count_by_values({scenarios.dataset}, datasets, ...
    'dataset');
summary.by_time_window = count_by_values({scenarios.time_window}, ...
    {timeWindows.name}, 'time_window');
summary.by_job_category = count_by_values({scenarios.job_category}, ...
    jobCategories, 'job_category');
summary.by_seed = count_by_numeric_values([scenarios.seed], seeds, 'seed');
summary.skipped = skipped;
end

function rows = count_by_values(values, expectedValues, fieldName)
rows = repmat(empty_count_row(fieldName), 1, numel(expectedValues));
for i = 1:numel(expectedValues)
    rows(i).(fieldName) = expectedValues{i};
    rows(i).count = sum(strcmp(values, expectedValues{i}));
end
end

function rows = count_by_numeric_values(values, expectedValues, fieldName)
rows = repmat(empty_count_row(fieldName), 1, numel(expectedValues));
for i = 1:numel(expectedValues)
    rows(i).(fieldName) = expectedValues(i);
    rows(i).count = sum(values == expectedValues(i));
end
end

function row = empty_count_row(fieldName)
row = struct();
row.(fieldName) = [];
row.count = 0;
end

function scenario = empty_scenario()
scenario = struct();
scenario.scenario_id = '';
scenario.dataset = '';
scenario.seed = NaN;
scenario.time_window = '';
scenario.job_category = '';
scenario.cancel = struct();
scenario.cancel.job_id = NaN;
scenario.cancel.cancel_time = NaN;
scenario.cancel.policy = '';
scenario.cancel_time_ratio = NaN;
scenario.notes = {};
end

function skipped = empty_skipped_scenario()
skipped = struct();
skipped.dataset = '';
skipped.time_window = '';
skipped.job_category = '';
skipped.seed = NaN;
skipped.notes = {};
end

function skipped = make_skipped_scenario(dataset, timeWindow, jobCategory, ...
    seed, notes)
skipped = empty_skipped_scenario();
skipped.dataset = dataset;
skipped.time_window = timeWindow;
skipped.job_category = jobCategory;
skipped.seed = seed;
skipped.notes = notes;
end

function timeWindow = empty_time_window()
timeWindow = struct();
timeWindow.name = '';
timeWindow.cancel_time_ratio = NaN;
end
