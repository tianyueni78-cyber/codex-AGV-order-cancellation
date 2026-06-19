clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'raw_code', 'NSGA-II'));

[problem, machineData, agvData, config, chrom] = make_compare_case();

rawResult = evaluate_chromosome(chrom, problem, machineData, agvData, config);

[decodedResult, decodeReport] = decode_chromosome_independent( ...
    chrom, problem, machineData, agvData, config);
assert(decodeReport.isValid, strjoin(decodeReport.errors, newline));

independentResult = evaluate_decoded_schedule( ...
    decodedResult, problem, machineData, agvData, config);

tolerance = 1e-9;
assert(abs(independentResult.makespan - rawResult.makespan) < tolerance, ...
    'Independent makespan differs from raw wrapper.');
assert(abs(independentResult.machineEnergy - rawResult.machineEnergy) < tolerance, ...
    'Independent machineEnergy differs from raw wrapper.');
assert(abs(independentResult.agvEnergy - rawResult.agvEnergy) < tolerance, ...
    'Independent agvEnergy differs from raw wrapper.');
assert(abs(independentResult.totalEnergy - rawResult.totalEnergy) < tolerance, ...
    'Independent totalEnergy differs from raw wrapper.');
assert(all(abs(independentResult.objectives - rawResult.objectives) < tolerance), ...
    'Independent objectives differ from raw wrapper.');

fprintf('test_evaluation_independent_compare_raw passed: makespan=%.6f, totalEnergy=%.6f\n', ...
    independentResult.makespan, independentResult.totalEnergy);

function [problem, machineData, agvData, config, chrom] = make_compare_case()
problem.jobNum = 2;
problem.machineNum = 3;
problem.operaNumVec = [2, 1];
problem.candidateMachine = cell(2, 2);
problem.candidateMachine{1, 1} = [1, 2];
problem.candidateMachine{1, 2} = [2];
problem.candidateMachine{2, 1} = [1, 3];
problem.jobInfo = cell(1, 2);
problem.jobInfo{1} = [5, 6, inf; inf, 4, inf];
problem.jobInfo{2} = [3, inf, 7];

machineData.distance_matrix.machine_to_machine = [0, 2, 3; 2, 0, 4; 3, 4, 0];
machineData.distance_matrix.load_to_machine = [1, 2, 3];
machineData.distance_matrix.machine_to_unload = [1, 2, 3];
machineData.distance_matrix.load_to_unload = 1;
machineData.machineEnergy.work = [10; 20; 30];
machineData.machineEnergy.free = [1; 2; 3];

agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5, 2.0];
agvData.AGVEnergy.free = [1.0, 1.2, 1.4];
agvData.AGVEnergy.load = [1.4, 1.6, 1.8];

config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;
config.machineTable = create_initial_machine_table(problem.machineNum);
config.AGVTable = create_initial_agv_table(agvData.AGVNum);

chrom = [[1, 2, 1], [2, 1, 1], [1, 2, 1], [1, 2, 1, 2, 1, 2]];
end

function machineTable = create_initial_machine_table(machineNum)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = struct('start', 0, 'end', inf, 'job', 0, 'opera', 0);
end
end

function AGVTable = create_initial_agv_table(AGVNum)
AGVTable = cell(1, AGVNum);
for agvIdx = 1:AGVNum
    AGVTable{agvIdx} = repmat(struct('start', 0, 'end', 0, ...
        'job', 0, 'opera', 0, 'from_machine', -1, ...
        'to_machine', -1, 'status', 0), 1, 2);
    AGVTable{agvIdx}(2).end = inf;
end
end
