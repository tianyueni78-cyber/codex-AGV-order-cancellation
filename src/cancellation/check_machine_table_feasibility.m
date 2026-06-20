function [isFeasible, report] = check_machine_table_feasibility(machineTable)
%CHECK_MACHINE_TABLE_FEASIBILITY Check machine operation time conflicts.
%   [isFeasible, report] = CHECK_MACHINE_TABLE_FEASIBILITY(machineTable)
%   checks real operations only. Idle blocks with job <= 0 are ignored.

if nargin < 1
    error('check_machine_table_feasibility:MissingInput', ...
        'machineTable is required.');
end

report = empty_report();

if ~iscell(machineTable)
    report.errors{end + 1} = 'machineTable must be a cell array.';
    isFeasible = false;
    report.isFeasible = isFeasible;
    return
end

for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    if isempty(blocks)
        continue
    end

    report = require_block_fields(blocks, machineIdx, report);
    if ~isempty(report.errors)
        continue
    end

    operations = collect_real_operations(blocks, machineIdx);
    report.checkedOperationCount = ...
        report.checkedOperationCount + numel(operations);
    report = check_operation_times(operations, report);
    report = check_machine_overlaps(operations, report);
end

isFeasible = isempty(report.errors);
report.isFeasible = isFeasible;
end

function report = require_block_fields(blocks, machineIdx, report)
requiredFields = {'start', 'end', 'job', 'opera'};
for i = 1:numel(requiredFields)
    if ~isfield(blocks, requiredFields{i})
        report.errors{end + 1} = sprintf( ...
            'machineTable{%d} blocks require field %s.', ...
            machineIdx, requiredFields{i});
    end
end
end

function operations = collect_real_operations(blocks, machineIdx)
operations = empty_operation_array();

for blockIdx = 1:numel(blocks)
    block = blocks(blockIdx);
    if block.job <= 0
        continue
    end

    operation = struct();
    operation.machine_id = machineIdx;
    operation.block_index = blockIdx;
    operation.job_id = block.job;
    operation.operation_id = block.opera;
    operation.start_time = require_scalar_time(block.start, ...
        machineIdx, blockIdx, 'start');
    operation.end_time = require_scalar_time(block.end, ...
        machineIdx, blockIdx, 'end');
    operations(end + 1) = operation;
end
end

function value = require_scalar_time(value, machineIdx, blockIdx, fieldName)
if isempty(value) || ~isnumeric(value) || ~isscalar(value)
    error('check_machine_table_feasibility:InvalidTimeValue', ...
        'machineTable{%d} block %d field %s must be a numeric scalar.', ...
        machineIdx, blockIdx, fieldName);
end
end

function report = check_operation_times(operations, report)
for i = 1:numel(operations)
    operation = operations(i);
    if operation.end_time < operation.start_time
        report.errors{end + 1} = sprintf( ...
            ['machine %d block %d has end < start: ', ...
            'job %d operation %d, start %.6f, end %.6f.'], ...
            operation.machine_id, operation.block_index, ...
            operation.job_id, operation.operation_id, ...
            operation.start_time, operation.end_time);
    end
end
end

function report = check_machine_overlaps(operations, report)
if numel(operations) < 2
    return
end

startTimes = [operations.start_time]';
endTimes = [operations.end_time]';
[~, order] = sortrows([startTimes, endTimes], [1, 2]);
operations = operations(order);

for i = 2:numel(operations)
    previous = operations(i - 1);
    current = operations(i);
    if current.start_time < previous.end_time
        report.errors{end + 1} = sprintf( ...
            ['machine %d has overlapping operations: ', ...
            'block %d job %d operation %d [%.6f, %.6f] and ', ...
            'block %d job %d operation %d [%.6f, %.6f].'], ...
            current.machine_id, ...
            previous.block_index, previous.job_id, ...
            previous.operation_id, previous.start_time, ...
            previous.end_time, current.block_index, current.job_id, ...
            current.operation_id, current.start_time, current.end_time);
    end
end
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.checkedOperationCount = 0;
report.isFeasible = false;
end

function operations = empty_operation_array()
operations = repmat(struct( ...
    'machine_id', [], ...
    'block_index', [], ...
    'job_id', [], ...
    'operation_id', [], ...
    'start_time', [], ...
    'end_time', []), 1, 0);
end
