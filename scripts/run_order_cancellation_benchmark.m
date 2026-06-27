clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

benchmarkConfigPath = fullfile(projectRoot, 'configs', ...
    'order_cancellation_benchmark.yaml');
benchmarkConfig = load_benchmark_config(benchmarkConfigPath);
scenarioConfigPath = fullfile(projectRoot, ...
    benchmarkConfig.scenario_library_config);
scenarioConfig = load_scenario_library_config(scenarioConfigPath);
scenarioConfig.datasets = benchmarkConfig.datasets;
scenarioConfig.seeds = benchmarkConfig.seeds;

outputDir = create_output_dir(projectRoot, benchmarkConfig.output_base_dir);

[scenarioRows, resultRows] = run_benchmark( ...
    projectRoot, benchmarkConfig, scenarioConfig);

write_text(fullfile(outputDir, 'benchmark_config_used.yaml'), ...
    read_text(benchmarkConfigPath));
write_seed_results_csv(fullfile(outputDir, 'seed_results.csv'), resultRows);
write_group_summary_csv(fullfile(outputDir, 'scenario_summary.csv'), ...
    resultRows, 'scenario_id');
write_group_summary_csv(fullfile(outputDir, 'dataset_summary.csv'), ...
    resultRows, 'dataset');
write_group_summary_csv(fullfile(outputDir, 'strategy_summary.csv'), ...
    resultRows, 'strategy_mode');
write_feasibility_summary_csv(fullfile(outputDir, ...
    'feasibility_summary.csv'), resultRows);
write_benchmark_summary_json(fullfile(outputDir, ...
    'benchmark_summary.json'), benchmarkConfig, scenarioRows, resultRows, ...
    outputDir);
write_benchmark_notes(fullfile(outputDir, 'benchmark_notes.md'), ...
    benchmarkConfig, scenarioRows, resultRows);

fprintf('order cancellation benchmark\n');
fprintf('dataset_count: %d\n', numel(benchmarkConfig.datasets));
fprintf('scenario_count: %d\n', numel(scenarioRows));
fprintf('strategy_count: %d\n', numel(benchmarkConfig.strategies));
fprintf('result_row_count: %d\n', numel(resultRows));
fprintf('output_dir: %s\n', outputDir);
fprintf('benchmark_config_used_yaml: %s\n', ...
    fullfile(outputDir, 'benchmark_config_used.yaml'));
fprintf('seed_results_csv: %s\n', fullfile(outputDir, 'seed_results.csv'));
fprintf('scenario_summary_csv: %s\n', ...
    fullfile(outputDir, 'scenario_summary.csv'));
fprintf('dataset_summary_csv: %s\n', ...
    fullfile(outputDir, 'dataset_summary.csv'));
fprintf('strategy_summary_csv: %s\n', ...
    fullfile(outputDir, 'strategy_summary.csv'));
fprintf('feasibility_summary_csv: %s\n', ...
    fullfile(outputDir, 'feasibility_summary.csv'));
fprintf('benchmark_summary_json: %s\n', ...
    fullfile(outputDir, 'benchmark_summary.json'));
fprintf('benchmark_notes_md: %s\n', ...
    fullfile(outputDir, 'benchmark_notes.md'));

function [scenarioRows, resultRows] = run_benchmark( ...
    projectRoot, benchmarkConfig, scenarioConfig)
scenarioRows = repmat(empty_scenario_row(), 1, 0);
resultRows = repmat(empty_benchmark_result_row(), 1, 0);

for datasetIdx = 1:numel(benchmarkConfig.datasets)
    dataset = benchmarkConfig.datasets{datasetIdx};
    datasetPath = fullfile(projectRoot, dataset);
    problem = read_fjsp(datasetPath);
    machineData = build_sample_machine_data(problem.machineNum);
    agvData = build_sample_agv_data();
    baselineSchedule = build_sample_schedule(problem.machineNum);

    datasetScenarioConfig = scenarioConfig;
    datasetScenarioConfig.datasets = {dataset};
    [scenarios, ~] = build_order_cancellation_scenarios( ...
        problem, baselineSchedule, datasetScenarioConfig);

    for scenarioIdx = 1:numel(scenarios)
        scenario = scenarios(scenarioIdx);
        scenarioRows(end + 1) = make_scenario_row(scenario);
        rows = run_benchmark_scenario( ...
            problem, machineData, agvData, baselineSchedule, scenario, ...
            benchmarkConfig);
        for rowIdx = 1:numel(rows)
            resultRows(end + 1) = rows(rowIdx);
        end
    end
end
end

function rows = run_benchmark_scenario( ...
    problem, machineData, agvData, baselineSchedule, scenario, ...
    benchmarkConfig)
rows = repmat(empty_benchmark_result_row(), 1, 0);
baseResult = struct();
baseRuntime = NaN;
baseError = '';

try
    tic;
    baseResult = run_order_cancellation_library_scenario( ...
        problem, machineData, agvData, baselineSchedule, scenario, struct());
    baseRuntime = toc;
catch err
    baseError = err.message;
end

for strategyIdx = 1:numel(benchmarkConfig.strategies)
    strategyMode = benchmarkConfig.strategies{strategyIdx};
    switch strategyMode
        case 'fixed_weight'
            rows(end + 1) = make_fixed_weight_row( ...
                scenario, baseResult, baseRuntime, baseError);
        case 'adaptive_weight'
            rows(end + 1) = make_adaptive_weight_row( ...
                scenario, baseResult, baseRuntime, baseError, ...
                baselineSchedule, machineData, agvData);
        otherwise
            row = make_error_row(scenario, strategyMode, ...
                sprintf('Unsupported strategy mode: %s', strategyMode));
            rows(end + 1) = row;
    end
end
end

function row = make_fixed_weight_row(scenario, baseResult, runtimeSeconds, ...
    baseError)
row = empty_benchmark_result_row();
row = fill_scenario_fields(row, scenario, 'fixed_weight');
row.runtime_seconds = runtimeSeconds;

if ~isempty(baseError)
    row.error_count = 1;
    row.rejected_reason_count = 1;
    return
end

row = fill_candidate_fields(row, baseResult);
row.selected_strategy = read_char_field(baseResult, 'selected_strategy', '');
row.is_selected = ~isempty(row.selected_strategy);
row.no_feasible_candidate = strcmp( ...
    read_char_field(baseResult, 'selected_reason', ''), ...
    'no_feasible_candidate');
row = fill_selected_metrics_from_result(row, baseResult);
row.constraint_feasible = selected_constraint_feasible(row, baseResult);
row.error_count = read_numeric_field(baseResult, 'local_error_count', 0) + ...
    read_numeric_field(baseResult, 'complete_error_count', 0);
row.rejected_reason_count = count_rejected_reasons(baseResult);
end

function row = make_adaptive_weight_row( ...
    scenario, baseResult, baseRuntime, baseError, baselineSchedule, ...
    machineData, agvData)
row = empty_benchmark_result_row();
row = fill_scenario_fields(row, scenario, 'adaptive_weight');

if ~isempty(baseError)
    row.runtime_seconds = baseRuntime;
    row.error_count = 1;
    row.rejected_reason_count = 1;
    return
end

row = fill_candidate_fields(row, baseResult);
try
    tic;
    details = baseResult.details;
    adaptiveResult = select_adaptive_cancellation_strategy( ...
        baselineSchedule, details.state, details.cancel, ...
        details.localCandidate, details.completeCandidate, ...
        machineData, agvData, details.evaluationConfig);
    adaptiveRuntime = toc;
    row.runtime_seconds = baseRuntime + adaptiveRuntime;
    row.selected_strategy = read_char_field( ...
        adaptiveResult.selection, 'name', '');
    row.is_selected = get_logical_field( ...
        adaptiveResult.selection, 'isSelected');
    row.no_feasible_candidate = strcmp( ...
        read_char_field(adaptiveResult.selection, 'reason', ''), ...
        'no_feasible_candidate');
    row = fill_selected_metrics_from_evaluations( ...
        row, adaptiveResult.localRepairEvaluation, ...
        adaptiveResult.completeReschedulingEvaluation);
    row.constraint_feasible = selected_constraint_feasible(row, baseResult);
    row.error_count = evaluation_error_count( ...
        adaptiveResult.localRepairEvaluation) + ...
        evaluation_error_count(adaptiveResult.completeReschedulingEvaluation);
    row.rejected_reason_count = selection_rejected_reason_count( ...
        adaptiveResult.selection);
catch err
    row.runtime_seconds = baseRuntime;
    row.error_count = 1;
    row.rejected_reason_count = 1;
end
end

function row = make_error_row(scenario, strategyMode, errorMessage)
row = empty_benchmark_result_row();
row = fill_scenario_fields(row, scenario, strategyMode);
row.error_count = 1;
row.rejected_reason_count = 1;
if ~isempty(errorMessage)
    row.no_feasible_candidate = true;
end
end

function row = fill_scenario_fields(row, scenario, strategyMode)
row.dataset = scenario.dataset;
row.scenario_id = scenario.scenario_id;
row.time_window = scenario.time_window;
row.job_category = scenario.job_category;
row.seed = scenario.seed;
row.strategy_mode = strategyMode;
end

function row = fill_candidate_fields(row, result)
row.local_feasible = get_logical_field(result, 'local_isFeasible');
row.complete_feasible = get_logical_field(result, 'complete_isFeasible');
end

function row = fill_selected_metrics_from_result(row, result)
switch row.selected_strategy
    case 'local_repair'
        row.Cmax_delta = read_numeric_field(result, 'local_Cmax_delta', NaN);
        row.SD = read_numeric_field(result, 'local_SD', NaN);
        row.TD = read_numeric_field(result, 'local_TD', NaN);
        row.energy_delta = read_numeric_field( ...
            result, 'local_energy_delta', NaN);
        row.Y = read_numeric_field(result, 'local_Y', NaN);
    case 'complete_rescheduling'
        row.Cmax_delta = read_numeric_field( ...
            result, 'complete_Cmax_delta', NaN);
        row.SD = read_numeric_field(result, 'complete_SD', NaN);
        row.TD = read_numeric_field(result, 'complete_TD', NaN);
        row.energy_delta = read_numeric_field( ...
            result, 'complete_energy_delta', NaN);
        row.Y = read_numeric_field(result, 'complete_Y', NaN);
end
end

function row = fill_selected_metrics_from_evaluations( ...
    row, localEvaluation, completeEvaluation)
switch row.selected_strategy
    case 'local_repair'
        row = fill_metrics_from_evaluation(row, localEvaluation);
    case 'complete_rescheduling'
        row = fill_metrics_from_evaluation(row, completeEvaluation);
end
end

function row = fill_metrics_from_evaluation(row, evaluation)
if ~isstruct(evaluation) || ~isfield(evaluation, 'metrics')
    return
end
metrics = evaluation.metrics;
row.Cmax_delta = read_numeric_field(metrics, 'Cmax_delta', NaN);
row.SD = read_numeric_field(metrics, 'SD', NaN);
row.TD = read_numeric_field(metrics, 'TD', NaN);
row.energy_delta = read_numeric_field(metrics, 'energy_delta', NaN);
row.Y = read_numeric_field(metrics, 'Y', NaN);
end

function isFeasible = selected_constraint_feasible(row, result)
isFeasible = false;
switch row.selected_strategy
    case 'local_repair'
        isFeasible = get_logical_field( ...
            result, 'local_machine_check_isFeasible') && ...
            get_logical_field(result, 'local_agv_check_isFeasible') && ...
            get_logical_field(result, 'local_job_sequence_check_isFeasible');
    case 'complete_rescheduling'
        isFeasible = get_logical_field( ...
            result, 'complete_machine_check_isFeasible') && ...
            get_logical_field(result, 'complete_agv_check_isFeasible') && ...
            get_logical_field( ...
            result, 'complete_job_sequence_check_isFeasible') && ...
            get_logical_field(result, 'complete_frozen_check_isFeasible') && ...
            get_logical_field( ...
            result, 'complete_cancelled_exclusion_check_isFeasible');
end
end

function count = count_rejected_reasons(result)
count = count_cell_field(result, 'local_rejectedReasons') + ...
    count_cell_field(result, 'complete_rejectedReasons');
if strcmp(read_char_field(result, 'selected_reason', ''), ...
        'no_feasible_candidate')
    count = count + 1;
end
end

function count = evaluation_error_count(evaluation)
count = 0;
if isstruct(evaluation) && isfield(evaluation, 'report') && ...
        isstruct(evaluation.report) && isfield(evaluation.report, 'errors')
    count = numel(evaluation.report.errors);
end
end

function count = selection_rejected_reason_count(selection)
count = 0;
if ~isstruct(selection) || ~isfield(selection, 'candidates')
    return
end
if isfield(selection.candidates, 'localRepair')
    count = count + count_cell_field( ...
        selection.candidates.localRepair, 'rejectedReasons');
end
if isfield(selection.candidates, 'completeRescheduling')
    count = count + count_cell_field( ...
        selection.candidates.completeRescheduling, 'rejectedReasons');
end
if strcmp(read_char_field(selection, 'reason', ''), ...
        'no_feasible_candidate')
    count = count + 1;
end
end

function outputDir = create_output_dir(projectRoot, outputBaseDir)
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
outputDir = fullfile(projectRoot, outputBaseDir, timestamp);
suffix = 1;
while exist(outputDir, 'dir')
    outputDir = fullfile(projectRoot, outputBaseDir, ...
        sprintf('%s_%02d', timestamp, suffix));
    suffix = suffix + 1;
end
mkdir(outputDir);
end

function write_seed_results_csv(filePath, rows)
fid = fopen(filePath, 'w');
if fid < 0
    error('run_order_cancellation_benchmark:FileOpenFailed', ...
        'Cannot open seed_results.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['dataset,scenario_id,time_window,job_category,seed,', ...
    'strategy_mode,selected_strategy,is_selected,local_feasible,', ...
    'complete_feasible,Cmax_delta,SD,TD,energy_delta,Y,', ...
    'constraint_feasible,no_feasible_candidate,runtime_seconds,', ...
    'error_count,rejected_reason_count\n']);

for i = 1:numel(rows)
    row = rows(i);
    fprintf(fid, ['%s,%s,%s,%s,%d,%s,%s,%d,%d,%d,', ...
        '%.6f,%.6f,%.6f,%.6f,%.6f,%d,%d,%.6f,%d,%d\n'], ...
        csv_text(row.dataset), csv_text(row.scenario_id), ...
        csv_text(row.time_window), csv_text(row.job_category), ...
        row.seed, csv_text(row.strategy_mode), ...
        csv_text(row.selected_strategy), row.is_selected, ...
        row.local_feasible, row.complete_feasible, row.Cmax_delta, ...
        row.SD, row.TD, row.energy_delta, row.Y, ...
        row.constraint_feasible, row.no_feasible_candidate, ...
        row.runtime_seconds, row.error_count, row.rejected_reason_count);
end
end

function write_group_summary_csv(filePath, rows, groupField)
summary = summarize_order_cancellation_benchmark(rows);
switch groupField
    case 'scenario_id'
        groupRows = summary.by_scenario;
    case 'dataset'
        groupRows = summary.by_dataset;
    case 'strategy_mode'
        groupRows = summary.by_strategy_mode;
    otherwise
        error('run_order_cancellation_benchmark:UnsupportedGroupField', ...
            'Unsupported group field: %s', groupField);
end
fid = fopen(filePath, 'w');
if fid < 0
    error('run_order_cancellation_benchmark:FileOpenFailed', ...
        'Cannot open group summary csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['group,run_count,selected_count,win_rate,', ...
    'no_feasible_candidate_count,infeasible_rate,Cmax_delta_mean,Cmax_delta_std,', ...
    'SD_mean,SD_std,TD_mean,TD_std,energy_delta_mean,', ...
    'energy_delta_std,Y_mean,Y_std\n']);

for i = 1:numel(groupRows)
    row = groupRows(i);
    fprintf(fid, ['%s,%d,%d,%.6f,%d,%.6f,%.6f,%.6f,%.6f,', ...
        '%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n'], ...
        csv_text(row.(groupField)), row.run_count, row.selected_count, ...
        row.win_rate, row.no_feasible_candidate_count, row.infeasible_rate, ...
        row.Cmax_delta_mean, row.Cmax_delta_std, row.SD_mean, row.SD_std, ...
        row.TD_mean, row.TD_std, row.energy_delta_mean, ...
        row.energy_delta_std, row.Y_mean, row.Y_std);
end
end

function write_feasibility_summary_csv(filePath, rows)
summary = summarize_order_cancellation_benchmark(rows);
groups = summary.by_feasibility;

fid = fopen(filePath, 'w');
if fid < 0
    error('run_order_cancellation_benchmark:FileOpenFailed', ...
        'Cannot open feasibility_summary.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'feasibility,count,rate\n');
for i = 1:numel(groups)
    fprintf(fid, '%s,%d,%.6f\n', csv_text(groups(i).feasibility), ...
        groups(i).count, groups(i).rate);
end
end

function write_benchmark_summary_json(filePath, config, scenarioRows, ...
    resultRows, outputDir)
summary = struct();
summary.experiment_name = 'order_cancellation_benchmark';
summary.datasets = config.datasets;
summary.scenario_library_config = config.scenario_library_config;
summary.strategies = config.strategies;
summary.seeds = config.seeds;
summary.max_runtime_minutes = config.max_runtime_minutes;
summary.output_dir = outputDir;
summary.scenario_count = numel(scenarioRows);
summary.result_row_count = numel(resultRows);
summary.output_files = { ...
    'benchmark_config_used.yaml', ...
    'seed_results.csv', ...
    'scenario_summary.csv', ...
    'dataset_summary.csv', ...
    'strategy_summary.csv', ...
    'feasibility_summary.csv', ...
    'benchmark_summary.json', ...
    'benchmark_notes.md'};
summary.scope = struct();
summary.scope.machine_failure = false;
summary.scope.full_order_insertion = false;
summary.scope.reinforcement_learning = false;
summary.scope.algorithm_rewrite = false;
summary.scope.global_optimality_proof = false;

write_text(filePath, jsonencode(summary));
end

function write_benchmark_notes(filePath, config, scenarioRows, resultRows)
lines = {
    '# Stage L Benchmark Notes'
    ''
    'Generated by `scripts/run_order_cancellation_benchmark.m`.'
    ''
    '## Scope'
    ''
    sprintf('- Dataset count: `%d`', numel(config.datasets))
    sprintf('- Scenario count: `%d`', numel(scenarioRows))
    sprintf('- Result row count: `%d`', numel(resultRows))
    sprintf('- Strategy modes: `%s`', strjoin(config.strategies, ', '))
    sprintf('- Max runtime budget: `%g` minutes', config.max_runtime_minutes)
    ''
    '## Interpretation Boundaries'
    ''
    '- This is a stage L benchmark, not a global optimality proof.'
    '- Machine failure is out of scope.'
    '- Full new-order insertion is out of scope.'
    '- Reinforcement learning is out of scope.'
    '- Existing local repair, complete rescheduling, evaluation, and adaptive weighting logic are reused.'
    ''
    '## Review Checklist'
    ''
    '- Inspect `seed_results.csv` before using summary tables.'
    '- Compare `fixed_weight` and `adaptive_weight` in `strategy_summary.csv`.'
    '- Check `feasibility_summary.csv` before drawing conclusions.'
};
write_text(filePath, strjoin(lines, newline));
end

function groupRows = summarize_group(rows, groupField)
if isempty(rows)
    groupRows = repmat(empty_group_summary(), 1, 0);
    return
end

values = group_values(rows, groupField);
groups = unique(values, 'stable');
groupRows = repmat(empty_group_summary(), 1, numel(groups));
for i = 1:numel(groups)
    rowsInGroup = rows(strcmp(values, groups{i}));
    groupRows(i) = build_group_summary(groups{i}, rowsInGroup);
end
end

function values = group_values(rows, groupField)
values = cell(1, numel(rows));
for i = 1:numel(rows)
    value = rows(i).(groupField);
    if isnumeric(value)
        values{i} = num2str(value);
    else
        values{i} = char(string(value));
    end
end
end

function row = build_group_summary(group, rows)
row = empty_group_summary();
row.group = group;
row.run_count = numel(rows);
row.selected_count = sum([rows.is_selected]);
row.constraint_feasible_count = sum([rows.constraint_feasible]);
row.no_feasible_candidate_count = sum([rows.no_feasible_candidate]);
row.Cmax_delta_mean = mean_field(rows, 'Cmax_delta');
row.Cmax_delta_std = std_field(rows, 'Cmax_delta');
row.SD_mean = mean_field(rows, 'SD');
row.SD_std = std_field(rows, 'SD');
row.TD_mean = mean_field(rows, 'TD');
row.TD_std = std_field(rows, 'TD');
row.energy_delta_mean = mean_field(rows, 'energy_delta');
row.energy_delta_std = std_field(rows, 'energy_delta');
row.Y_mean = mean_field(rows, 'Y');
row.Y_std = std_field(rows, 'Y');
row.runtime_seconds_mean = mean_field(rows, 'runtime_seconds');
row.error_count = sum([rows.error_count]);
row.rejected_reason_count = sum([rows.rejected_reason_count]);
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
values = [rows.(fieldName)];
values = values(isfinite(values));
end

function label = feasibility_label(row)
if row.local_feasible && row.complete_feasible
    label = 'both_candidates_feasible';
elseif row.local_feasible
    label = 'local_only';
elseif row.complete_feasible
    label = 'complete_only';
else
    label = 'no_candidate_feasible';
end
end

function config = load_benchmark_config(configPath)
config = default_benchmark_config();
lines = read_text_lines(configPath);
section = '';

for i = 1:numel(lines)
    line = strtrim(lines{i});
    if isempty(line) || startsWith(line, '#')
        continue
    end

    if startsWith(line, 'datasets:')
        section = 'datasets';
        config.datasets = {};
        continue
    elseif startsWith(line, 'strategies:')
        section = 'strategies';
        config.strategies = {};
        continue
    end

    if strcmp(section, 'datasets') && startsWith(line, '- ')
        config.datasets{end + 1} = strtrim(extractAfter(line, '- '));
        continue
    end
    if strcmp(section, 'strategies') && startsWith(line, '- ')
        config.strategies{end + 1} = strtrim(extractAfter(line, '- '));
        continue
    end

    section = '';
    if startsWith(line, 'scenario_library_config:')
        config.scenario_library_config = strtrim(extractAfter( ...
            line, 'scenario_library_config:'));
    elseif startsWith(line, 'seeds:')
        config.seeds = parse_numeric_list(strtrim(extractAfter( ...
            line, 'seeds:')));
    elseif startsWith(line, 'max_runtime_minutes:')
        config.max_runtime_minutes = str2double(strtrim(extractAfter( ...
            line, 'max_runtime_minutes:')));
    elseif startsWith(line, 'output_base_dir:')
        config.output_base_dir = strtrim(extractAfter( ...
            line, 'output_base_dir:'));
    end
end
end

function config = load_scenario_library_config(configPath)
lines = read_text_lines(configPath);
config = default_scenario_library_config();
section = '';
currentTimeWindow = empty_time_window();
inTimeWindow = false;

for i = 1:numel(lines)
    line = strtrim(lines{i});
    if isempty(line) || startsWith(line, '#')
        continue
    end

    if startsWith(line, 'datasets:')
        section = 'datasets';
        config.datasets = {};
        continue
    elseif startsWith(line, 'time_windows:')
        section = 'time_windows';
        continue
    elseif startsWith(line, 'job_categories:')
        section = 'job_categories';
        config.job_categories = {};
        continue
    end

    if strcmp(section, 'datasets') && startsWith(line, '- ')
        config.datasets{end + 1} = strtrim(extractAfter(line, '- '));
        continue
    end

    if strcmp(section, 'job_categories') && startsWith(line, '- ')
        config.job_categories{end + 1} = strtrim(extractAfter(line, '- '));
        continue
    end

    if strcmp(section, 'time_windows') && startsWith(line, '- name:')
        if inTimeWindow
            config.time_windows(end + 1) = currentTimeWindow;
        end
        currentTimeWindow = empty_time_window();
        currentTimeWindow.name = strtrim(extractAfter(line, '- name:'));
        inTimeWindow = true;
        continue
    end

    if strcmp(section, 'time_windows') && startsWith( ...
            line, 'cancel_time_ratio:')
        currentTimeWindow.cancel_time_ratio = str2double(strtrim( ...
            extractAfter(line, 'cancel_time_ratio:')));
        continue
    end

    if startsWith(line, 'cancel_policy:')
        config.cancel_policy = strtrim(extractAfter(line, 'cancel_policy:'));
        section = '';
    elseif startsWith(line, 'seeds:')
        config.seeds = parse_numeric_list(strtrim(extractAfter( ...
            line, 'seeds:')));
        section = '';
    elseif startsWith(line, 'output_base_dir:')
        config.output_base_dir = strtrim(extractAfter( ...
            line, 'output_base_dir:'));
        section = '';
    end
end

if inTimeWindow
    config.time_windows(end + 1) = currentTimeWindow;
end
end

function config = default_benchmark_config()
config = struct();
config.datasets = {};
config.scenario_library_config = ...
    'configs/order_cancellation_scenario_library.yaml';
config.strategies = {'fixed_weight', 'adaptive_weight'};
config.seeds = [1, 2, 3, 4, 5];
config.max_runtime_minutes = 30;
config.output_base_dir = 'outputs/order_cancellation_benchmark';
end

function config = default_scenario_library_config()
config = struct();
config.datasets = {};
config.cancel_policy = 'cancel_unstarted_operations_only';
config.time_windows = repmat(empty_time_window(), 1, 0);
config.job_categories = {};
config.seeds = [1, 2, 3];
config.output_base_dir = 'outputs/order_cancellation_scenario_library';
end

function timeWindow = empty_time_window()
timeWindow = struct();
timeWindow.name = '';
timeWindow.cancel_time_ratio = NaN;
end

function values = parse_numeric_list(textValue)
textValue = strrep(textValue, '[', '');
textValue = strrep(textValue, ']', '');
parts = strsplit(textValue, ',');
values = zeros(1, numel(parts));
for i = 1:numel(parts)
    values(i) = str2double(strtrim(parts{i}));
end
end

function row = make_scenario_row(scenario)
row = empty_scenario_row();
row.dataset = scenario.dataset;
row.scenario_id = scenario.scenario_id;
row.time_window = scenario.time_window;
row.job_category = scenario.job_category;
row.seed = scenario.seed;
end

function row = empty_scenario_row()
row = struct();
row.dataset = '';
row.scenario_id = '';
row.time_window = '';
row.job_category = '';
row.seed = NaN;
end

function row = empty_benchmark_result_row()
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

function row = empty_group_summary()
row = struct();
row.group = '';
row.run_count = 0;
row.selected_count = 0;
row.constraint_feasible_count = 0;
row.no_feasible_candidate_count = 0;
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
row.runtime_seconds_mean = NaN;
row.error_count = 0;
row.rejected_reason_count = 0;
end

function value = read_numeric_field(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && isnumeric(s.(fieldName)) && ...
        isscalar(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = read_char_field(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = char(string(s.(fieldName)));
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

function count = count_cell_field(s, fieldName)
count = 0;
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
    if iscell(value)
        count = numel(value);
    end
end
end

function text = read_text(filePath)
lines = read_text_lines(filePath);
text = strjoin(lines, newline);
end

function lines = read_text_lines(filePath)
fid = fopen(filePath, 'r');
if fid < 0
    error('run_order_cancellation_benchmark:FileOpenFailed', ...
        'Cannot open file: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));

lines = {};
while true
    line = fgetl(fid);
    if ~ischar(line)
        break
    end
    lines{end + 1} = line;
end
end

function write_text(filePath, text)
fid = fopen(filePath, 'w');
if fid < 0
    error('run_order_cancellation_benchmark:FileOpenFailed', ...
        'Cannot open file for writing: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
end

function value = csv_text(value)
if isnumeric(value)
    value = num2str(value);
elseif iscell(value)
    value = strjoin(value, '; ');
else
    value = char(string(value));
end
value = strrep(value, '"', '""');
value = ['"', value, '"'];
end

function machineData = build_sample_machine_data(machineNum)
machineData = struct();
machineData.distance_matrix = struct();
machineData.distance_matrix.machine_to_machine = zeros(machineNum, machineNum);
for i = 1:machineNum
    for j = 1:machineNum
        machineData.distance_matrix.machine_to_machine(i, j) = abs(i - j);
    end
end
machineData.distance_matrix.load_to_machine = 1:machineNum;
machineData.distance_matrix.machine_to_unload = machineNum:-1:1;
machineData.distance_matrix.load_to_unload = 1;
machineData.machineEnergy = struct();
machineData.machineEnergy.work = ones(1, machineNum) * 2;
machineData.machineEnergy.free = ones(1, machineNum);
end

function agvData = build_sample_agv_data()
agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5, 2.0];
agvData.AGVEnergy.free = [1.0, 1.2, 1.4];
agvData.AGVEnergy.load = [1.4, 1.6, 1.8];
end

function schedule = build_sample_schedule(machineNum)
schedule = struct();
schedule.machineTable = build_sample_machine_table(machineNum);
schedule.AGVTable = build_sample_agv_table();
end

function machineTable = build_sample_machine_table(machineNum)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = make_machine_block(0, inf, 0, 0);
end

machineTable{1} = [
    make_machine_block(0, 4, 1, 1)
    make_machine_block(10, 14, 1, 2)
    make_machine_block(14, inf, 0, 0)
];

machineTable{2} = [
    make_machine_block(0, 3, 3, 1)
    make_machine_block(3, 8, 2, 1)
    make_machine_block(12, 15, 2, 2)
    make_machine_block(15, inf, 0, 0)
];

if machineNum >= 3
    machineTable{3} = [
        make_machine_block(14, 18, 3, 2)
        make_machine_block(18, inf, 0, 0)
    ];
end
end

function AGVTable = build_sample_agv_table()
AGVTable = cell(1, 2);

AGVTable{1} = [
    make_agv_block(0, 4, 1, 1, -1, 1, -2)
    make_agv_block(10, 12, 1, 2, 1, 1, -2)
    make_agv_block(12, 16, 2, 2, 2, -2, -2)
    make_agv_block(16, inf, 0, 0, -2, -2, 0)
];

AGVTable{2} = [
    make_agv_block(0, 3, 3, 1, -1, 2, -2)
    make_agv_block(4, 8, 2, 1, -1, 2, -2)
    make_agv_block(10, 13, 3, 2, 2, -2, -2)
    make_agv_block(13, inf, 0, 0, -2, -2, 0)
];
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end

function block = make_agv_block(startTime, endTime, jobId, operationId, ...
    fromMachine, toMachine, loadStatus)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.from_machine = fromMachine;
block.to_machine = toMachine;
block.status = [];
block.load_status = loadStatus;
block.charge = 0;
end
