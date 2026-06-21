clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

configPath = fullfile(projectRoot, 'configs', ...
    'order_cancellation_small_experiment.yaml');
experimentConfig = load_small_experiment_config(configPath);

datasetPath = fullfile(projectRoot, experimentConfig.dataset);
problem = read_fjsp(datasetPath);
machineData = build_sample_machine_data(problem.machineNum);
agvData = build_sample_agv_data();
baselineSchedule = build_sample_schedule(problem.machineNum);

outputDir = create_output_dir(projectRoot, experimentConfig.output_base_dir);
results = run_scenarios( ...
    problem, machineData, agvData, baselineSchedule, experimentConfig);

write_scenario_results_csv( ...
    fullfile(outputDir, 'scenario_results.csv'), results);
write_seed_results_csv(fullfile(outputDir, 'seed_results.csv'), results);
write_selected_strategy_counts( ...
    fullfile(outputDir, 'selected_strategy_counts.csv'), results);
write_summary_json(fullfile(outputDir, 'summary.json'), ...
    experimentConfig, outputDir, results);
write_experiment_notes(fullfile(outputDir, 'experiment_notes.md'), ...
    experimentConfig, results);
write_run_summary(fullfile(outputDir, 'run_summary.txt'), ...
    experimentConfig, outputDir, results);

fprintf('order cancellation small experiment\n');
fprintf('dataset: %s\n', experimentConfig.dataset);
fprintf('scenario_count: %d\n', numel(experimentConfig.scenarios));
fprintf('seed_count: %d\n', numel(experimentConfig.seeds));
fprintf('run_count: %d\n', numel(results));
fprintf('output_dir: %s\n', outputDir);
fprintf('seed_results_csv: %s\n', fullfile(outputDir, 'seed_results.csv'));
fprintf('scenario_results_csv: %s\n', ...
    fullfile(outputDir, 'scenario_results.csv'));
fprintf('summary_json: %s\n', fullfile(outputDir, 'summary.json'));
fprintf('selected_strategy_counts_csv: %s\n', ...
    fullfile(outputDir, 'selected_strategy_counts.csv'));
fprintf('experiment_notes_md: %s\n', ...
    fullfile(outputDir, 'experiment_notes.md'));
fprintf('run_summary_txt: %s\n', fullfile(outputDir, 'run_summary.txt'));

function results = run_scenarios( ...
    problem, machineData, agvData, baselineSchedule, experimentConfig)
results = struct([]);

runConfig = struct();
runConfig.cancel_policy = experimentConfig.cancel_policy;

for scenarioIdx = 1:numel(experimentConfig.scenarios)
    scenario = experimentConfig.scenarios(scenarioIdx);
    for seedIdx = 1:numel(experimentConfig.seeds)
        seed = experimentConfig.seeds(seedIdx);
        result = run_order_cancellation_scenario( ...
            problem, machineData, agvData, baselineSchedule, ...
            scenario, seed, runConfig);
        results(end + 1) = remove_details(result);
    end
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

function write_seed_results_csv(filePath, results)
fid = fopen(filePath, 'w');
if fid < 0
    error('small_experiment:FileOpenFailed', ...
        'Cannot open seed_results.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['scenario_name,seed,cancel_job_id,cancel_time,', ...
    'local_candidate_isFeasible,complete_candidate_isFeasible,', ...
    'local_machine_check_isFeasible,local_agv_check_isFeasible,', ...
    'local_job_sequence_check_isFeasible,', ...
    'complete_machine_check_isFeasible,complete_agv_check_isFeasible,', ...
    'complete_job_sequence_check_isFeasible,', ...
    'complete_frozen_check_isFeasible,', ...
    'complete_cancelled_exclusion_check_isFeasible,', ...
    'local_isFeasible,complete_isFeasible,', ...
    'local_Cmax_delta,complete_Cmax_delta,', ...
    'local_SD,complete_SD,local_TD,complete_TD,', ...
    'local_energy_delta,complete_energy_delta,', ...
    'local_Y,complete_Y,selected_strategy,selected_reason,selected_Y\n']);

for i = 1:numel(results)
    row = results(i);
    fprintf(fid, ['%s,%d,%d,%.6f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,', ...
        '%d,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,', ...
        '%.6f,%.6f,%s,%s,%.6f\n'], ...
        row.scenario_name, row.seed, row.cancel_job_id, ...
        row.cancel_time, row.local_candidate_isFeasible, ...
        row.complete_candidate_isFeasible, ...
        row.local_machine_check_isFeasible, ...
        row.local_agv_check_isFeasible, ...
        row.local_job_sequence_check_isFeasible, ...
        row.complete_machine_check_isFeasible, ...
        row.complete_agv_check_isFeasible, ...
        row.complete_job_sequence_check_isFeasible, ...
        row.complete_frozen_check_isFeasible, ...
        row.complete_cancelled_exclusion_check_isFeasible, ...
        row.local_isFeasible, row.complete_isFeasible, ...
        row.local_Cmax_delta, row.complete_Cmax_delta, ...
        row.local_SD, row.complete_SD, row.local_TD, row.complete_TD, ...
        row.local_energy_delta, row.complete_energy_delta, ...
        row.local_Y, row.complete_Y, ...
        row.selected_strategy, row.selected_reason, row.selected_Y);
end
end

function write_scenario_results_csv(filePath, results)
scenarioNames = unique({results.scenario_name}, 'stable');
fid = fopen(filePath, 'w');
if fid < 0
    error('small_experiment:FileOpenFailed', ...
        'Cannot open scenario_results.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['scenario_name,run_count,local_feasible_count,', ...
    'complete_feasible_count,local_Cmax_delta_mean,', ...
    'complete_Cmax_delta_mean,local_SD_mean,complete_SD_mean,', ...
    'local_TD_mean,complete_TD_mean,local_energy_delta_mean,', ...
    'complete_energy_delta_mean,local_Y_mean,complete_Y_mean,', ...
    'selected_local_repair_count,selected_complete_rescheduling_count\n']);

for i = 1:numel(scenarioNames)
    scenarioName = scenarioNames{i};
    rows = results(strcmp({results.scenario_name}, scenarioName));
    fprintf(fid, ['%s,%d,%d,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,', ...
        '%.6f,%.6f,%.6f,%.6f,%d,%d\n'], ...
        scenarioName, numel(rows), ...
        sum([rows.local_isFeasible]), ...
        sum([rows.complete_isFeasible]), ...
        mean_numeric_field(rows, 'local_Cmax_delta'), ...
        mean_numeric_field(rows, 'complete_Cmax_delta'), ...
        mean_numeric_field(rows, 'local_SD'), ...
        mean_numeric_field(rows, 'complete_SD'), ...
        mean_numeric_field(rows, 'local_TD'), ...
        mean_numeric_field(rows, 'complete_TD'), ...
        mean_numeric_field(rows, 'local_energy_delta'), ...
        mean_numeric_field(rows, 'complete_energy_delta'), ...
        mean_numeric_field(rows, 'local_Y'), ...
        mean_numeric_field(rows, 'complete_Y'), ...
        sum(strcmp({rows.selected_strategy}, 'local_repair')), ...
        sum(strcmp({rows.selected_strategy}, 'complete_rescheduling')));
end
end

function write_selected_strategy_counts(filePath, results)
strategyNames = unique({results.selected_strategy}, 'stable');
fid = fopen(filePath, 'w');
if fid < 0
    error('small_experiment:FileOpenFailed', ...
        'Cannot open selected_strategy_counts.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'selected_strategy,count\n');
for i = 1:numel(strategyNames)
    strategyName = strategyNames{i};
    count = sum(strcmp({results.selected_strategy}, strategyName));
    fprintf(fid, '%s,%d\n', strategyName, count);
end
end

function write_summary_json(filePath, experimentConfig, outputDir, results)
summary = struct();
summary.experiment_name = 'order_cancellation_small_experiment';
summary.dataset = experimentConfig.dataset;
summary.cancel_policy = experimentConfig.cancel_policy;
summary.cancel_time_source = experimentConfig.cancel_time_source;
summary.scenarios = experimentConfig.scenarios;
summary.seeds = experimentConfig.seeds;
summary.output_dir = outputDir;
summary.output_files = { ...
    'scenario_results.csv', ...
    'seed_results.csv', ...
    'summary.json', ...
    'selected_strategy_counts.csv', ...
    'experiment_notes.md'};
summary.run_count = numel(results);
summary.scenario_count = numel(experimentConfig.scenarios);
summary.seed_count = numel(experimentConfig.seeds);
summary.evaluation = struct();
summary.evaluation.weights = struct( ...
    'Cmax_delta', 0.25, ...
    'SD', 0.25, ...
    'TD', 0.25, ...
    'energy_delta', 0.25);
summary.evaluation.normalization = ...
    'per_run_minmax_if_both_candidates_feasible_else_wide_fallback';
summary.scope = struct();
summary.scope.multiseed = true;
summary.scope.formal_experiment = false;
summary.scope.machine_failure = false;
summary.scope.new_order_insertion = false;
summary.scope.sequential_cancellation = false;
summary.scope.reinforcement_learning = false;
summary.scope.global_optimality_proof = false;

write_text(filePath, jsonencode(summary));
end

function write_experiment_notes(filePath, experimentConfig, results)
lines = {
    '# Stage F Small Experiment Notes'
    ''
    'Generated by `scripts/run_order_cancellation_small_experiment.m`.'
    ''
    '## Scope'
    ''
    sprintf('- Dataset: `%s`', experimentConfig.dataset)
    sprintf('- Cancellation policy: `%s`', experimentConfig.cancel_policy)
    sprintf('- Scenario count: `%d`', numel(experimentConfig.scenarios))
    sprintf('- Seed count: `%d`', numel(experimentConfig.seeds))
    sprintf('- Run count: `%d`', numel(results))
    ''
    '## Interpretation Boundaries'
    ''
    '- This is a stage F small experiment, not a final large-scale conclusion.'
    '- Machine failure is out of scope.'
    '- New order insertion is out of scope.'
    '- Sequential order cancellation is out of scope.'
    '- Reinforcement learning is out of scope.'
    '- Global optimality proof is out of scope.'
    ''
    '## Next Step'
    ''
    ['Research conclusions should be formed only after reviewing ', ...
    '`scenario_results.csv`, `seed_results.csv`, and constraint checks.']
};
write_text(filePath, strjoin(lines, newline));
end

function write_run_summary(filePath, experimentConfig, outputDir, results)
fid = fopen(filePath, 'w');
if fid < 0
    error('small_experiment:FileOpenFailed', ...
        'Cannot open run_summary.txt for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'order cancellation small experiment\n');
fprintf(fid, 'dataset: %s\n', experimentConfig.dataset);
fprintf(fid, 'cancel_policy: %s\n', experimentConfig.cancel_policy);
fprintf(fid, 'cancel_time_source: %s\n', ...
    experimentConfig.cancel_time_source);
fprintf(fid, 'scenario_count: %d\n', numel(experimentConfig.scenarios));
fprintf(fid, 'seed_count: %d\n', numel(experimentConfig.seeds));
fprintf(fid, 'run_count: %d\n', numel(results));
fprintf(fid, 'output_dir: %s\n', outputDir);
fprintf(fid, 'scope.multiseed: true\n');
fprintf(fid, 'scope.formal_experiment: false\n');
fprintf(fid, 'scope.machine_failure: false\n');
fprintf(fid, 'scope.new_order_insertion: false\n');
fprintf(fid, 'scope.reinforcement_learning: false\n');
fprintf(fid, 'scope.global_optimality_proof: false\n');
end

function write_text(filePath, text)
fid = fopen(filePath, 'w');
if fid < 0
    error('small_experiment:FileOpenFailed', ...
        'Cannot open file for writing: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
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

function config = load_small_experiment_config(configPath)
lines = read_text_lines(configPath);
config = default_experiment_config();
config.scenarios = repmat(empty_scenario(), 1, 0);
currentScenario = empty_scenario();
inScenario = false;

for i = 1:numel(lines)
    line = strtrim(lines{i});
    if isempty(line) || startsWith(line, '#')
        continue
    end

    if startsWith(line, '- name:')
        if inScenario
            config.scenarios(end + 1) = currentScenario;
        end
        currentScenario = empty_scenario();
        currentScenario.name = strtrim(extractAfter(line, '- name:'));
        inScenario = true;
        continue
    end

    if inScenario && startsWith(line, 'cancel_time_ratio:')
        currentScenario.cancel_time_ratio = str2double(strtrim( ...
            extractAfter(line, 'cancel_time_ratio:')));
        continue
    end

    if startsWith(line, 'dataset:')
        config.dataset = strtrim(extractAfter(line, 'dataset:'));
    elseif startsWith(line, 'cancel_policy:')
        config.cancel_policy = strtrim(extractAfter(line, 'cancel_policy:'));
    elseif startsWith(line, 'cancel_time_source:')
        config.cancel_time_source = strtrim( ...
            extractAfter(line, 'cancel_time_source:'));
    elseif startsWith(line, 'seeds:')
        config.seeds = parse_numeric_list(strtrim(extractAfter(line, ...
            'seeds:')));
    elseif startsWith(line, 'output_base_dir:')
        config.output_base_dir = strtrim(extractAfter(line, ...
            'output_base_dir:'));
    end
end

if inScenario
    config.scenarios(end + 1) = currentScenario;
end
end

function lines = read_text_lines(filePath)
fid = fopen(filePath, 'r');
if fid < 0
    error('small_experiment:FileOpenFailed', ...
        'Cannot open config file: %s', filePath);
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

function values = parse_numeric_list(textValue)
textValue = strrep(textValue, '[', '');
textValue = strrep(textValue, ']', '');
parts = strsplit(textValue, ',');
values = zeros(1, numel(parts));
for i = 1:numel(parts)
    values(i) = str2double(strtrim(parts{i}));
end
end

function config = default_experiment_config()
config = struct();
config.dataset = 'data_sample/Mk01.fjs';
config.cancel_policy = 'cancel_unstarted_operations_only';
config.cancel_time_source = 'baseline_Cmax_ratio';
config.scenarios = repmat(empty_scenario(), 1, 0);
config.seeds = [1, 2, 3];
config.output_base_dir = 'outputs/order_cancellation_small_experiment';
end

function scenario = empty_scenario()
scenario = struct();
scenario.name = '';
scenario.cancel_time_ratio = [];
end

function row = remove_details(result)
row = result;
if isfield(row, 'details')
    row = rmfield(row, 'details');
end
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
