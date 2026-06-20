function constraints = build_rescheduling_constraints(prefix, remainingSet, cancel)
%BUILD_RESCHEDULING_CONSTRAINTS Build constraints for complete rescheduling.
%   constraints = BUILD_RESCHEDULING_CONSTRAINTS(prefix, remainingSet, cancel)
%   records frozen machine/AGV occupancy and the earliest allowed start time
%   for remaining operations.

if nargin < 3
    error('build_rescheduling_constraints:MissingInput', ...
        'prefix, remainingSet, and cancel are required.');
end

require_prefix(prefix);
require_remaining_set(remainingSet);
require_cancel_consistency(prefix.cancel, cancel, 'prefix.cancel');
require_cancel_consistency(remainingSet.cancel, cancel, 'remainingSet.cancel');

constraints = empty_constraints();
constraints.cancel = cancel;
constraints.earliest_start_time = cancel.cancel_time;
constraints.frozen_machine_occupancy = make_machine_occupancy( ...
    prefix.frozen_operations, cancel.cancel_time);
constraints.frozen_agv_occupancy = make_agv_occupancy( ...
    prefix.frozen_agv_tasks, cancel.cancel_time);

constraints.report.frozenMachineOccupancyCount = ...
    numel(constraints.frozen_machine_occupancy);
constraints.report.frozenAgvOccupancyCount = ...
    numel(constraints.frozen_agv_occupancy);

constraints = check_remaining_start_times( ...
    constraints, remainingSet.operations, cancel.cancel_time);
constraints = check_prefix_feasibility(constraints, prefix);
constraints.isFeasible = isempty(constraints.report.errors);
end

function require_prefix(prefix)
requiredFields = {'cancel', 'frozen_operations', 'frozen_agv_tasks', ...
    'isFeasible'};

for i = 1:numel(requiredFields)
    if ~isstruct(prefix) || ~isfield(prefix, requiredFields{i})
        error('build_rescheduling_constraints:InvalidPrefix', ...
            'prefix.%s is required.', requiredFields{i});
    end
end
end

function require_remaining_set(remainingSet)
requiredFields = {'cancel', 'operations'};

for i = 1:numel(requiredFields)
    if ~isstruct(remainingSet) || ~isfield(remainingSet, requiredFields{i})
        error('build_rescheduling_constraints:InvalidRemainingSet', ...
            'remainingSet.%s is required.', requiredFields{i});
    end
end
end

function require_cancel_consistency(sourceCancel, cancel, sourceName)
if ~isfield(sourceCancel, 'job_id') || ~isfield(cancel, 'job_id') || ...
        sourceCancel.job_id ~= cancel.job_id
    error('build_rescheduling_constraints:CancelMismatch', ...
        '%s.job_id must match cancel.job_id.', sourceName);
end

if ~isfield(sourceCancel, 'cancel_time') || ...
        ~isfield(cancel, 'cancel_time') || ...
        sourceCancel.cancel_time ~= cancel.cancel_time
    error('build_rescheduling_constraints:CancelMismatch', ...
        '%s.cancel_time must match cancel.cancel_time.', sourceName);
end
end

function occupancy = make_machine_occupancy(frozenOperations, cancelTime)
occupancy = empty_machine_occupancy();

for i = 1:numel(frozenOperations)
    operation = frozenOperations(i);
    if operation.end_time > cancelTime
        error('build_rescheduling_constraints:InvalidFrozenOperation', ...
            'Frozen operation must end no later than cancel_time.');
    end

    record = struct();
    record.machine_id = operation.machine_id;
    record.job_id = operation.job_id;
    record.operation_id = operation.operation_id;
    record.start_time = operation.start_time;
    record.end_time = operation.end_time;
    record.source = 'prefix.frozen_operations';
    occupancy(end + 1) = record;
end
end

function occupancy = make_agv_occupancy(frozenAgvTasks, cancelTime)
occupancy = empty_agv_occupancy();

for i = 1:numel(frozenAgvTasks)
    agvTask = frozenAgvTasks(i);
    if agvTask.end_time > cancelTime
        error('build_rescheduling_constraints:InvalidFrozenAgvTask', ...
            'Frozen AGV task must end no later than cancel_time.');
    end

    record = struct();
    record.agv_id = agvTask.agv_id;
    record.job_id = agvTask.job_id;
    record.operation_id = agvTask.operation_id;
    record.start_time = agvTask.start_time;
    record.end_time = agvTask.end_time;
    record.from_machine = agvTask.from_machine;
    record.to_machine = agvTask.to_machine;
    record.source = 'prefix.frozen_agv_tasks';
    occupancy(end + 1) = record;
end
end

function constraints = check_remaining_start_times( ...
    constraints, operations, cancelTime)
for i = 1:numel(operations)
    operation = operations(i);
    if isfield(operation, 'start_time') && ...
            ~isempty(operation.start_time) && ...
            operation.start_time < cancelTime
        constraints.report.errors{end + 1} = sprintf( ...
            ['remaining operation job %d operation %d starts before ', ...
            'cancel_time: %.6f < %.6f.'], ...
            operation.job_id, operation.operation_id, ...
            operation.start_time, cancelTime);
    end
end
end

function constraints = check_prefix_feasibility(constraints, prefix)
if ~prefix.isFeasible
    constraints.report.rejectedReasons{end + 1} = ...
        'frozen_prefix_infeasible';
    constraints.report.errors{end + 1} = ...
        'Frozen prefix is infeasible for stage D constraints.';
end
end

function constraints = empty_constraints()
constraints = struct();
constraints.cancel = struct();
constraints.earliest_start_time = [];
constraints.frozen_machine_occupancy = empty_machine_occupancy();
constraints.frozen_agv_occupancy = empty_agv_occupancy();
constraints.isFeasible = true;
constraints.report = struct();
constraints.report.errors = {};
constraints.report.warnings = {};
constraints.report.rejectedReasons = {};
constraints.report.frozenMachineOccupancyCount = 0;
constraints.report.frozenAgvOccupancyCount = 0;
end

function occupancy = empty_machine_occupancy()
occupancy = repmat(struct( ...
    'machine_id', [], ...
    'job_id', [], ...
    'operation_id', [], ...
    'start_time', [], ...
    'end_time', [], ...
    'source', ''), 1, 0);
end

function occupancy = empty_agv_occupancy()
occupancy = repmat(struct( ...
    'agv_id', [], ...
    'job_id', [], ...
    'operation_id', [], ...
    'start_time', [], ...
    'end_time', [], ...
    'from_machine', [], ...
    'to_machine', [], ...
    'source', ''), 1, 0);
end

