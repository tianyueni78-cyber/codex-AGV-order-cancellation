clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

baselineSchedule = make_baseline_schedule();
candidateSchedule = make_candidate_schedule();
cancel = struct('job_id', 2);

[metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateSchedule, cancel);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(report.isFeasible, strjoin(report.errors, newline));
assert(metrics.TD == 3, ...
    'TD should sum non-cancelled AGV task start-time changes.');
assert(report.checkedBaselineTaskCount == 3, ...
    'Cancelled job and idle blocks should not count in baseline TD.');
assert(report.checkedCandidateTaskCount == 3, ...
    'Cancelled job and idle blocks should not count in candidate TD.');

candidateWithFrozenUnchanged = candidateSchedule;
candidateWithFrozenUnchanged.AGVTable{1}(1).start = 0;
[metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateWithFrozenUnchanged, cancel);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(metrics.TD == 3, ...
    'Unchanged completed AGV tasks should contribute zero TD.');

candidateMissingTask = candidateSchedule;
candidateMissingTask.AGVTable{1}(2).job = 0;
candidateMissingTask.AGVTable{1}(2).opera = 0;
[metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateMissingTask, cancel);
assert(~metrics.isFeasible, ...
    'Missing non-cancelled AGV task should be rejected.');
assert(~isempty(report.errors), ...
    'Missing non-cancelled AGV task should record an error.');

candidateWithCancelledReturn = candidateSchedule;
candidateWithCancelledReturn.AGVTable{2}(end + 1) = ...
    make_agv_block(12, 14, 2, 2);
[metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateWithCancelledReturn, cancel);
assert(~metrics.isFeasible, ...
    'Returned cancelled AGV task should be rejected.');
assert(~isempty(report.errors), ...
    'Returned cancelled AGV task should record an error.');

candidateWithCompletedCancelledHistory = candidateSchedule;
candidateWithCompletedCancelledHistory.AGVTable{2}(end + 1) = ...
    make_agv_block(0, 3, 2, 1);
cancelWithTime = struct('job_id', 2, 'cancel_time', 10);
[metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateWithCompletedCancelledHistory, ...
    cancelWithTime);
assert(metrics.isFeasible, ...
    strjoin(report.errors, newline));
assert(metrics.TD == 3, ...
    'Completed cancelled-job AGV history should be allowed and excluded.');

candidateWithUnfinishedCancelledReturn = candidateSchedule;
candidateWithUnfinishedCancelledReturn.AGVTable{2}(end + 1) = ...
    make_agv_block(12, 14, 2, 2);
[metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateWithUnfinishedCancelledReturn, ...
    cancelWithTime);
assert(~metrics.isFeasible, ...
    'Unfinished cancelled-job AGV task should be rejected.');

candidateWithAuxiliaryAgvBlock = candidateSchedule;
candidateWithAuxiliaryAgvBlock.AGVTable{2}(end + 1) = ...
    make_agv_block(12, 14, 2, -1);
[metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateWithAuxiliaryAgvBlock, cancelWithTime);
assert(metrics.isFeasible, ...
    strjoin(report.errors, newline));
assert(metrics.TD == 3, ...
    'Auxiliary AGV blocks with operation_id <= 0 should be excluded.');

candidateExtraTask = candidateSchedule;
candidateExtraTask.AGVTable{2}(end + 1) = make_agv_block(14, 16, 4, 1);
[metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateExtraTask, cancel);
assert(~metrics.isFeasible, ...
    'Extra non-cancelled AGV task should be rejected.');
assert(~isempty(report.errors), ...
    'Extra non-cancelled AGV task should record an error.');

fprintf('test_order_cancellation_evaluation_td passed\n');

function schedule = make_baseline_schedule()
schedule = struct();
schedule.machineTable = {};
schedule.AGVTable = cell(1, 2);
schedule.AGVTable{1} = [
    make_agv_block(0, 2, 1, 1)
    make_agv_block(5, 7, 1, 2)
    make_agv_block(7, inf, 0, 0)
];
schedule.AGVTable{2} = [
    make_agv_block(0, 3, 2, 1)
    make_agv_block(4, 6, 3, 1)
    make_agv_block(8, 10, 2, 2)
    make_agv_block(10, inf, 0, 0)
];
end

function schedule = make_candidate_schedule()
schedule = struct();
schedule.machineTable = {};
schedule.AGVTable = cell(1, 2);
schedule.AGVTable{1} = [
    make_agv_block(0, 2, 1, 1)
    make_agv_block(7, 9, 1, 2)
    make_agv_block(9, inf, 0, 0)
];
schedule.AGVTable{2} = [
    make_agv_block(5, 7, 3, 1)
    make_agv_block(7, inf, 0, 0)
];
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
