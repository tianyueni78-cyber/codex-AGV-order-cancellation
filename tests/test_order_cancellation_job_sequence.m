clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = struct();
problem.jobNum = 3;
problem.operaNumVec = [2, 2, 2];
cancel = create_order_cancellation_event(2, 10);

machineTable = make_feasible_machine_table();
[isFeasible, report] = check_job_operation_sequence( ...
    problem, machineTable, cancel);
assert(isFeasible, strjoin(report.errors, newline));

machineTable = make_feasible_machine_table();
machineTable{1}(2).start = 4;
[isFeasible, report] = check_job_operation_sequence( ...
    problem, machineTable, cancel);
assert(~isFeasible, ...
    'Later operation should not start before earlier operation completes.');
assert_has_error(report, 'starts before operation');

machineTable = make_feasible_machine_table();
machineTable{1}(2).end = 4;
[isFeasible, report] = check_job_operation_sequence( ...
    problem, machineTable, cancel);
assert(~isFeasible, ...
    'Later operation should not complete before earlier operation.');
assert_has_error(report, 'completes before operation');

machineTable = make_feasible_machine_table();
machineTable{1}(2).opera = 1;
[isFeasible, report] = check_job_operation_sequence( ...
    problem, machineTable, cancel);
assert(~isFeasible, 'Duplicate operation ids should be rejected.');
assert_has_error(report, 'duplicate operation ids');

machineTable = make_cancelled_job_history_only_table();
[isFeasible, report] = check_job_operation_sequence( ...
    problem, machineTable, cancel);
assert(isFeasible, ...
    ['Deleted unfinished operations of the cancelled job should not be ', ...
    'required.', newline, strjoin(report.errors, newline)]);

fprintf('test_order_cancellation_job_sequence passed\n');

function machineTable = make_feasible_machine_table()
machineTable = cell(1, 2);

machineTable{1} = [
    make_block(0, 5, 1, 1)
    make_block(5, 9, 1, 2)
    make_block(9, inf, 0, 0)
];

machineTable{2} = [
    make_block(0, 3, 2, 1)
    make_block(12, 15, 2, 2)
    make_block(3, 8, 3, 1)
    make_block(8, 11, 3, 2)
    make_block(15, inf, 0, 0)
];
end

function machineTable = make_cancelled_job_history_only_table()
machineTable = cell(1, 2);

machineTable{1} = [
    make_block(0, 5, 1, 1)
    make_block(5, 9, 1, 2)
    make_block(9, inf, 0, 0)
];

machineTable{2} = [
    make_block(0, 3, 2, 1)
    make_block(3, 8, 3, 1)
    make_block(8, 11, 3, 2)
    make_block(11, inf, 0, 0)
];
end

function block = make_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end

function assert_has_error(report, expectedMessage)
joinedErrors = strjoin(report.errors, newline);
assert(~isempty(strfind(joinedErrors, expectedMessage)), ...
    ['Expected error containing: ', expectedMessage, newline, ...
    'Actual errors:', newline, joinedErrors]);
end
