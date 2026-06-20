clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

baselineSchedule = make_baseline_schedule();
machineData = make_machine_data();
agvData = make_agv_data();
cancel = struct('job_id', 2);
config = make_config();

localCandidate = make_local_repair_candidate();
evaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, localCandidate, cancel, machineData, agvData, ...
    config, 'local_repair');
assert(evaluation.metrics.isFeasible, ...
    strjoin(evaluation.report.errors, newline));
assert(strcmp(evaluation.strategyName, 'local_repair'), ...
    'Evaluation should record strategyName.');
assert(evaluation.metrics.Cmax_delta == 1, ...
    'Cmax_delta mismatch.');
assert(evaluation.metrics.SD == 1, ...
    'SD mismatch.');
assert(evaluation.metrics.TD == 1, ...
    'TD mismatch.');
assert(evaluation.metrics.energy_delta == -15.5, ...
    'energy_delta mismatch.');
expectedY = 0.25 * 0.1 + 0.25 * 0.1 + 0.25 * 0.1 + 0.25 * 0.1125;
assert(abs(evaluation.metrics.Y - expectedY) < 1e-12, ...
    'Y mismatch.');

completeCandidate = make_complete_rescheduling_candidate();
evaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, completeCandidate, cancel, machineData, agvData, ...
    config, 'complete_rescheduling');
assert(evaluation.metrics.isFeasible, ...
    strjoin(evaluation.report.errors, newline));
assert(strcmp(evaluation.strategyName, 'complete_rescheduling'), ...
    'Complete rescheduling strategyName mismatch.');
assert(evaluation.metrics.Cmax_delta == 3, ...
    'Complete rescheduling Cmax_delta mismatch.');

infeasibleCandidate = localCandidate;
infeasibleCandidate.isFeasible = false;
evaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, infeasibleCandidate, cancel, machineData, agvData, ...
    config, 'local_repair');
assert(~evaluation.metrics.isFeasible, ...
    'Infeasible candidate should not participate in evaluation.');
assert(any(strcmp(evaluation.report.rejectedReasons, ...
    'candidate_infeasible')), ...
    'Infeasible candidate should record rejected reason.');

badConfig = config;
badConfig.weights = rmfield(badConfig.weights, 'TD');
evaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, localCandidate, cancel, machineData, agvData, ...
    badConfig, 'local_repair');
assert(~evaluation.metrics.isFeasible, ...
    'Missing Y weight should reject candidate evaluation.');
assert(any(strcmp(evaluation.report.rejectedReasons, ...
    'y_evaluation_failed')), ...
    'Missing Y config should record y_evaluation_failed.');

fprintf('test_order_cancellation_candidate_evaluation passed\n');

function config = make_config()
config = struct();
config.weights = struct();
config.weights.Cmax_delta = 0.25;
config.weights.SD = 0.25;
config.weights.TD = 0.25;
config.weights.energy_delta = 0.25;
config.normalization = struct();
config.normalization.Cmax_delta = make_bounds(0, 10);
config.normalization.SD = make_bounds(0, 10);
config.normalization.TD = make_bounds(0, 10);
config.normalization.energy_delta = make_bounds(-20, 20);
end

function bounds = make_bounds(minValue, maxValue)
bounds = struct();
bounds.min = minValue;
bounds.max = maxValue;
end

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
    make_machine_block(0, 5, 1, 1)
    make_machine_block(5, 9, 1, 2)
    make_machine_block(9, inf, 0, 0)
];
schedule.machineTable{2} = [
    make_machine_block(0, 4, 2, 1)
    make_machine_block(4, 8, 3, 1)
    make_machine_block(8, inf, 0, 0)
];
schedule.AGVTable = cell(1, 2);
schedule.AGVTable{1} = [
    make_agv_block(0, 2, 1, 1)
    make_agv_block(5, 7, 1, 2)
    make_agv_block(7, inf, 0, 0)
];
schedule.AGVTable{2} = [
    make_agv_block(0, 3, 2, 1)
    make_agv_block(4, 6, 3, 1)
    make_agv_block(6, inf, 0, 0)
];
end

function candidate = make_local_repair_candidate()
candidate = struct();
candidate.isFeasible = true;
candidate.machineTable = cell(1, 2);
candidate.machineTable{1} = [
    make_machine_block(0, 5, 1, 1)
    make_machine_block(5, 6, 0, 0)
    make_machine_block(6, 10, 1, 2)
    make_machine_block(10, inf, 0, 0)
];
candidate.machineTable{2} = [
    make_machine_block(4, 8, 3, 1)
    make_machine_block(8, inf, 0, 0)
];
candidate.AGVTable = cell(1, 2);
candidate.AGVTable{1} = [
    make_agv_block(0, 2, 1, 1)
    make_agv_block(6, 8, 1, 2)
    make_agv_block(8, inf, 0, 0)
];
candidate.AGVTable{2} = [
    make_agv_block(4, 6, 3, 1)
    make_agv_block(6, inf, 0, 0)
];
end

function candidate = make_complete_rescheduling_candidate()
candidate = make_local_repair_candidate();
candidate.machineTable{1}(3).start = 8;
candidate.machineTable{1}(3).end = 12;
candidate.AGVTable{1}(2).start = 8;
candidate.AGVTable{1}(2).end = 10;
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end

function block = make_agv_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.from_machine = -1;
block.to_machine = -1;
block.status = [];
block.load_status = -2;
block.charge = 0;
end
