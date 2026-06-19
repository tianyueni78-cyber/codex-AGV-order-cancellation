clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'evaluation'));

schedule = struct();
schedule.jobCompleteUnLoad = [10, 15, 12];
makespan = compute_makespan_from_schedule(schedule);
assert(makespan == 15, 'makespan should be max(jobCompleteUnLoad).');

machineTable = cell(1, 2);
machineTable{1} = [
    make_machine_block(0, 4, 1)
    make_machine_block(4, 6, 0)
    make_machine_block(6, inf, 0)
];
machineTable{2} = [
    make_machine_block(0, 3, 0)
    make_machine_block(3, 8, 2)
    make_machine_block(8, inf, 0)
];
machineEnergy = struct();
machineEnergy.work = [10, 20];
machineEnergy.free = [1, 2];
machineEnergySum = compute_machine_energy(machineTable, machineEnergy);
expectedMachineEnergy = 10 * 4 + 1 * 2 + 20 * 5 + 2 * 3;
assert(machineEnergySum == expectedMachineEnergy, ...
    'machine energy does not match manual expectation.');

agvEGRecord = cell(1, 2);
agvEGRecord{1} = [
    0, 100
    1, 95
    2, 98
    3, 90
];
agvEGRecord{2} = [
    0, 80
    1, 70
];
agvEnergySum = compute_agv_energy(agvEGRecord);
expectedAgvEnergy = 5 + 8 + 10;
assert(agvEnergySum == expectedAgvEnergy, ...
    'AGV energy does not match manual expectation.');

objectives = build_objectives(makespan, machineEnergySum, agvEnergySum);
assert(isequal(objectives.objectives, ...
    [makespan, machineEnergySum + agvEnergySum]), ...
    'objective vector mismatch.');
assert(objectives.totalEnergy == machineEnergySum + agvEnergySum, ...
    'total energy mismatch.');

fprintf('test_evaluation_components passed: makespan=%.6f, totalEnergy=%.6f\n', ...
    objectives.makespan, objectives.totalEnergy);

function block = make_machine_block(startTime, endTime, job)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = job;
block.opera = 1;
end
