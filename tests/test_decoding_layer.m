clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'raw_code', 'NSGA-II'));

rng(42);

problem = read_fjsp(fullfile(projectRoot, 'data_sample', 'Mk01.fjs'));
machineData = read_machine_data( ...
    fullfile(projectRoot, 'data_sample', '机器数据.xlsx'), ...
    problem.machineNum);
agvData = read_agv_data(fullfile(projectRoot, 'data_sample', 'AGV数据.xlsx'));

[population, populationReport] = generate_initial_population(3, problem, agvData);
assert(populationReport.isValid, ...
    'Generated population did not pass encoding validation.');
chrom = population(1, :);

config = struct();
config.AGVEG_MAX = 100;
config.eChargeSpeed = 20;
config.AGVEG_MIN = compute_agv_energy_min( ...
    machineData.distance_matrix, agvData.AGVSpeed, agvData.AGVEnergy);
config.machineTable = create_initial_machine_table(problem.machineNum);
config.AGVTable = create_initial_agv_table(agvData.AGVNum);

[schedule, report] = decode_chromosome(chrom, problem, machineData, agvData, config);

assert(report.isValid, strjoin(report.errors, newline));
assert(strcmp(report.decodingStatus, 'decoded'), ...
    'Decoding status should be decoded.');

assert(isfield(schedule, 'machineTable'), 'schedule.machineTable is missing.');
assert(isfield(schedule, 'AGVTable'), 'schedule.AGVTable is missing.');
assert(isfield(schedule, 'jobCompleteUnLoad'), ...
    'schedule.jobCompleteUnLoad is missing.');
assert(isfield(schedule, 'agvEGRecord'), 'schedule.agvEGRecord is missing.');
assert(isfield(schedule, 'agvChargeNum'), 'schedule.agvChargeNum is missing.');
assert(isfield(schedule, 'parts'), 'schedule.parts is missing.');

assert(numel(schedule.machineTable) == problem.machineNum, ...
    'machineTable machine count mismatch.');
assert(numel(schedule.AGVTable) == agvData.AGVNum, ...
    'AGVTable AGV count mismatch.');
assert(numel(schedule.jobCompleteUnLoad) == problem.jobNum, ...
    'jobCompleteUnLoad job count mismatch.');
assert(numel(schedule.agvEGRecord) == agvData.AGVNum, ...
    'agvEGRecord AGV count mismatch.');
assert(numel(schedule.agvChargeNum) == agvData.AGVNum, ...
    'agvChargeNum AGV count mismatch.');

assert(schedule.dim == 5 * sum(problem.operaNumVec), ...
    'schedule.dim does not match 5 * sum(problem.operaNumVec).');
assert(schedule.operaNum == sum(problem.operaNumVec), ...
    'schedule.operaNum does not match sum(problem.operaNumVec).');

scheduledOperationCount = count_scheduled_operations(schedule.machineTable);
assert(scheduledOperationCount == sum(problem.operaNumVec), ...
    'Decoded schedule does not contain every operation exactly once.');

assert(all(schedule.jobCompleteUnLoad >= 0), ...
    'jobCompleteUnLoad contains negative values.');

[schedules, populationDecodeReport] = decode_population( ...
    population, problem, machineData, agvData, config);

assert(populationDecodeReport.isValid, ...
    'Decoded population report should be valid.');
assert(populationDecodeReport.successCount == size(population, 1), ...
    'Decoded population successCount mismatch.');
assert(populationDecodeReport.failureCount == 0, ...
    'Decoded population should not contain failures.');
assert(isempty(populationDecodeReport.failedIndexes), ...
    'Decoded population should not contain failed indexes.');
assert(numel(schedules) == size(population, 1), ...
    'Decoded schedules count mismatch.');

for i = 1:numel(schedules)
    assert(isstruct(schedules{i}), 'Each decoded schedule should be a struct.');
    assert(isfield(schedules{i}, 'machineTable'), ...
        'Decoded population schedule is missing machineTable.');
    assert(populationDecodeReport.chromosomes(i).isValid, ...
        strjoin(populationDecodeReport.chromosomes(i).errors, newline));
end

fprintf('test_decoding_layer passed: population=%d, operations=%d, AGVNum=%d\n', ...
    size(population, 1), scheduledOperationCount, agvData.AGVNum);

function machineTable = create_initial_machine_table(machineNum)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = struct( ...
        'start', 0, ...
        'end', inf, ...
        'job', 0, ...
        'opera', 0);
end
end

function AGVTable = create_initial_agv_table(AGVNum)
AGVTable = cell(1, AGVNum);
for agvIdx = 1:AGVNum
    AGVTable{agvIdx} = repmat(struct( ...
        'start', 0, ...
        'end', 0, ...
        'job', 0, ...
        'opera', 0, ...
        'from_machine', -1, ...
        'to_machine', -1, ...
        'status', 0), 1, 2);
    AGVTable{agvIdx}(2).end = inf;
end
end

function AGVEG_MIN = compute_agv_energy_min(distanceMatrix, AGVSpeed, AGVEnergy)
distanceMax = max([ ...
    max(distanceMatrix.machine_to_machine(:)), ...
    max(distanceMatrix.load_to_machine), ...
    max(distanceMatrix.machine_to_unload), ...
    distanceMatrix.load_to_unload]);
AGVEG_MIN = distanceMax / AGVSpeed(end) * ...
    (AGVEnergy.free(end) + AGVEnergy.load(end)) + 1e-6;
end

function operationCount = count_scheduled_operations(machineTable)
operationCount = 0;
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    if isempty(blocks)
        continue
    end
    jobs = [blocks.job];
    operationCount = operationCount + sum(jobs > 0);
end
end
