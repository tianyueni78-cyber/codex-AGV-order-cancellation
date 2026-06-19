clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
rawAlgorithmDir = fullfile(projectRoot, 'raw_code', 'NSGA-II');
addpath(rawAlgorithmDir);
cleanupRawPath = onCleanup(@() remove_path_if_present(rawAlgorithmDir));

rng(42);

problem = read_fjsp(fullfile(projectRoot, 'data_sample', 'Mk01.fjs'));
machineData = load_sample_machine_data(projectRoot, problem.machineNum);
agvData = load_sample_agv_data(projectRoot);
config = make_evaluation_config(machineData, agvData);

chromSet = init(1, problem.jobNum, problem.operaNumVec, ...
    problem.candidateMachine, agvData.AGVNum, numel(agvData.AGVSpeed));
chrom = chromSet(1, :);

rawResult = evaluate_chromosome(chrom, problem, machineData, agvData, config);

machineEnergySum = compute_machine_energy( ...
    rawResult.machineTable, machineData.machineEnergy);
agvEnergySum = compute_agv_energy(rawResult.agvEGRecord);
rebuilt = build_objectives(rawResult.makespan, machineEnergySum, agvEnergySum);

assert_close(machineEnergySum, rawResult.machineEnergy, 'machineEnergy');
assert_close(agvEnergySum, rawResult.agvEnergy, 'agvEnergy');
assert_close(rebuilt.totalEnergy, rawResult.totalEnergy, 'totalEnergy');
assert_close(rebuilt.objectives(1), rawResult.objectives(1), 'objective makespan');
assert_close(rebuilt.objectives(2), rawResult.objectives(2), 'objective totalEnergy');

fprintf(['test_evaluation_components_compare_raw passed: ', ...
    'makespan=%.6f, machineEnergy=%.6f, agvEnergy=%.6f\n'], ...
    rawResult.makespan, machineEnergySum, agvEnergySum);

function config = make_evaluation_config(machineData, agvData)
config = struct();
config.AGVEG_MAX = 100;
config.eChargeSpeed = 20;

distanceMatrix = machineData.distance_matrix;
distanceMax = max([max(distanceMatrix.machine_to_machine(:)), ...
    max(distanceMatrix.load_to_machine), ...
    max(distanceMatrix.machine_to_unload), ...
    distanceMatrix.load_to_unload]);
config.AGVEG_MIN = distanceMax / agvData.AGVSpeed(end) * ...
    (agvData.AGVEnergy.free(end) + agvData.AGVEnergy.load(end)) + 1e-6;
end

function machineData = load_sample_machine_data(projectRoot, machineNum)
xlsxFiles = dir(fullfile(projectRoot, 'data_sample', '*.xlsx'));
for i = 1:numel(xlsxFiles)
    candidatePath = fullfile(xlsxFiles(i).folder, xlsxFiles(i).name);
    try
        candidateData = read_machine_data(candidatePath, machineNum);
        if isfield(candidateData, 'distance_matrix') && ...
                isfield(candidateData, 'machineEnergy')
            machineData = candidateData;
            return
        end
    catch
    end
end
error('test_evaluation_components_compare_raw:SampleMachineDataNotFound', ...
    'Could not find sample machine data in data_sample.');
end

function agvData = load_sample_agv_data(projectRoot)
xlsxFiles = dir(fullfile(projectRoot, 'data_sample', '*.xlsx'));
for i = 1:numel(xlsxFiles)
    candidatePath = fullfile(xlsxFiles(i).folder, xlsxFiles(i).name);
    try
        candidateData = read_agv_data(candidatePath);
        if isfield(candidateData, 'AGVNum') && ...
                isfield(candidateData, 'AGVSpeed') && ...
                isfield(candidateData, 'AGVEnergy')
            agvData = candidateData;
            return
        end
    catch
    end
end
error('test_evaluation_components_compare_raw:SampleAgvDataNotFound', ...
    'Could not find sample AGV data in data_sample.');
end

function assert_close(actual, expected, label)
tolerance = 1e-9;
assert(abs(actual - expected) <= tolerance, ...
    '%s mismatch: actual %.12f, expected %.12f.', label, actual, expected);
end

function remove_path_if_present(pathToRemove)
currentPath = strsplit(path, pathsep);
if any(strcmp(currentPath, pathToRemove))
    rmpath(pathToRemove);
end
end
