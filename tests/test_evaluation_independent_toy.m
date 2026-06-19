clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'evaluation'));

decodedResult = struct();
decodedResult.jobCompleteUnLoad = [10, 15, 12];
decodedResult.machineTable = cell(1, 2);
decodedResult.machineTable{1} = [
    make_machine_block(0, 4, 1)
    make_machine_block(4, 6, 0)
    make_machine_block(6, inf, 0)
];
decodedResult.machineTable{2} = [
    make_machine_block(0, 3, 0)
    make_machine_block(3, 8, 2)
    make_machine_block(8, inf, 0)
];
decodedResult.AGVTable = cell(1, 2);
decodedResult.AGVTable{1} = [];
decodedResult.AGVTable{2} = [];
decodedResult.agvEGRecord = cell(1, 2);
decodedResult.agvEGRecord{1} = [0, 100; 1, 95; 2, 98; 3, 90];
decodedResult.agvEGRecord{2} = [0, 80; 1, 70];
decodedResult.agvChargeNum = [0, 1];

problem.jobNum = 3;
machineData.machineEnergy.work = [10, 20];
machineData.machineEnergy.free = [1, 2];
agvData.AGVNum = 2;
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;

result = evaluate_decoded_schedule(decodedResult, problem, machineData, agvData, config);

expectedMachineEnergy = 10 * 4 + 1 * 2 + 20 * 5 + 2 * 3;
expectedAgvEnergy = 5 + 8 + 10;
expectedMakespan = 15;
expectedTotalEnergy = expectedMachineEnergy + expectedAgvEnergy;

assert(result.makespan == expectedMakespan, 'Unexpected makespan.');
assert(result.machineEnergy == expectedMachineEnergy, 'Unexpected machine energy.');
assert(result.agvEnergy == expectedAgvEnergy, 'Unexpected AGV energy.');
assert(result.totalEnergy == expectedTotalEnergy, 'Unexpected total energy.');
assert(isequal(result.objectives, [expectedMakespan, expectedTotalEnergy]), ...
    'Unexpected objectives.');
assert(isfield(result, 'detail'), 'result.detail is missing.');

fprintf('test_evaluation_independent_toy passed: makespan=%.6f, totalEnergy=%.6f\n', ...
    result.makespan, result.totalEnergy);

function block = make_machine_block(startTime, endTime, job)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = job;
block.opera = 1;
end
