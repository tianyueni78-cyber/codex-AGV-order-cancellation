clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

AGVTable = make_feasible_agv_table();
[isFeasible, report] = check_agv_table_feasibility(AGVTable);
assert(isFeasible, strjoin(report.errors, newline));
assert(report.checkedAgvTaskCount == 3, ...
    'Only real AGV transport tasks should be checked.');

AGVTable = make_feasible_agv_table();
AGVTable{1}(3).start = 4;
[isFeasible, report] = check_agv_table_feasibility(AGVTable);
assert(~isFeasible, 'Overlapping real AGV tasks should be rejected.');
assert_has_error(report, 'overlapping transport tasks');

AGVTable = make_feasible_agv_table();
AGVTable{2}(1).end = -1;
[isFeasible, report] = check_agv_table_feasibility(AGVTable);
assert(~isFeasible, 'end < start should be rejected.');
assert_has_error(report, 'end < start');

AGVTable = make_feasible_agv_table();
AGVTable{1}(1).start = 1;
AGVTable{1}(1).end = 7;
AGVTable{2}(2).start = 6;
AGVTable{2}(2).end = 8;
[isFeasible, report] = check_agv_table_feasibility(AGVTable);
assert(isFeasible, ...
    ['Idle or charging blocks should not participate in transport checks.', ...
    newline, strjoin(report.errors, newline)]);

fprintf('test_order_cancellation_agv_feasibility passed\n');

function AGVTable = make_feasible_agv_table()
AGVTable = cell(1, 2);

AGVTable{1} = [
    make_block(0, 10, 0, 0, 0)
    make_block(0, 5, 1, 1, -2)
    make_block(5, 9, 2, 1, -2)
    make_block(9, inf, 0, 0, 0)
];

AGVTable{2} = [
    make_block(0, 4, 3, 1, -2)
    make_block(10, 9, 0, 0, 1)
    make_block(4, inf, 0, 0, 0)
];
end

function block = make_block(startTime, endTime, jobId, operationId, loadStatus)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.from_machine = -1;
block.to_machine = -1;
block.status = [];
block.load_status = loadStatus;
block.charge = 0;
end

function assert_has_error(report, expectedMessage)
joinedErrors = strjoin(report.errors, newline);
assert(~isempty(strfind(joinedErrors, expectedMessage)), ...
    ['Expected error containing: ', expectedMessage, newline, ...
    'Actual errors:', newline, joinedErrors]);
end
