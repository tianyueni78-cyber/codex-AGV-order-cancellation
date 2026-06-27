% Random order cancellation batch acceptance.
% Local edit points:
%   seeds = 1:30;
%   cancelTimes = [5, 9, 13];
%   datasets = {'data_sample/Mk01.fjs'};
%
% Command-line override example:
% matlab -batch "cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation'); seeds=1:3; cancelTimes=[5 9]; run('scripts/run_random_order_cancellation_batch.m')"

clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

if ~exist('seeds', 'var')
    seeds = 1:30;
end
if ~exist('cancelTimes', 'var')
    cancelTimes = [5, 9, 13];
end
if ~exist('datasets', 'var')
    datasets = {
        'raw_code/fjsp/Brandimarte_Data/Mk01.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk02.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk03.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk04.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk05.fjs'
    };
end
if ~exist('strategyPolicies', 'var')
    strategyPolicies = {'auto_selection'};
end
if ~exist('baseline_mode', 'var')
    baseline_mode = 'instance_decoded';
end

outputDir = make_output_dir(projectRoot);
outputCsv = fullfile(outputDir, 'batch_random_order_cancellation.csv');
rows = repmat(empty_row(), 1, 0);

for datasetIdx = 1:numel(datasets)
    dataset = datasets{datasetIdx};
    for policyIdx = 1:numel(strategyPolicies)
        strategyPolicy = strategyPolicies{policyIdx};
        try
            datasetState = load_dataset_state(projectRoot, dataset, ...
                baseline_mode);
        catch err
            rows = append_dataset_error_rows( ...
                rows, dataset, seeds, cancelTimes, strategyPolicy, ...
                err.message);
            continue
        end

        for timeIdx = 1:numel(cancelTimes)
            cancelTime = cancelTimes(timeIdx);
            for seedIdx = 1:numel(seeds)
                seed = seeds(seedIdx);
                rows(end + 1) = run_one_random_case( ...
                    datasetState, dataset, seed, cancelTime, ...
                    strategyPolicy);
            end
        end
    end
end

write_rows_csv(outputCsv, rows);

fprintf('random order cancellation batch\n');
fprintf('dataset_count: %d\n', numel(datasets));
fprintf('seed_count: %d\n', numel(seeds));
fprintf('cancel_time_count: %d\n', numel(cancelTimes));
fprintf('strategy_policy_count: %d\n', numel(strategyPolicies));
fprintf('baseline_mode: %s\n', baseline_mode);
fprintf('row_count: %d\n', numel(rows));
fprintf('output_csv: %s\n', outputCsv);

function datasetState = load_dataset_state(projectRoot, dataset, baseline_mode)
datasetPath = fullfile(projectRoot, dataset);
problem = read_fjsp(datasetPath);
if strcmp(baseline_mode, 'sample')
    machineData = build_sample_machine_data(problem.machineNum);
    agvData = build_sample_agv_data();
    baselineSchedule = build_sample_schedule(problem.machineNum);
    decodeReport = struct();
elseif strcmp(baseline_mode, 'instance_decoded')
    baselineState = build_instance_driven_baseline_state(problem);
    machineData = baselineState.machineData;
    agvData = baselineState.agvData;
    baselineSchedule = baselineState.baselineSchedule;
    decodeReport = baselineState.decodeReport;
else
    error('random_order_cancellation_batch:InvalidBaselineMode', ...
        'Unsupported baseline_mode: %s', baseline_mode);
end

[baselineMetrics, baselineReport] = evaluate_candidate_cmax( ...
    baselineSchedule, baselineSchedule);
if ~baselineMetrics.isFeasible
    error('random_order_cancellation_batch:InvalidBaselineCmax', ...
        strjoin(baselineReport.errors, newline));
end

datasetState = struct();
datasetState.problem = problem;
datasetState.machineData = machineData;
datasetState.agvData = agvData;
datasetState.baselineSchedule = baselineSchedule;
datasetState.baselineCmax = baselineMetrics.Cmax;
datasetState.baselineMode = baseline_mode;
datasetState.decodeReport = decodeReport;
end

function row = run_one_random_case( ...
    datasetState, dataset, seed, cancelTime, strategyPolicy)
row = empty_row();
row.dataset = dataset;
row.seed = seed;
row.cancel_time = cancelTime;
row.strategy_policy = strategyPolicy;

try
    if cancelTime < 0 || cancelTime >= datasetState.baselineCmax
        error('random_order_cancellation_batch:InvalidCancelTime', ...
            'cancel_time must be >= 0 and < baseline Cmax %.6f.', ...
            datasetState.baselineCmax);
    end

    scenarioConfig = make_scenario_config(dataset, seed, cancelTime, ...
        datasetState.baselineCmax);
    [scenarios, ~] = build_order_cancellation_scenarios( ...
        datasetState.problem, datasetState.baselineSchedule, ...
        scenarioConfig);
    if isempty(scenarios)
        error('random_order_cancellation_batch:NoCancellableOrder', ...
            'No cancellable order exists at cancel_time %.6f.', ...
            cancelTime);
    end

    scenario = scenarios(1);
    runConfig = struct();
    runConfig.strategy_policy = strategyPolicy;
    result = run_order_cancellation_library_scenario( ...
        datasetState.problem, datasetState.machineData, ...
        datasetState.agvData, datasetState.baselineSchedule, ...
        scenario, runConfig);
    row = fill_success_row(row, result);
    if isfield(result, 'error_message') && ~isempty(result.error_message)
        row.error_message = result.error_message;
    end
catch err
    row.error_message = err.message;
end
end

function config = make_scenario_config(dataset, seed, cancelTime, baselineCmax)
config = struct();
config.datasets = {dataset};
config.cancel_policy = 'cancel_unstarted_operations_only';
config.time_windows = struct();
config.time_windows.name = sprintf('time_%.6g', cancelTime);
config.time_windows.cancel_time_ratio = cancelTime / baselineCmax;
config.job_categories = {'random'};
config.seeds = seed;
end

function baselineState = build_instance_driven_baseline_state(problem)
machineData = build_sample_machine_data(problem.machineNum);
agvData = build_sample_agv_data();
decodeConfig = build_baseline_decode_config(problem, agvData);
chrom = build_deterministic_baseline_chromosome(problem, agvData);
[baselineSchedule, decodeReport] = decode_chromosome_independent( ...
    chrom, problem, machineData, agvData, decodeConfig);

if ~isfield(decodeReport, 'isValid') || ~decodeReport.isValid
    if isfield(decodeReport, 'errors') && ~isempty(decodeReport.errors)
        error('random_order_cancellation_batch:BaselineDecodeFailed', ...
            strjoin(decodeReport.errors, newline));
    end
    error('random_order_cancellation_batch:BaselineDecodeFailed', ...
        'Instance-driven baseline decoding failed.');
end

baselineState = struct();
baselineState.baselineSchedule = baselineSchedule;
baselineState.machineData = machineData;
baselineState.agvData = agvData;
baselineState.decodeReport = decodeReport;
baselineState.baselineMode = 'instance_decoded';
end

function decodeConfig = build_baseline_decode_config(problem, agvData)
decodeConfig = struct();
decodeConfig.AGVEG_MAX = 100;
decodeConfig.AGVEG_MIN = 1;
decodeConfig.eChargeSpeed = 20;
decodeConfig.machineTable = build_decode_machine_table(problem.machineNum);
decodeConfig.AGVTable = build_decode_agv_table(agvData.AGVNum);
end

function chrom = build_deterministic_baseline_chromosome(problem, agvData)
operaNum = sum(problem.operaNumVec);
OS = build_os_sequence(problem);
MS = build_first_machine_selection(problem);
AS = mod(0:(operaNum - 1), agvData.AGVNum) + 1;
SS = ones(1, 2 * operaNum);
chrom = [OS, MS, AS, SS];
end

function OS = build_os_sequence(problem)
OS = zeros(1, sum(problem.operaNumVec));
pos = 1;
for jobIdx = 1:problem.jobNum
    for operaIdx = 1:problem.operaNumVec(jobIdx)
        OS(pos) = jobIdx;
        pos = pos + 1;
    end
end
end

function MS = build_first_machine_selection(problem)
MS = zeros(1, sum(problem.operaNumVec));
pos = 1;
for jobIdx = 1:problem.jobNum
    for operaIdx = 1:problem.operaNumVec(jobIdx)
        candidates = problem.candidateMachine{jobIdx, operaIdx};
        if isempty(candidates)
            error('random_order_cancellation_batch:MissingCandidateMachine', ...
                'candidateMachine{%d,%d} is empty.', jobIdx, operaIdx);
        end
        MS(pos) = 1;
        pos = pos + 1;
    end
end
end

function machineTable = build_decode_machine_table(machineNum)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = make_machine_block(0, inf, 0, 0);
end
end

function AGVTable = build_decode_agv_table(agvNum)
AGVTable = cell(1, agvNum);
for agvIdx = 1:agvNum
    AGVTable{agvIdx} = [
        make_agv_block(0, 0, 0, 0, -1, -1, 0)
        make_agv_block(0, inf, 0, 0, -1, -1, 0)
    ];
end
end

function row = fill_success_row(row, result)
row.canceled_order_id = result.cancel_job_id;
row.selected_strategy = result.selected_strategy;
if isfield(result, 'run_through')
    row.run_through = logical(result.run_through);
else
    row.run_through = result.local_candidate_isFeasible || ...
        result.complete_candidate_isFeasible;
end
if isfield(result, 'feasible')
    row.feasible = logical(result.feasible);
else
    row.feasible = result.local_isFeasible || result.complete_isFeasible;
end

switch result.selected_strategy
    case 'local_repair'
        row.Cmax_delta = result.local_Cmax_delta;
        row.SD = result.local_SD;
        row.TD = result.local_TD;
        row.Y = result.local_Y;
    case 'complete_rescheduling'
        row.Cmax_delta = result.complete_Cmax_delta;
        row.SD = result.complete_SD;
        row.TD = result.complete_TD;
        row.Y = result.complete_Y;
end
end

function rows = append_dataset_error_rows(rows, dataset, seeds, cancelTimes, ...
    strategyPolicy, message)
for timeIdx = 1:numel(cancelTimes)
    for seedIdx = 1:numel(seeds)
        row = empty_row();
        row.dataset = dataset;
        row.seed = seeds(seedIdx);
        row.cancel_time = cancelTimes(timeIdx);
        row.strategy_policy = strategyPolicy;
        row.error_message = message;
        rows(end + 1) = row;
    end
end
end

function outputDir = make_output_dir(projectRoot)
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
outputDir = fullfile(projectRoot, 'outputs', ...
    'batch_random_order_cancellation', timestamp);
suffix = 1;
while exist(outputDir, 'dir')
    outputDir = fullfile(projectRoot, 'outputs', ...
        'batch_random_order_cancellation', ...
        sprintf('%s_%02d', timestamp, suffix));
    suffix = suffix + 1;
end
mkdir(outputDir);
end

function write_rows_csv(filePath, rows)
fid = fopen(filePath, 'w');
if fid < 0
    error('random_order_cancellation_batch:FileOpenFailed', ...
        'Cannot open CSV for writing: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['dataset,seed,cancel_time,canceled_order_id,', ...
    'strategy_policy,selected_strategy,run_through,feasible,', ...
    'Cmax_delta,SD,TD,Y,error_message\n']);
for i = 1:numel(rows)
    row = rows(i);
    fprintf(fid, '%s,%d,%.6f,%g,%s,%s,%d,%d,%.6f,%.6f,%.6f,%.6f,%s\n', ...
        csv_text(row.dataset), row.seed, row.cancel_time, ...
        row.canceled_order_id, csv_text(row.strategy_policy), ...
        csv_text(row.selected_strategy), ...
        row.run_through, row.feasible, row.Cmax_delta, row.SD, row.TD, ...
        row.Y, csv_text(row.error_message));
end
end

function value = csv_text(value)
value = char(string(value));
value = strrep(value, '"', '""');
value = ['"', value, '"'];
end

function row = empty_row()
row = struct();
row.dataset = '';
row.seed = NaN;
row.cancel_time = NaN;
row.canceled_order_id = NaN;
row.strategy_policy = '';
row.selected_strategy = '';
row.run_through = false;
row.feasible = false;
row.Cmax_delta = NaN;
row.SD = NaN;
row.TD = NaN;
row.Y = NaN;
row.error_message = '';
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
