function candidate = remove_cancelled_machine_operations(problem, schedule, state, cancel)
%REMOVE_CANCELLED_MACHINE_OPERATIONS Remove unstarted cancelled machine operations.
%   candidate = REMOVE_CANCELLED_MACHINE_OPERATIONS(problem, schedule, state,
%   cancel) removes only unstarted machine operations for the cancelled job.
%   It does not move remaining operations or touch AGV tasks.

if nargin < 4
    error('remove_cancelled_machine_operations:MissingInput', ...
        'problem, schedule, state, and cancel are required.');
end

candidate = create_empty_candidate();
candidate.report = validate_inputs(problem, schedule, state, cancel, ...
    candidate.report);

if isstruct(schedule) && isfield(schedule, 'machineTable')
    candidate.machineTable = schedule.machineTable;
end

if isstruct(schedule) && isfield(schedule, 'AGVTable')
    candidate.AGVTable = schedule.AGVTable;
end

if ~isempty(candidate.report.rejectedReasons) || ...
        ~isempty(candidate.report.errors)
    candidate.isFeasible = false;
    return
end

candidate.machineTable = schedule.machineTable;
candidate.AGVTable = schedule.AGVTable;
[candidate.machineTable, candidate.removed_operations, ...
    candidate.frozen_operations, candidate.unknown_operations, ...
    candidate.completed_operation_count] = prune_cancelled_machine_table( ...
    candidate.machineTable, cancel);
candidate.report.removedOperationCount = ...
    numel(candidate.removed_operations);
candidate.report.removedUnstartedOperationCount = ...
    numel(candidate.removed_operations);
candidate.report.remainingUnstartedOperationCount = ...
    count_remaining_unstarted_machine_operations(candidate.machineTable, ...
    cancel);
candidate.report.completedOperationCount = ...
    candidate.completed_operation_count;
candidate.report.frozenProcessingOperationCount = ...
    numel(candidate.frozen_operations);
candidate.report.frozenProcessingOperations = candidate.frozen_operations;
candidate.report.unknownOperationCount = numel(candidate.unknown_operations);
candidate.report.unknownOperations = candidate.unknown_operations;
candidate.isFeasible = true;
end

function candidate = create_empty_candidate()
candidate = struct();
candidate.machineTable = [];
candidate.AGVTable = [];
candidate.removed_operations = empty_operation_array();
candidate.removed_agv_tasks = empty_agv_task_array();
candidate.isFeasible = false;
candidate.report = empty_report();
end

function report = validate_inputs(problem, schedule, state, cancel, report)
if ~isstruct(problem)
    report.errors{end + 1} = 'problem must be a struct.';
end

if ~isstruct(schedule) || ~isfield(schedule, 'machineTable') || ...
        ~isfield(schedule, 'AGVTable')
    report.errors{end + 1} = ...
        'schedule.machineTable and schedule.AGVTable are required.';
end

requiredStateFields = {'cancelled_unfinished_operations', ...
    'cancelled_unfinished_agv_tasks', 'has_unsupported_operations', ...
    'has_unsupported_agv_tasks', 'cancel'};
for i = 1:numel(requiredStateFields)
    if ~isstruct(state) || ~isfield(state, requiredStateFields{i})
        report.errors{end + 1} = sprintf( ...
            'state.%s is required.', requiredStateFields{i});
    end
end

if ~isempty(report.errors)
    return
end

if ~strcmp(cancel.policy, 'cancel_unstarted_operations_only')
    report.rejectedReasons{end + 1} = ...
        'Only cancel_unstarted_operations_only is supported.';
end

if state.cancel.job_id ~= cancel.job_id
    report.rejectedReasons{end + 1} = ...
        'state.cancel.job_id does not match cancel.job_id.';
end

if state.cancel.cancel_time ~= cancel.cancel_time
    report.rejectedReasons{end + 1} = ...
        'state.cancel.cancel_time does not match cancel.cancel_time.';
end
end

function [machineTable, removedOperations, frozenOperations, ...
    unknownOperations, completedOperationCount] = prune_cancelled_machine_table( ...
    machineTable, cancel)
removedOperations = empty_operation_array();
frozenOperations = empty_operation_array();
unknownOperations = empty_operation_array();
completedOperationCount = 0;

if ~iscell(machineTable)
    return
end

for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    if isempty(blocks) || ~isstruct(blocks)
        continue
    end

    keptBlocks = blocks([]);
    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if ~isfield(block, 'job') || block.job ~= cancel.job_id
            keptBlocks(end + 1) = block;
            continue
        end

        operation = struct();
        operation.job_id = read_optional_block_value(block, 'job');
        operation.operation_id = read_optional_block_value(block, 'opera');
        operation.machine_id = machineIdx;
        operation.block_index = blockIdx;
        operation.start_time = read_optional_block_value(block, 'start');
        operation.end_time = read_optional_block_value(block, 'end');
        operation.status = '';

        bucket = classify_cancelled_machine_operation(block, cancel);
        if strcmp(bucket, 'unstarted')
            removedOperations(end + 1) = operation;
        elseif strcmp(bucket, 'processing')
            keptBlocks(end + 1) = block;
            frozenOperations(end + 1) = operation;
        elseif strcmp(bucket, 'completed')
            keptBlocks(end + 1) = block;
            completedOperationCount = completedOperationCount + 1;
        else
            keptBlocks(end + 1) = block;
            unknownOperations(end + 1) = operation;
        end
    end
    machineTable{machineIdx} = keptBlocks;
end

removedOperations = sort_operations_for_deletion(removedOperations);
frozenOperations = sort_operations_for_deletion(frozenOperations);
unknownOperations = sort_operations_for_deletion(unknownOperations);
end

function count = count_remaining_unstarted_machine_operations(machineTable, ...
    cancel)
count = 0;
if ~iscell(machineTable)
    return
end

for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    if isempty(blocks) || ~isstruct(blocks)
        continue
    end

    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if ~isfield(block, 'job') || block.job ~= cancel.job_id
            continue
        end

        startTime = read_optional_block_value(block, 'start');
        endTime = read_optional_block_value(block, 'end');
        if isempty(startTime) || isempty(endTime)
            continue
        end

        if startTime > cancel.cancel_time
            count = count + 1;
        end
    end
end
end

function bucket = classify_cancelled_machine_operation(block, cancel)
bucket = 'unknown';
if ~isstruct(cancel) || ~isfield(cancel, 'cancel_time') || ...
        ~isnumeric(cancel.cancel_time) || ~isscalar(cancel.cancel_time)
    return
end

startTime = read_optional_block_value(block, 'start');
endTime = read_optional_block_value(block, 'end');
if isempty(startTime) || isempty(endTime)
    return
end

if endTime <= cancel.cancel_time
    bucket = 'completed';
elseif startTime <= cancel.cancel_time && cancel.cancel_time < endTime
    bucket = 'processing';
elseif startTime > cancel.cancel_time
    bucket = 'unstarted';
end
end

function value = read_optional_block_value(block, fieldName)
value = [];
if ~isstruct(block) || ~isfield(block, fieldName)
    return
end
fieldValue = block.(fieldName);
if ~isnumeric(fieldValue) || ~isscalar(fieldValue) || ~isfinite(fieldValue)
    return
end
value = fieldValue;
end

function operations = sort_operations_for_deletion(operations)
if isempty(operations)
    return
end

keys = zeros(numel(operations), 2);
for i = 1:numel(operations)
    keys(i, :) = [operations(i).machine_id, operations(i).block_index];
end

[~, order] = sortrows(keys, [-1, -2]);
operations = operations(order);
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.rejectedReasons = {};
report.removedOperationCount = 0;
report.removedAgvTaskCount = 0;
report.machineConflictCheck = struct();
report.agvConflictCheck = struct();
report.jobSequenceCheck = struct();
end

function operations = empty_operation_array()
operations = repmat(struct( ...
    'job_id', [], ...
    'operation_id', [], ...
    'machine_id', [], ...
    'block_index', [], ...
    'start_time', [], ...
    'end_time', [], ...
    'status', ''), 1, 0);
end

function agvTasks = empty_agv_task_array()
agvTasks = repmat(struct( ...
    'job_id', [], ...
    'operation_id', [], ...
    'agv_id', [], ...
    'block_index', [], ...
    'start_time', [], ...
    'end_time', [], ...
    'from_machine', [], ...
    'to_machine', [], ...
    'status', '', ...
    'load_status', [], ...
    'charge', []), 1, 0);
end
