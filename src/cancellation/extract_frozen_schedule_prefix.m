function prefix = extract_frozen_schedule_prefix(schedule, state, cancel)
%EXTRACT_FROZEN_SCHEDULE_PREFIX Extract completed tasks before cancellation.
%   prefix = EXTRACT_FROZEN_SCHEDULE_PREFIX(schedule, state, cancel) returns
%   the completed machine operations and AGV tasks that must remain fixed in
%   complete rescheduling. Processing operations and AGV tasks are reported
%   as unsupported in the first version.

if nargin < 3
    error('extract_frozen_schedule_prefix:MissingInput', ...
        'schedule, state, and cancel are required.');
end

require_schedule(schedule);
require_state(state);
require_cancel_consistency(state, cancel);

prefix = empty_prefix();
prefix.cancel = cancel;
prefix.frozen_operations = add_source( ...
    state.completed_operations, 'state.completed_operations');
prefix.frozen_agv_tasks = add_source( ...
    state.completed_agv_tasks, 'state.completed_agv_tasks');
prefix.unsupported_operations = add_source( ...
    state.processing_operations, 'state.processing_operations');
prefix.unsupported_agv_tasks = add_source( ...
    state.processing_agv_tasks, 'state.processing_agv_tasks');

prefix.has_unsupported_operations = ~isempty(prefix.unsupported_operations);
prefix.has_unsupported_agv_tasks = ~isempty(prefix.unsupported_agv_tasks);
prefix.isFeasible = ~prefix.has_unsupported_operations && ...
    ~prefix.has_unsupported_agv_tasks;

prefix.report.frozenOperationCount = numel(prefix.frozen_operations);
prefix.report.frozenAgvTaskCount = numel(prefix.frozen_agv_tasks);
prefix.report.unsupportedOperationCount = ...
    numel(prefix.unsupported_operations);
prefix.report.unsupportedAgvTaskCount = ...
    numel(prefix.unsupported_agv_tasks);

validate_completed_records(prefix.frozen_operations, ...
    cancel.cancel_time, 'operation');
validate_completed_records(prefix.frozen_agv_tasks, ...
    cancel.cancel_time, 'agv_task');

if prefix.has_unsupported_operations
    prefix.report.rejectedReasons{end + 1} = ...
        'processing_operations_are_not_supported_in_stage_d';
end

if prefix.has_unsupported_agv_tasks
    prefix.report.rejectedReasons{end + 1} = ...
        'processing_agv_tasks_are_not_supported_in_stage_d';
end
end

function require_schedule(schedule)
if ~isstruct(schedule)
    error('extract_frozen_schedule_prefix:InvalidSchedule', ...
        'schedule must be a struct.');
end

if ~isfield(schedule, 'machineTable')
    error('extract_frozen_schedule_prefix:MissingMachineTable', ...
        'schedule.machineTable is required.');
end

if ~isfield(schedule, 'AGVTable')
    error('extract_frozen_schedule_prefix:MissingAGVTable', ...
        'schedule.AGVTable is required.');
end
end

function require_state(state)
requiredFields = { ...
    'cancel', ...
    'completed_operations', ...
    'completed_agv_tasks', ...
    'processing_operations', ...
    'processing_agv_tasks'};

for i = 1:numel(requiredFields)
    if ~isstruct(state) || ~isfield(state, requiredFields{i})
        error('extract_frozen_schedule_prefix:InvalidState', ...
            'state.%s is required.', requiredFields{i});
    end
end
end

function require_cancel_consistency(state, cancel)
if ~isfield(state.cancel, 'job_id') || ~isfield(cancel, 'job_id') || ...
        state.cancel.job_id ~= cancel.job_id
    error('extract_frozen_schedule_prefix:CancelMismatch', ...
        'state.cancel.job_id must match cancel.job_id.');
end

if ~isfield(state.cancel, 'cancel_time') || ...
        ~isfield(cancel, 'cancel_time') || ...
        state.cancel.cancel_time ~= cancel.cancel_time
    error('extract_frozen_schedule_prefix:CancelMismatch', ...
        'state.cancel.cancel_time must match cancel.cancel_time.');
end
end

function records = add_source(records, sourceName)
for i = 1:numel(records)
    records(i).source = sourceName;
end
end

function validate_completed_records(records, cancelTime, recordType)
for i = 1:numel(records)
    if records(i).end_time > cancelTime
        error('extract_frozen_schedule_prefix:InvalidFrozenRecord', ...
            'Frozen %s must end no later than cancel_time.', recordType);
    end
end
end

function prefix = empty_prefix()
prefix = struct();
prefix.cancel = struct();
prefix.frozen_operations = struct([]);
prefix.frozen_agv_tasks = struct([]);
prefix.unsupported_operations = struct([]);
prefix.unsupported_agv_tasks = struct([]);
prefix.has_unsupported_operations = false;
prefix.has_unsupported_agv_tasks = false;
prefix.isFeasible = true;
prefix.report = struct();
prefix.report.errors = {};
prefix.report.warnings = {};
prefix.report.rejectedReasons = {};
prefix.report.frozenOperationCount = 0;
prefix.report.frozenAgvTaskCount = 0;
prefix.report.unsupportedOperationCount = 0;
prefix.report.unsupportedAgvTaskCount = 0;
end

