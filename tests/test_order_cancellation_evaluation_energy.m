clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

machineData = make_machine_data();
agvData = make_agv_data();
baselineSchedule = make_baseline_schedule();
candidateSchedule = make_candidate_schedule();

[metrics, report] = evaluate_candidate_energy( ...
    baselineSchedule, candidateSchedule, machineData, agvData);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(report.isFeasible, strjoin(report.errors, newline));
assert(metrics.baseline_machine_energy == 30, ...
    'Baseline machine energy should reuse machine energy evaluator.');
assert(metrics.machine_energy == 39, ...
    'Candidate machine energy should reuse machine energy evaluator.');
assert(metrics.baseline_agv_energy == 7, ...
    'Baseline AGV energy should use simplified AGVTable estimate.');
assert(metrics.agv_energy == 10, ...
    'Candidate AGV energy should use simplified AGVTable estimate.');
assert(metrics.baseline_energy == 37, ...
    'Baseline total energy mismatch.');
assert(metrics.energy == 49, ...
    'Candidate total energy mismatch.');
assert(metrics.energy_delta == 12, ...
    'energy_delta should be candidate energy minus baseline energy.');
assert(strcmp(metrics.agv_energy_source, 'AGVTable_simplified'), ...
    'AGV energy source should record simplified fallback.');

baselineWithRecord = baselineSchedule;
candidateWithRecord = candidateSchedule;
baselineWithRecord.agvEGRecord = make_agv_record();
candidateWithRecord.agvEGRecord = make_candidate_agv_record();
[metrics, report] = evaluate_candidate_energy( ...
    baselineWithRecord, candidateWithRecord, machineData, agvData);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(metrics.baseline_agv_energy == 6, ...
    'Baseline AGV energy should reuse agvEGRecord evaluator.');
assert(metrics.agv_energy == 9, ...
    'Candidate AGV energy should reuse agvEGRecord evaluator.');
assert(strcmp(metrics.agv_energy_source, 'agvEGRecord'), ...
    'AGV energy source should record agvEGRecord reuse.');

missingMachineEnergy = machineData;
missingMachineEnergy = rmfield(missingMachineEnergy, 'machineEnergy');
[metrics, report] = evaluate_candidate_energy( ...
    baselineSchedule, candidateSchedule, missingMachineEnergy, agvData);
assert(~metrics.isFeasible, ...
    'Missing machineEnergy should be rejected.');
assert(~isempty(report.errors), ...
    'Missing machineEnergy should record an error.');

fprintf('test_order_cancellation_evaluation_energy passed\n');

function machineData = make_machine_data()
machineData = struct();
machineData.machineEnergy = struct();
machineData.machineEnergy.work = [2, 3];
machineData.machineEnergy.free = [1, 1];
end

function agvData = make_agv_data()
agvData = struct();
agvData.AGVEnergy = struct();
agvData.AGVEnergy.free = 0.5;
agvData.AGVEnergy.load = 1.5;
end

function schedule = make_baseline_schedule()
schedule = struct();
schedule.machineTable = cell(1, 2);
schedule.machineTable{1} = [
    make_machine_block(0, 5, 1)
    make_machine_block(5, 7, 0)
    make_machine_block(7, inf, 0)
];
schedule.machineTable{2} = [
    make_machine_block(0, 6, 2)
    make_machine_block(6, inf, 0)
];
schedule.AGVTable = cell(1, 1);
schedule.AGVTable{1} = [
    make_agv_block(0, 4, 1)
    make_agv_block(4, 6, 0)
    make_agv_block(6, inf, 0)
];
end

function schedule = make_candidate_schedule()
schedule = struct();
schedule.machineTable = cell(1, 2);
schedule.machineTable{1} = [
    make_machine_block(0, 8, 1)
    make_machine_block(8, 10, 0)
    make_machine_block(10, inf, 0)
];
schedule.machineTable{2} = [
    make_machine_block(0, 7, 2)
    make_machine_block(7, inf, 0)
];
schedule.AGVTable = cell(1, 1);
schedule.AGVTable{1} = [
    make_agv_block(0, 6, 1)
    make_agv_block(6, 8, 0)
    make_agv_block(8, inf, 0)
];
end

function block = make_machine_block(startTime, endTime, jobId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = 1;
end

function block = make_agv_block(startTime, endTime, jobId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = 1;
block.from_machine = -1;
block.to_machine = -1;
block.status = [];
block.load_status = -2;
block.charge = 0;
end

function agvEGRecord = make_agv_record()
agvEGRecord = cell(1, 1);
agvEGRecord{1} = [
    0, 100
    1, 96
    2, 94
];
end

function agvEGRecord = make_candidate_agv_record()
agvEGRecord = cell(1, 1);
agvEGRecord{1} = [
    0, 100
    1, 95
    2, 91
];
end
