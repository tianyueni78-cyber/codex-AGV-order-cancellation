clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

configPath = fullfile(projectRoot, 'configs', ...
    'order_cancellation_scenario_library.yaml');
experimentConfig = load_scenario_library_config(configPath);
outputDir = create_output_dir(projectRoot, experimentConfig.output_base_dir);

[scenarioRows, resultRows, librarySummaries] = run_datasets( ...
    projectRoot, experimentConfig);

write_scenario_library_csv( ...
    fullfile(outputDir, 'scenario_library.csv'), scenarioRows);
write_seed_results_csv(fullfile(outputDir, 'seed_results.csv'), resultRows);
write_group_summary_csv(fullfile(outputDir, 'scenario_summary.csv'), ...
    resultRows, 'time_window');
write_group_summary_csv(fullfile(outputDir, 'category_summary.csv'), ...
    resultRows, 'job_category');
write_strategy_counts_csv(fullfile(outputDir, 'strategy_counts.csv'), ...
    resultRows);
write_summary_json(fullfile(outputDir, 'summary.json'), ...
    experimentConfig, outputDir, scenarioRows, resultRows, librarySummaries);
write_experiment_notes(fullfile(outputDir, 'experiment_notes.md'), ...
    experimentConfig, scenarioRows, resultRows);

fprintf('order cancellation scenario library experiment\n');
fprintf('dataset_count: %d\n', numel(experimentConfig.datasets));
fprintf('scenario_count: %d\n', numel(scenarioRows));
fprintf('run_count: %d\n', numel(resultRows));
fprintf('output_dir: %s\n', outputDir);
fprintf('scenario_library_csv: %s\n', ...
    fullfile(outputDir, 'scenario_library.csv'));
fprintf('seed_results_csv: %s\n', fullfile(outputDir, 'seed_results.csv'));
fprintf('scenario_summary_csv: %s\n', ...
    fullfile(outputDir, 'scenario_summary.csv'));
fprintf('category_summary_csv: %s\n', ...
    fullfile(outputDir, 'category_summary.csv'));
fprintf('strategy_counts_csv: %s\n', ...
    fullfile(outputDir, 'strategy_counts.csv'));
fprintf('summary_json: %s\n', fullfile(outputDir, 'summary.json'));
fprintf('experiment_notes_md: %s\n', ...
    fullfile(outputDir, 'experiment_notes.md'));

function [scenarioRows, resultRows, librarySummaries] = run_datasets( ...
    projectRoot, experimentConfig)
scenarioRows = repmat(empty_scenario_row(), 1, 0);
resultRows = repmat(empty_result_row(), 1, 0);
librarySummaries = repmat(empty_library_summary(), 1, 0);

for datasetIdx = 1:numel(experimentConfig.datasets)
    dataset = experimentConfig.datasets{datasetIdx};
    datasetPath = fullfile(projectRoot, dataset);
    problem = read_fjsp(datasetPath);
    machineData = build_sample_machine_data(problem.machineNum);
    agvData = build_sample_agv_data();
    baselineSchedule = build_sample_schedule(problem.machineNum);

    datasetConfig = experimentConfig;
    datasetConfig.datasets = {dataset};
    [scenarios, summary] = build_order_cancellation_scenarios( ...
        problem, baselineSchedule, datasetConfig);
    librarySummaries(end + 1).dataset = dataset;
    librarySummaries(end).summary = summary;

    for scenarioIdx = 1:numel(scenarios)
        scenario = scenarios(scenarioIdx);
        scenarioRows(end + 1) = make_scenario_row(scenario);
        result = run_one_scenario( ...
            problem, machineData, agvData, baselineSchedule, scenario);
        resultRows(end + 1) = make_result_row(result, scenario);
    end
end
end

function row = empty_library_summary()
row = struct();
row.dataset = '';
row.summary = struct();
end

function result = run_one_scenario( ...
    problem, machineData, agvData, baselineSchedule, scenario)
config = struct();
try
    result = run_order_cancellation_library_scenario( ...
        problem, machineData, agvData, baselineSchedule, scenario, config);
catch err
    result = struct();
    result.error_message = err.message;
    result.selected_reason = 'scenario_error';
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

function write_scenario_library_csv(filePath, scenarioRows)
fid = fopen(filePath, 'w');
if fid < 0
    error('scenario_library_experiment:FileOpenFailed', ...
        'Cannot open scenario_library.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['scenario_id,dataset,seed,time_window,job_category,', ...
    'cancel_job_id,cancel_time,cancel_policy,cancel_time_ratio,notes\n']);
for i = 1:numel(scenarioRows)
    row = scenarioRows(i);
    fprintf(fid, '%s,%s,%d,%s,%s,%d,%.6f,%s,%.6f,%s\n', ...
        csv_text(row.scenario_id), csv_text(row.dataset), row.seed, ...
        csv_text(row.time_window), csv_text(row.job_category), ...
        row.cancel_job_id, row.cancel_time, csv_text(row.cancel_policy), ...
        row.cancel_time_ratio, csv_text(row.notes));
end
end

function write_seed_results_csv(filePath, resultRows)
fid = fopen(filePath, 'w');
if fid < 0
    error('scenario_library_experiment:FileOpenFailed', ...
        'Cannot open seed_results.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['scenario_id,dataset,time_window,job_category,seed,', ...
    'cancel_job_id,cancel_time,cancel_policy,cancel_time_ratio,', ...
    'local_candidate_isFeasible,complete_candidate_isFeasible,', ...
    'local_machine_check_isFeasible,local_agv_check_isFeasible,', ...
    'local_job_sequence_check_isFeasible,', ...
    'complete_machine_check_isFeasible,complete_agv_check_isFeasible,', ...
    'complete_job_sequence_check_isFeasible,complete_frozen_check_isFeasible,', ...
    'complete_cancelled_exclusion_check_isFeasible,', ...
    'local_isFeasible,complete_isFeasible,', ...
    'local_Cmax_delta,complete_Cmax_delta,local_SD,complete_SD,', ...
    'local_TD,complete_TD,local_energy_delta,complete_energy_delta,', ...
    'local_Y,complete_Y,selected_strategy,selected_reason,selected_Y,', ...
    'local_error_count,complete_error_count,error_message\n']);

for i = 1:numel(resultRows)
    row = resultRows(i);
    fprintf(fid, ['%s,%s,%s,%s,%d,%d,%.6f,%s,%.6f,', ...
        '%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,', ...
        '%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,', ...
        '%.6f,%.6f,%s,%s,%.6f,%d,%d,%s\n'], ...
        csv_text(row.scenario_id), csv_text(row.dataset), ...
        csv_text(row.time_window), csv_text(row.job_category), ...
        row.seed, row.cancel_job_id, row.cancel_time, ...
        csv_text(row.cancel_policy), row.cancel_time_ratio, ...
        row.local_candidate_isFeasible, ...
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
        csv_text(row.selected_strategy), csv_text(row.selected_reason), ...
        row.selected_Y, row.local_error_count, row.complete_error_count, ...
        csv_text(row.error_message));
end
end

function write_group_summary_csv(filePath, resultRows, groupField)
summary = summarize_order_cancellation_library_results(resultRows);
switch groupField
    case 'time_window'
        groupRows = summary.by_time_window;
    case 'job_category'
        groupRows = summary.by_job_category;
    case 'dataset'
        groupRows = summary.by_dataset;
    case 'seed'
        groupRows = summary.by_seed;
    otherwise
        error('scenario_library_experiment:UnsupportedGroupField', ...
            'Unsupported group field: %s', groupField);
end

fid = fopen(filePath, 'w');
if fid < 0
    error('scenario_library_experiment:FileOpenFailed', ...
        'Cannot open group summary csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['group,run_count,local_feasible_count,complete_feasible_count,', ...
    'no_feasible_candidate_count,local_Cmax_delta_mean,', ...
    'complete_Cmax_delta_mean,local_SD_mean,complete_SD_mean,', ...
    'local_TD_mean,complete_TD_mean,local_energy_delta_mean,', ...
    'complete_energy_delta_mean,local_Y_mean,complete_Y_mean,', ...
    'selected_local_repair_count,selected_complete_rescheduling_count\n']);

for i = 1:numel(groupRows)
    row = groupRows(i);
    fprintf(fid, ['%s,%d,%d,%d,%d,%.6f,%.6f,%.6f,%.6f,%.6f,', ...
        '%.6f,%.6f,%.6f,%.6f,%.6f,%d,%d\n'], ...
        csv_text(row.(groupField)), row.run_count, ...
        row.local_feasible_count, row.complete_feasible_count, ...
        row.no_feasible_candidate_count, row.local_Cmax_delta_mean, ...
        row.complete_Cmax_delta_mean, row.local_SD_mean, ...
        row.complete_SD_mean, row.local_TD_mean, row.complete_TD_mean, ...
        row.local_energy_delta_mean, row.complete_energy_delta_mean, ...
        row.local_Y_mean, row.complete_Y_mean, ...
        row.selected_local_repair_count, ...
        row.selected_complete_rescheduling_count);
end
end

function write_strategy_counts_csv(filePath, resultRows)
summary = summarize_order_cancellation_library_results(resultRows);
strategyRows = summary.by_selected_strategy;

fid = fopen(filePath, 'w');
if fid < 0
    error('scenario_library_experiment:FileOpenFailed', ...
        'Cannot open strategy_counts.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'selected_strategy,count\n');
for i = 1:numel(strategyRows)
    fprintf(fid, '%s,%d\n', csv_text(strategyRows(i).selected_strategy), ...
        strategyRows(i).count);
end
end

function write_summary_json(filePath, experimentConfig, outputDir, ...
    scenarioRows, resultRows, librarySummaries)
summary = struct();
summary.experiment_name = 'order_cancellation_scenario_library';
summary.datasets = experimentConfig.datasets;
summary.cancel_policy = experimentConfig.cancel_policy;
summary.time_windows = experimentConfig.time_windows;
summary.job_categories = experimentConfig.job_categories;
summary.seeds = experimentConfig.seeds;
summary.output_dir = outputDir;
summary.output_files = { ...
    'scenario_library.csv', ...
    'seed_results.csv', ...
    'scenario_summary.csv', ...
    'category_summary.csv', ...
    'strategy_counts.csv', ...
    'summary.json', ...
    'experiment_notes.md'};
summary.scenario_count = numel(scenarioRows);
summary.run_count = numel(resultRows);
summary.library_summaries = librarySummaries;
summary.scope = struct();
summary.scope.scenario_library = true;
summary.scope.formal_experiment = false;
summary.scope.machine_failure = false;
summary.scope.new_order_insertion = false;
summary.scope.reinforcement_learning = false;
summary.scope.global_optimality_proof = false;

write_text(filePath, jsonencode(summary));
end

function write_experiment_notes(filePath, experimentConfig, scenarioRows, ...
    resultRows)
lines = {
    '# Stage G Scenario Library Experiment Notes'
    ''
    'Generated by `scripts/run_order_cancellation_scenario_library_experiment.m`.'
    ''
    '## Scope'
    ''
    sprintf('- Dataset count: `%d`', numel(experimentConfig.datasets))
    sprintf('- Scenario count: `%d`', numel(scenarioRows))
    sprintf('- Run count: `%d`', numel(resultRows))
    sprintf('- Cancellation policy: `%s`', experimentConfig.cancel_policy)
    ''
    '## Interpretation Boundaries'
    ''
    '- This is a stage G scenario-library experiment, not a final large-scale conclusion.'
    '- Machine failure is out of scope.'
    '- New order insertion is out of scope.'
    '- Reinforcement learning is out of scope.'
    '- Global optimality proof is out of scope.'
    ''
    '## Next Step'
    ''
    ['Review `scenario_summary.csv`, `category_summary.csv`, ', ...
    '`strategy_counts.csv`, and constraint-check fields before drawing ', ...
    'stage G conclusions.']
};
write_text(filePath, strjoin(lines, newline));
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
        continue
    elseif startsWith(line, 'time_windows:')
        section = 'time_windows';
        continue
    elseif startsWith(line, 'job_categories:')
        section = 'job_categories';
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

    if strcmp(section, 'time_windows') && startsWith(line, ...
            'cancel_time_ratio:')
        currentTimeWindow.cancel_time_ratio = str2double(strtrim( ...
            extractAfter(line, 'cancel_time_ratio:')));
        continue
    end

    if startsWith(line, 'cancel_policy:')
        config.cancel_policy = strtrim(extractAfter(line, 'cancel_policy:'));
        section = '';
    elseif startsWith(line, 'seeds:')
        config.seeds = parse_numeric_list(strtrim(extractAfter(line, ...
            'seeds:')));
        section = '';
    elseif startsWith(line, 'output_base_dir:')
        config.output_base_dir = strtrim(extractAfter(line, ...
            'output_base_dir:'));
        section = '';
    end
end

if inTimeWindow
    config.time_windows(end + 1) = currentTimeWindow;
end
end

function lines = read_text_lines(filePath)
fid = fopen(filePath, 'r');
if fid < 0
    error('scenario_library_experiment:FileOpenFailed', ...
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

function row = make_scenario_row(scenario)
row = empty_scenario_row();
row.scenario_id = scenario.scenario_id;
row.dataset = scenario.dataset;
row.seed = scenario.seed;
row.time_window = scenario.time_window;
row.job_category = scenario.job_category;
row.cancel_job_id = scenario.cancel.job_id;
row.cancel_time = scenario.cancel.cancel_time;
row.cancel_policy = scenario.cancel.policy;
row.cancel_time_ratio = scenario.cancel_time_ratio;
row.notes = join_notes(scenario.notes);
end

function row = make_result_row(result, scenario)
row = empty_result_row();
row.scenario_id = scenario.scenario_id;
row.dataset = scenario.dataset;
row.time_window = scenario.time_window;
row.job_category = scenario.job_category;
row.seed = scenario.seed;
row.cancel_job_id = scenario.cancel.job_id;
row.cancel_time = scenario.cancel.cancel_time;
row.cancel_policy = scenario.cancel.policy;
row.cancel_time_ratio = scenario.cancel_time_ratio;

fieldNames = fieldnames(row);
for i = 1:numel(fieldNames)
    fieldName = fieldNames{i};
    if isfield(result, fieldName)
        row.(fieldName) = result.(fieldName);
    end
end
if isfield(result, 'error_message')
    row.error_message = result.error_message;
end
end

function row = empty_scenario_row()
row = struct();
row.scenario_id = '';
row.dataset = '';
row.seed = NaN;
row.time_window = '';
row.job_category = '';
row.cancel_job_id = NaN;
row.cancel_time = NaN;
row.cancel_policy = '';
row.cancel_time_ratio = NaN;
row.notes = '';
end

function row = empty_result_row()
row = struct();
row.scenario_id = '';
row.dataset = '';
row.time_window = '';
row.job_category = '';
row.seed = NaN;
row.cancel_job_id = NaN;
row.cancel_time = NaN;
row.cancel_policy = '';
row.cancel_time_ratio = NaN;
row.local_candidate_isFeasible = false;
row.complete_candidate_isFeasible = false;
row.local_machine_check_isFeasible = false;
row.local_agv_check_isFeasible = false;
row.local_job_sequence_check_isFeasible = false;
row.complete_machine_check_isFeasible = false;
row.complete_agv_check_isFeasible = false;
row.complete_job_sequence_check_isFeasible = false;
row.complete_frozen_check_isFeasible = false;
row.complete_cancelled_exclusion_check_isFeasible = false;
row.local_isFeasible = false;
row.complete_isFeasible = false;
row.local_Cmax_delta = NaN;
row.complete_Cmax_delta = NaN;
row.local_SD = NaN;
row.complete_SD = NaN;
row.local_TD = NaN;
row.complete_TD = NaN;
row.local_energy_delta = NaN;
row.complete_energy_delta = NaN;
row.local_Y = NaN;
row.complete_Y = NaN;
row.selected_strategy = '';
row.selected_reason = '';
row.selected_Y = NaN;
row.local_error_count = 0;
row.complete_error_count = 0;
row.error_message = '';
end

function value = join_notes(notes)
if isempty(notes)
    value = '';
elseif iscell(notes)
    value = strjoin(notes, '; ');
else
    value = char(string(notes));
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
    error('scenario_library_experiment:FileOpenFailed', ...
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
