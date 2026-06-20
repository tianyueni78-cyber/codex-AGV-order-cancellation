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

config = make_config(-20, 20);
localCandidate = make_local_repair_candidate();
completeCandidate = make_complete_rescheduling_candidate();

[localEvaluation, completeEvaluation, selection] = evaluate_and_select( ...
    baselineSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, config);

assert(localEvaluation.metrics.isFeasible, ...
    strjoin(localEvaluation.report.errors, newline));
assert(completeEvaluation.metrics.isFeasible, ...
    strjoin(completeEvaluation.report.errors, newline));
assert_metrics_present(localEvaluation);
assert_metrics_present(completeEvaluation);
assert(selection.isSelected, 'Pipeline should select one strategy.');
assert(strcmp(selection.name, 'local_repair'), ...
    'Local repair should be selected when its Y is smaller.');
assert(strcmp(selection.reason, 'smaller_Y'), ...
    'Selection reason should record smaller_Y.');

config = make_config(-80, 20);
betterCompleteCandidate = make_better_complete_rescheduling_candidate();
[localEvaluation, completeEvaluation, selection] = evaluate_and_select( ...
    baselineSchedule, localCandidate, betterCompleteCandidate, cancel, ...
    machineData, agvData, config);

assert(localEvaluation.metrics.isFeasible, ...
    strjoin(localEvaluation.report.errors, newline));
assert(completeEvaluation.metrics.isFeasible, ...
    strjoin(completeEvaluation.report.errors, newline));
assert(selection.isSelected, 'Pipeline should select one strategy.');
assert(strcmp(selection.name, 'complete_rescheduling'), ...
    'Complete rescheduling should be selected when its Y is smaller.');
assert(strcmp(selection.reason, 'smaller_Y'), ...
    'Selection reason should record smaller_Y.');

infeasibleLocal = localCandidate;
infeasibleLocal.isFeasible = false;
[localEvaluation, completeEvaluation, selection] = evaluate_and_select( ...
    baselineSchedule, infeasibleLocal, completeCandidate, cancel, ...
    machineData, agvData, config);

assert(~localEvaluation.metrics.isFeasible, ...
    'Infeasible local candidate should be excluded from evaluation.');
assert(completeEvaluation.metrics.isFeasible, ...
    strjoin(completeEvaluation.report.errors, newline));
assert(selection.isSelected, ...
    'Pipeline should select the single feasible candidate.');
assert(strcmp(selection.name, 'complete_rescheduling'), ...
    'Complete rescheduling should be selected when local repair is infeasible.');
assert(strcmp(selection.reason, 'only_feasible_candidate'), ...
    'Selection should record only_feasible_candidate.');

fprintf('test_order_cancellation_evaluation_pipeline passed\n');

function [localEvaluation, completeEvaluation, selection] = evaluate_and_select( ...
    baselineSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, config)
localEvaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, localCandidate, cancel, machineData, agvData, ...
    config, 'local_repair');
completeEvaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, completeCandidate, cancel, machineData, agvData, ...
    config, 'complete_rescheduling');
selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);
end

function assert_metrics_present(evaluation)
requiredFields = {'Cmax_delta', 'SD', 'TD', 'energy', 'energy_delta', 'Y'};
for i = 1:numel(requiredFields)
    fieldName = requiredFields{i};
    assert(isfield(evaluation.metrics, fieldName), ...
        'Evaluation metrics missing required field.');
    assert(~isempty(evaluation.metrics.(fieldName)), ...
        'Evaluation metric should not be empty.');
end
end

function config = make_config(energyMin, energyMax)
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
config.normalization.energy_delta = make_bounds(energyMin, energyMax);
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

function candidate = make_better_complete_rescheduling_candidate()
candidate = struct();
candidate.isFeasible = true;
candidate.machineTable = cell(1, 2);
candidate.machineTable{1} = [
    make_machine_block(0, 5, 1, 1)
    make_machine_block(5, 9, 1, 2)
    make_machine_block(9, inf, 0, 0)
];
candidate.machineTable{2} = [
    make_machine_block(4, 8, 3, 1)
    make_machine_block(8, inf, 0, 0)
];
candidate.AGVTable = cell(1, 2);
candidate.AGVTable{1} = [
    make_agv_block(0, 2, 1, 1)
    make_agv_block(5, 7, 1, 2)
    make_agv_block(7, inf, 0, 0)
];
candidate.AGVTable{2} = [
    make_agv_block(4, 6, 3, 1)
    make_agv_block(6, inf, 0, 0)
];
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
