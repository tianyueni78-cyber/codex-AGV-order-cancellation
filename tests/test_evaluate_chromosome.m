clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'raw_code', 'NSGA-II'));

rng(42);

beforeFiles = dir(projectRoot);
beforeNames = sort({beforeFiles.name});

problem = read_fjsp(fullfile(projectRoot, 'data_sample', 'Mk01.fjs'));
machineData = read_machine_data( ...
    fullfile(projectRoot, 'data_sample', '机器数据.xlsx'), ...
    problem.machineNum);
agvData = read_agv_data(fullfile(projectRoot, 'data_sample', 'AGV数据.xlsx'));

config = struct();
config.AGVEG_MAX = 100;
config.eChargeSpeed = 20;

distance_matrix = machineData.distance_matrix;
AGVSpeed = agvData.AGVSpeed;
AGVEnergy = agvData.AGVEnergy;
distance_MAX = max([max(distance_matrix.machine_to_machine(:)), ...
    max(distance_matrix.load_to_machine), ...
    max(distance_matrix.machine_to_unload), ...
    distance_matrix.load_to_unload]);
config.AGVEG_MIN = distance_MAX / AGVSpeed(end) * ...
    (AGVEnergy.free(end) + AGVEnergy.load(end)) + 1e-6;

pop = 1;
speedNum = length(agvData.AGVSpeed);
chromSet = init(pop, problem.jobNum, problem.operaNumVec, ...
    problem.candidateMachine, agvData.AGVNum, speedNum);
chrom = chromSet(1, :);

result = evaluate_chromosome(chrom, problem, machineData, agvData, config);

assert(isfield(result, 'makespan'), 'result.makespan is missing.');
assert(isfield(result, 'totalEnergy'), 'result.totalEnergy is missing.');
assert(isfield(result, 'machineTable'), 'result.machineTable is missing.');
assert(isfield(result, 'AGVTable'), 'result.AGVTable is missing.');
assert(~isempty(result.makespan) && isfinite(result.makespan), ...
    'result.makespan is empty or not finite.');
assert(~isempty(result.totalEnergy) && isfinite(result.totalEnergy), ...
    'result.totalEnergy is empty or not finite.');

afterFiles = dir(projectRoot);
afterNames = sort({afterFiles.name});
assert(isequal(beforeNames, afterNames), ...
    'test_evaluate_chromosome created or removed files in the project root.');

fprintf('test_evaluate_chromosome passed: makespan=%.6f, totalEnergy=%.6f\n', ...
    result.makespan, result.totalEnergy);
