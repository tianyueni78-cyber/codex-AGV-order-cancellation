function state = extract_cancellation_state(problem, schedule, cancel)
%EXTRACT_CANCELLATION_STATE Classify operations at cancellation time.
%   state = EXTRACT_CANCELLATION_STATE(problem, schedule, cancel) reads the
%   normal schedule.machineTable and schedule.AGVTable, then classifies real
%   operations and AGV tasks at cancel.cancel_time.

if nargin < 3
    error('extract_cancellation_state:MissingInput', ...
        'problem, schedule, and cancel are required.');
end

[isCancelValid, cancelReport] = validate_order_cancellation_event( ...
    cancel, problem);
if ~isCancelValid
    error('extract_cancellation_state:InvalidCancelEvent', ...
        strjoin(cancelReport.errors, newline));
end

require_schedule(schedule);

operations = collect_machine_operations(schedule.machineTable);
agvTasks = collect_agv_tasks(schedule.AGVTable);
t = cancel.cancel_time;

state = empty_state();
state.cancel = cancel;
state.operation_count = numel(operations);
state.agv_task_count = numel(agvTasks);

for i = 1:numel(operations)
    operation = operations(i);
    operation.status = classify_time_interval( ...
        operation.start_time, operation.end_time, t);

    switch operation.status
        case 'completed'
            state.completed_operations(end + 1) = operation;
        case 'processing'
            state.processing_operations(end + 1) = operation;
        case 'unstarted'
            state.unstarted_operations(end + 1) = operation;
    end

    isCancelledJob = operation.job_id == cancel.job_id;
    if isCancelledJob && ~strcmp(operation.status, 'completed')
        state.cancelled_unfinished_operations(end + 1) = operation;
        if strcmp(operation.status, 'processing')
            state.unsupported_operations(end + 1) = operation;
        end
    elseif ~isCancelledJob && ~strcmp(operation.status, 'completed')
        state.remaining_unfinished_operations(end + 1) = operation;
    end
end

state.has_unsupported_operations = ...
    ~isempty(state.unsupported_operations);

for i = 1:numel(agvTasks)
    agvTask = agvTasks(i);
    agvTask.status = classify_time_interval( ...
        agvTask.start_time, agvTask.end_time, t);

    switch agvTask.status
        case 'completed'
            state.completed_agv_tasks(end + 1) = agvTask;
        case 'processing'
            state.processing_agv_tasks(end + 1) = agvTask;
        case 'unstarted'
            state.unstarted_agv_tasks(end + 1) = agvTask;
    end

    if agvTask.job_id == cancel.job_id && ...
            ~strcmp(agvTask.status, 'completed')
        state.cancelled_unfinished_agv_tasks(end + 1) = agvTask;
        if strcmp(agvTask.status, 'processing')
            state.unsupported_agv_tasks(end + 1) = agvTask;
        end
    end
end

state.has_unsupported_agv_tasks = ~isempty(state.unsupported_agv_tasks);
end

function status = classify_time_interval(startTime, endTime, cancelTime)
if endTime < startTime
    error('extract_cancellation_state:InvalidTimeInterval', ...
        'end_time must be greater than or equal to start_time.');
end

if endTime <= cancelTime
    status = 'completed';
elseif startTime < cancelTime && cancelTime < endTime
    status = 'processing';
else
    status = 'unstarted';
end
end

function operations = collect_machine_operations(machineTable)
operations = empty_operation_array();

if ~iscell(machineTable)
    error('extract_cancellation_state:InvalidMachineTable', ...
        'schedule.machineTable must be a cell array.');
end

for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    if isempty(blocks)
        continue
    end
    require_block_fields(blocks, machineIdx);

    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job <= 0
            continue
        end

        operation = struct();
        operation.job_id = block.job;
        operation.operation_id = block.opera;
        operation.machine_id = machineIdx;
        operation.block_index = blockIdx;
        operation.start_time = block.start;
        operation.end_time = block.end;
        operation.status = '';
        operations(end + 1) = operation;
    end
end
end

function agvTasks = collect_agv_tasks(AGVTable)
agvTasks = empty_agv_task_array();

if ~iscell(AGVTable)
    error('extract_cancellation_state:InvalidAGVTable', ...
        'schedule.AGVTable must be a cell array.');
end

for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    if isempty(blocks)
        continue
    end
    require_agv_block_fields(blocks, agvIdx);

    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job <= 0
            continue
        end

        agvTask = struct();
        agvTask.job_id = block.job;
        agvTask.operation_id = block.opera;
        agvTask.agv_id = agvIdx;
        agvTask.block_index = blockIdx;
        agvTask.start_time = block.start;
        agvTask.end_time = block.end;
        agvTask.from_machine = block.from_machine;
        agvTask.to_machine = block.to_machine;
        agvTask.status = '';
        agvTask.load_status = optional_block_value(block, 'load_status');
        agvTask.charge = optional_block_value(block, 'charge');
        agvTasks(end + 1) = agvTask;
    end
end
end

function require_schedule(schedule)
if ~isstruct(schedule)
    error('extract_cancellation_state:InvalidSchedule', ...
        'schedule must be a struct.');
end

if ~isfield(schedule, 'machineTable')
    error('extract_cancellation_state:MissingMachineTable', ...
        'schedule.machineTable is required.');
end

if ~isfield(schedule, 'AGVTable')
    error('extract_cancellation_state:MissingAGVTable', ...
        'schedule.AGVTable is required.');
end
end

function require_block_fields(blocks, machineIdx)
requiredFields = {'start', 'end', 'job', 'opera'};
for i = 1:numel(requiredFields)
    if ~isfield(blocks, requiredFields{i})
        error('extract_cancellation_state:InvalidMachineBlock', ...
            'machineTable{%d} blocks require field %s.', ...
            machineIdx, requiredFields{i});
    end
end
end

function require_agv_block_fields(blocks, agvIdx)
requiredFields = {'start', 'end', 'job', 'opera', ...
    'from_machine', 'to_machine'};
for i = 1:numel(requiredFields)
    if ~isfield(blocks, requiredFields{i})
        error('extract_cancellation_state:InvalidAGVBlock', ...
            'AGVTable{%d} blocks require field %s.', ...
            agvIdx, requiredFields{i});
    end
end
end

function value = optional_block_value(block, fieldName)
if isfield(block, fieldName)
    value = block.(fieldName);
else
    value = [];
end
end

function state = empty_state()
state = struct();
state.cancel = struct();
state.operation_count = 0;
state.agv_task_count = 0;
state.completed_operations = empty_operation_array();
state.processing_operations = empty_operation_array();
state.unstarted_operations = empty_operation_array();
state.cancelled_unfinished_operations = empty_operation_array();
state.remaining_unfinished_operations = empty_operation_array();
state.unsupported_operations = empty_operation_array();
state.has_unsupported_operations = false;
state.completed_agv_tasks = empty_agv_task_array();
state.processing_agv_tasks = empty_agv_task_array();
state.unstarted_agv_tasks = empty_agv_task_array();
state.cancelled_unfinished_agv_tasks = empty_agv_task_array();
state.unsupported_agv_tasks = empty_agv_task_array();
state.has_unsupported_agv_tasks = false;
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
