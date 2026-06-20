clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

baselineSchedule = make_baseline_schedule();
candidateSchedule = make_candidate_schedule();

[metrics, report] = evaluate_candidate_cmax( ...
    baselineSchedule, candidateSchedule);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(report.isFeasible, strjoin(report.errors, newline));
assert(metrics.baseline_Cmax == 11, ...
    'Baseline Cmax should be calculated from real operations.');
assert(metrics.Cmax == 14, ...
    'Candidate Cmax should be calculated from real operations.');
assert(metrics.Cmax_delta == 3, ...
    'Cmax_delta should be candidate Cmax minus baseline Cmax.');
assert(report.checkedBaselineOperationCount == 3, ...
    'Idle blocks must not count as baseline operations.');
assert(report.checkedCandidateOperationCount == 3, ...
    'Idle blocks must not count as candidate operations.');

candidateWithLongIdle = candidateSchedule;
candidateWithLongIdle.machineTable{1}(end).end = 1000;
[metrics, report] = evaluate_candidate_cmax( ...
    baselineSchedule, candidateWithLongIdle);
assert(metrics.isFeasible, strjoin(report.errors, newline));
assert(metrics.Cmax == 14, ...
    'Idle block end time must not affect candidate Cmax.');

missingMachineTable = struct();
[metrics, report] = evaluate_candidate_cmax( ...
    baselineSchedule, missingMachineTable);
assert(~metrics.isFeasible, ...
    'Candidate without machineTable should be rejected.');
assert(~isempty(report.errors), ...
    'Missing machineTable should record an error.');

invalidCandidate = candidateSchedule;
invalidCandidate.machineTable{1}(1).end = 3;
invalidCandidate.machineTable{1}(1).start = 5;
[metrics, report] = evaluate_candidate_cmax( ...
    baselineSchedule, invalidCandidate);
assert(~metrics.isFeasible, ...
    'Operation with end < start should be rejected.');
assert(~isempty(report.errors), ...
    'Invalid operation time should record an error.');

fprintf('test_order_cancellation_evaluation_cmax passed\n');

function schedule = make_baseline_schedule()
schedule = struct();
schedule.machineTable = cell(1, 2);
schedule.machineTable{1} = [
    make_machine_block(0, 5, 1, 1)
    make_machine_block(5, inf, 0, 0)
];
schedule.machineTable{2} = [
    make_machine_block(0, 7, 2, 1)
    make_machine_block(7, 11, 3, 1)
    make_machine_block(11, inf, 0, 0)
];
schedule.AGVTable = {};
end

function schedule = make_candidate_schedule()
schedule = struct();
schedule.machineTable = cell(1, 2);
schedule.machineTable{1} = [
    make_machine_block(0, 5, 1, 1)
    make_machine_block(5, 14, 1, 2)
    make_machine_block(14, inf, 0, 0)
];
schedule.machineTable{2} = [
    make_machine_block(0, 7, 2, 1)
    make_machine_block(7, inf, 0, 0)
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
