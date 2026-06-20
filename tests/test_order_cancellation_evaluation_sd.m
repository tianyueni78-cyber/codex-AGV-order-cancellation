clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

baselineSchedule = make_baseline_schedule();
candidateSchedule = make_candidate_schedule();
cancel = struct('job_id', 2);

[metrics, report] = evaluate_candidate_sd( ...
    baselineSchedule, candidateSchedule, cancel);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(report.isFeasible, strjoin(report.errors, newline));
assert(metrics.SD == 3, ...
    'SD should sum non-cancelled operation start-time changes.');
assert(report.checkedBaselineOperationCount == 3, ...
    'Cancelled job and idle blocks should not count in baseline SD.');
assert(report.checkedCandidateOperationCount == 3, ...
    'Cancelled job and idle blocks should not count in candidate SD.');

candidateWithChangedCancelledJob = candidateSchedule;
candidateWithChangedCancelledJob.machineTable{2}(1).start = 100;
[metrics, report] = evaluate_candidate_sd( ...
    baselineSchedule, candidateWithChangedCancelledJob, cancel);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(metrics.SD == 3, ...
    'Cancelled job operations must not affect SD.');

candidateWithFrozenUnchanged = candidateSchedule;
candidateWithFrozenUnchanged.machineTable{1}(1).start = 0;
[metrics, report] = evaluate_candidate_sd( ...
    baselineSchedule, candidateWithFrozenUnchanged, cancel);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(metrics.SD == 3, ...
    'Unchanged completed operations should contribute zero SD.');

candidateMissingOperation = candidateSchedule;
candidateMissingOperation.machineTable{1}(2).job = 0;
candidateMissingOperation.machineTable{1}(2).opera = 0;
[metrics, report] = evaluate_candidate_sd( ...
    baselineSchedule, candidateMissingOperation, cancel);
assert(~metrics.isFeasible, ...
    'Missing non-cancelled operation should be rejected.');
assert(~isempty(report.errors), ...
    'Missing non-cancelled operation should record an error.');

candidateExtraOperation = candidateSchedule;
candidateExtraOperation.machineTable{2}(end + 1) = ...
    make_machine_block(12, 14, 4, 1);
[metrics, report] = evaluate_candidate_sd( ...
    baselineSchedule, candidateExtraOperation, cancel);
assert(~metrics.isFeasible, ...
    'Extra non-cancelled operation should be rejected.');
assert(~isempty(report.errors), ...
    'Extra non-cancelled operation should record an error.');

fprintf('test_order_cancellation_evaluation_sd passed\n');

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
schedule.AGVTable = {};
end

function schedule = make_candidate_schedule()
schedule = struct();
schedule.machineTable = cell(1, 2);
schedule.machineTable{1} = [
    make_machine_block(0, 5, 1, 1)
    make_machine_block(7, 11, 1, 2)
    make_machine_block(11, inf, 0, 0)
];
schedule.machineTable{2} = [
    make_machine_block(0, 4, 2, 1)
    make_machine_block(5, 9, 3, 1)
    make_machine_block(9, inf, 0, 0)
];
schedule.AGVTable = {};
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end
