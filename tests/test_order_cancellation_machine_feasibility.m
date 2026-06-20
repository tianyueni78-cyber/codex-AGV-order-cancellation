clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

machineTable = make_feasible_machine_table();
[isFeasible, report] = check_machine_table_feasibility(machineTable);
assert(isFeasible, strjoin(report.errors, newline));
assert(report.checkedOperationCount == 3, ...
    'Only real operations should be checked.');

machineTable = make_feasible_machine_table();
machineTable{1}(3).start = 4;
[isFeasible, report] = check_machine_table_feasibility(machineTable);
assert(~isFeasible, 'Overlapping real operations should be rejected.');
assert_has_error(report, 'overlapping operations');

machineTable = make_feasible_machine_table();
machineTable{2}(1).end = -1;
[isFeasible, report] = check_machine_table_feasibility(machineTable);
assert(~isFeasible, 'end < start should be rejected.');
assert_has_error(report, 'end < start');

machineTable = make_feasible_machine_table();
machineTable{1}(1).start = 1;
machineTable{1}(1).end = 7;
[isFeasible, report] = check_machine_table_feasibility(machineTable);
assert(isFeasible, ...
    ['Idle blocks should not participate in conflict checks.', newline, ...
    strjoin(report.errors, newline)]);

fprintf('test_order_cancellation_machine_feasibility passed\n');

function machineTable = make_feasible_machine_table()
machineTable = cell(1, 2);

machineTable{1} = [
    make_block(0, 10, 0, 0)
    make_block(0, 5, 1, 1)
    make_block(5, 9, 2, 1)
    make_block(9, inf, 0, 0)
];

machineTable{2} = [
    make_block(0, 4, 3, 1)
    make_block(10, 9, 0, 0)
    make_block(4, inf, 0, 0)
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
