clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

config = build_smoke_config();
outputDir = create_output_dir(projectRoot, config.output_base_dir);

[scenarioRows, resultRows] = run_smoke(projectRoot, config);

write_seed_results_csv(fullfile(outputDir, 'seed_results.csv'), resultRows);
write_group_summary_csv(fullfile(outputDir, 'scenario_summary.csv'), ...
    resultRows, 'scenario_id');
write_group_summary_csv(fullfile(outputDir, 'strategy_summary.csv'), ...
    resultRows, 'strategy_mode');
write_feasibility_summary_csv(fullfile(outputDir, ...
    'feasibility_summary.csv'), resultRows);
write_summary_json(fullfile(outputDir, 'benchmark_summary.json'), ...
    config, scenarioRows, resultRows, outputDir);
write_notes(fullfile(outputDir, 'benchmark_notes.md'), ...
    config, scenarioRows, resultRows);

fprintf('order cancellation benchmark smoke\n');
fprintf('dataset: %s\n', config.dataset);
fprintf('scenario_count: %d\n', numel(scenarioRows));
fprintf('seed_count: %d\n', numel(config.seeds));
fprintf('strategy_count: %d\n', numel(config.strategies));
fprintf('result_row_count: %d\n', numel(resultRows));
fprintf('output_dir: %s\n', outputDir);
fprintf('seed_results_csv: %s\n', fullfile(outputDir, 'seed_results.csv'));
fprintf('scenario_summary_csv: %s\n', ...
    fullfile(outputDir, 'scenario_summary.csv'));
fprintf('strategy_summary_csv: %s\n', ...
    fullfile(outputDir, 'strategy_summary.csv'));
fprintf('feasibility_summary_csv: %s\n', ...
    fullfile(outputDir, 'feasibility_summary.csv'));
fprintf('benchmark_summary_json: %s\n', ...
    fullfile(outputDir, 'benchmark_summary.json'));
fprintf('benchmark_notes_md: %s\n', ...
    fullfile(outputDir, 'benchmark_notes.md'));

function [scenarioRows, resultRows] = run_smoke(projectRoot, config)
problem = read_fjsp(fullfile(projectRoot, config.dataset));
machineData = build_sample_machine_data(problem.machineNum);
agvData = build_sample_agv_data();
baselineSchedule = build_sample_schedule(problem.machineNum);
scenarios = build_smoke_scenarios(config, baselineSchedule);

scenarioRows = repmat(empty_scenario_row(), 1, numel(scenarios));
resultRows = repmat(empty_result_row(), 1, 0);

for i = 1:numel(scenarios)
    scenario = scenarios(i);
    scenarioRows(i) = make_scenario_row(scenario);
    rows = run_one_smoke_scenario( ...
        problem, machineData, agvData, baselineSchedule, scenario, config);
    for rowIdx = 1:numel(rows)
        resultRows(end + 1) = rows(rowIdx);
    end
end
end

function scenarios = build_smoke_scenarios(config, baselineSchedule)
cmax = calculate_baseline_cmax(baselineSchedule);
scenarioCount = numel(config.time_windows) * numel(config.seeds);
scenarios = repmat(empty_scenario(), 1, scenarioCount);
idx = 0;

for seedIdx = 1:numel(config.seeds)
    seed = config.seeds(seedIdx);
    for timeIdx = 1:numel(config.time_windows)
        timeWindow = config.time_windows(timeIdx);
        idx = idx + 1;
        cancel = create_order_cancellation_event( ...
            config.cancel_job_id, ...
            cmax * timeWindow.cancel_time_ratio, ...
            config.cancel_policy);
        scenarios(idx).scenario_id = sprintf('%s_seed_%d', ...
            timeWindow.name, seed);
        scenarios(idx).dataset = config.dataset;
        scenarios(idx).seed = seed;
        scenarios(idx).time_window = timeWindow.name;
        scenarios(idx).job_category = 'smoke_fixed_job';
        scenarios(idx).cancel = cancel;
        scenarios(idx).cancel_time_ratio = timeWindow.cancel_time_ratio;
        scenarios(idx).notes = {'stage_l_smoke'};
    end
end
end

function rows = run_one_smoke_scenario( ...
    problem, machineData, agvData, baselineSchedule, scenario, config)
rows = repmat(empty_result_row(), 1, 0);
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

for strategyIdx = 1:numel(config.strategies)
    strategyMode = config.strategies{strategyIdx};
    switch strategyMode
        case 'fixed_weight'
            rows(end + 1) = make_fixed_row( ...
                scenario, baseResult, baseRuntime, baseError);
        case 'adaptive_weight'
            rows(end + 1) = make_adaptive_row( ...
                scenario, baseResult, baseRuntime, baseError, ...
                baselineSchedule, machineData, agvData);
    end
end
end

function row = make_fixed_row(scenario, baseResult, runtimeSeconds, baseError)
row = make_base_row(scenario, 'fixed_weight');
row.runtime_seconds = runtimeSeconds;
if ~isempty(baseError)
    row.error_count = 1;
    row.rejected_reason_count = 1;
    row.no_feasible_candidate = true;
    return
end

row.local_feasible = get_logical_field(baseResult, 'local_isFeasible');
row.complete_feasible = get_logical_field(baseResult, 'complete_isFeasible');
row.selected_strategy = read_char_field(baseResult, 'selected_strategy', '');
row.is_selected = ~isempty(row.selected_strategy);
row.no_feasible_candidate = strcmp( ...
    read_char_field(baseResult, 'selected_reason', ''), ...
    'no_feasible_candidate');
row = fill_metrics_from_base_result(row, baseResult);
row.constraint_feasible = selected_constraint_feasible(row, baseResult);
row.error_count = read_numeric_field(baseResult, 'local_error_count', 0) + ...
    read_numeric_field(baseResult, 'complete_error_count', 0);
row.rejected_reason_count = count_rejected_reasons(baseResult);
end

function row = make_adaptive_row( ...
    scenario, baseResult, baseRuntime, baseError, baselineSchedule, ...
    machineData, agvData)
row = make_base_row(scenario, 'adaptive_weight');
row.runtime_seconds = baseRuntime;
if ~isempty(baseError)
    row.error_count = 1;
    row.rejected_reason_count = 1;
    row.no_feasible_candidate = true;
    return
end

row.local_feasible = get_logical_field(baseResult, 'local_isFeasible');
row.complete_feasible = get_logical_field(baseResult, 'complete_isFeasible');
try
    tic;
    details = baseResult.details;
    adaptiveResult = select_adaptive_cancellation_strategy( ...
        baselineSchedule, details.state, details.cancel, ...
        details.localCandidate, details.completeCandidate, ...
        machineData, agvData, details.evaluationConfig);
    row.runtime_seconds = baseRuntime + toc;
    row.selected_strategy = read_char_field( ...
        adaptiveResult.selection, 'name', '');
    row.is_selected = get_logical_field( ...
        adaptiveResult.selection, 'isSelected');
    row.no_feasible_candidate = strcmp( ...
        read_char_field(adaptiveResult.selection, 'reason', ''), ...
        'no_feasible_candidate');
    row = fill_metrics_from_adaptive_result(row, adaptiveResult);
    row.constraint_feasible = selected_constraint_feasible(row, baseResult);
    row.error_count = evaluation_error_count( ...
        adaptiveResult.localRepairEvaluation) + ...
        evaluation_error_count(adaptiveResult.completeReschedulingEvaluation);
    row.rejected_reason_count = selection_rejected_reason_count( ...
        adaptiveResult.selection);
catch err
    row.error_count = 1;
    row.rejected_reason_count = 1;
    row.no_feasible_candidate = true;
end
end

function row = fill_metrics_from_base_result(row, result)
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

function row = fill_metrics_from_adaptive_result(row, adaptiveResult)
switch row.selected_strategy
    case 'local_repair'
        row = fill_metrics_from_evaluation( ...
            row, adaptiveResult.localRepairEvaluation);
    case 'complete_rescheduling'
        row = fill_metrics_from_evaluation( ...
            row, adaptiveResult.completeReschedulingEvaluation);
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

function write_seed_results_csv(filePath, rows)
fid = fopen(filePath, 'w');
if fid < 0
    error('benchmark_smoke:FileOpenFailed', ...
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
    case 'strategy_mode'
        groupRows = summary.by_strategy_mode;
    otherwise
        error('benchmark_smoke:UnsupportedGroupField', ...
            'Unsupported group field: %s', groupField);
end

fid = fopen(filePath, 'w');
if fid < 0
    error('benchmark_smoke:FileOpenFailed', ...
        'Cannot open summary csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, ['group,run_count,selected_count,win_rate,', ...
    'no_feasible_candidate_count,infeasible_rate,Cmax_delta_mean,', ...
    'Cmax_delta_std,SD_mean,SD_std,TD_mean,TD_std,', ...
    'energy_delta_mean,energy_delta_std,Y_mean,Y_std\n']);
for i = 1:numel(groupRows)
    row = groupRows(i);
    fprintf(fid, ['%s,%d,%d,%.6f,%d,%.6f,%.6f,%.6f,', ...
        '%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n'], ...
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
    error('benchmark_smoke:FileOpenFailed', ...
        'Cannot open feasibility_summary.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'feasibility,count,rate\n');
for i = 1:numel(groups)
    fprintf(fid, '%s,%d,%.6f\n', csv_text(groups(i).feasibility), ...
        groups(i).count, groups(i).rate);
end
end

function write_summary_json(filePath, config, scenarioRows, resultRows, ...
    outputDir)
summary = struct();
summary.experiment_name = 'order_cancellation_benchmark_smoke';
summary.dataset = config.dataset;
summary.seeds = config.seeds;
summary.strategies = config.strategies;
summary.scenario_count = numel(scenarioRows);
summary.result_row_count = numel(resultRows);
summary.output_dir = outputDir;
summary.scope = struct();
summary.scope.smoke = true;
summary.scope.final_conclusion = false;
summary.scope.machine_failure = false;
summary.scope.full_order_insertion = false;
summary.scope.reinforcement_learning = false;
write_text(filePath, jsonencode(summary));
end

function write_notes(filePath, config, scenarioRows, resultRows)
lines = {
    '# Stage L Benchmark Smoke Notes'
    ''
    'Generated by `scripts/run_order_cancellation_benchmark_smoke.m`.'
    ''
    '## Scope'
    ''
    sprintf('- Dataset: `%s`', config.dataset)
    sprintf('- Scenario count: `%d`', numel(scenarioRows))
    sprintf('- Result row count: `%d`', numel(resultRows))
    sprintf('- Seeds: `%s`', num2str(config.seeds))
    sprintf('- Strategies: `%s`', strjoin(config.strategies, ', '))
    ''
    '## Interpretation Boundaries'
    ''
    '- This is a small benchmark smoke run, not the final stage L conclusion.'
    '- It is used to verify output writing and fixed/adaptive strategy comparison.'
    '- Machine failure, full order insertion, reinforcement learning, and global optimality proof are out of scope.'
};
write_text(filePath, strjoin(lines, newline));
end

function config = build_smoke_config()
config = struct();
config.dataset = 'data_sample/Mk01.fjs';
config.cancel_policy = 'cancel_unstarted_operations_only';
config.cancel_job_id = 2;
config.seeds = [1, 2];
config.strategies = {'fixed_weight', 'adaptive_weight'};
config.output_base_dir = 'outputs/order_cancellation_benchmark_smoke';
config.time_windows = [
    make_time_window('early', 0.25)
    make_time_window('middle', 0.50)
    make_time_window('late', 0.75)
];
end

function timeWindow = make_time_window(name, ratio)
timeWindow = struct();
timeWindow.name = name;
timeWindow.cancel_time_ratio = ratio;
end

function cmax = calculate_baseline_cmax(schedule)
cmax = 0;
for machineIdx = 1:numel(schedule.machineTable)
    blocks = schedule.machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job > 0 && isfinite(block.end)
            cmax = max(cmax, block.end);
        end
    end
end
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

function row = make_scenario_row(scenario)
row = empty_scenario_row();
row.dataset = scenario.dataset;
row.scenario_id = scenario.scenario_id;
row.time_window = scenario.time_window;
row.job_category = scenario.job_category;
row.seed = scenario.seed;
end

function scenario = empty_scenario()
scenario = struct();
scenario.scenario_id = '';
scenario.dataset = '';
scenario.seed = NaN;
scenario.time_window = '';
scenario.job_category = '';
scenario.cancel = struct();
scenario.cancel_time_ratio = NaN;
scenario.notes = {};
end

function row = empty_scenario_row()
row = struct();
row.dataset = '';
row.scenario_id = '';
row.time_window = '';
row.job_category = '';
row.seed = NaN;
end

function row = make_base_row(scenario, strategyMode)
row = empty_result_row();
row.dataset = scenario.dataset;
row.scenario_id = scenario.scenario_id;
row.time_window = scenario.time_window;
row.job_category = scenario.job_category;
row.seed = scenario.seed;
row.strategy_mode = strategyMode;
end

function row = empty_result_row()
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

function write_text(filePath, text)
fid = fopen(filePath, 'w');
if fid < 0
    error('benchmark_smoke:FileOpenFailed', ...
        'Cannot open file for writing: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
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
