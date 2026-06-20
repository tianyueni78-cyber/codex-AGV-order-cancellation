function remainingSet = build_remaining_operation_set(state, cancel)
%BUILD_REMAINING_OPERATION_SET Build operations for complete rescheduling.
%   remainingSet = BUILD_REMAINING_OPERATION_SET(state, cancel) returns the
%   unfinished non-cancelled operations that may enter complete
%   rescheduling. Cancelled unfinished operations and historical completed
%   operations are excluded.

if nargin < 2
    error('build_remaining_operation_set:MissingInput', ...
        'state and cancel are required.');
end

require_state(state);
require_cancel_consistency(state, cancel);

remainingSet = empty_remaining_set();
remainingSet.cancel = cancel;
remainingSet.excluded_operations = add_exclude_reason( ...
    state.cancelled_unfinished_operations);

candidateOperations = state.remaining_unfinished_operations;
for i = 1:numel(candidateOperations)
    operation = candidateOperations(i);

    if operation.job_id == cancel.job_id
        remainingSet.report.rejectedReasons{end + 1} = ...
            'cancelled_job_operation_found_in_remaining_unfinished_operations';
        remainingSet.report.errors{end + 1} = ...
            'Cancelled job operation cannot enter remaining operation set.';
        continue
    end

    if is_operation_in_set(operation, state.cancelled_unfinished_operations)
        remainingSet.report.rejectedReasons{end + 1} = ...
            'cancelled_unfinished_operation_found_in_remaining_set';
        remainingSet.report.errors{end + 1} = ...
            'Cancelled unfinished operation cannot enter remaining set.';
        continue
    end

    if is_operation_in_set(operation, state.completed_operations)
        remainingSet.report.rejectedReasons{end + 1} = ...
            'completed_operation_found_in_remaining_set';
        remainingSet.report.errors{end + 1} = ...
            'Completed historical operation cannot enter remaining set.';
        continue
    end

    remainingSet.operations(end + 1) = normalize_operation(operation);
end

remainingSet.report.operationCount = numel(remainingSet.operations);
remainingSet.report.excludedOperationCount = ...
    numel(remainingSet.excluded_operations);
remainingSet.isFeasible = isempty(remainingSet.report.errors);
end

function require_state(state)
requiredFields = { ...
    'cancel', ...
    'remaining_unfinished_operations', ...
    'cancelled_unfinished_operations', ...
    'completed_operations'};

for i = 1:numel(requiredFields)
    if ~isstruct(state) || ~isfield(state, requiredFields{i})
        error('build_remaining_operation_set:InvalidState', ...
            'state.%s is required.', requiredFields{i});
    end
end
end

function require_cancel_consistency(state, cancel)
if ~isfield(state.cancel, 'job_id') || ~isfield(cancel, 'job_id') || ...
        state.cancel.job_id ~= cancel.job_id
    error('build_remaining_operation_set:CancelMismatch', ...
        'state.cancel.job_id must match cancel.job_id.');
end

if ~isfield(state.cancel, 'cancel_time') || ...
        ~isfield(cancel, 'cancel_time') || ...
        state.cancel.cancel_time ~= cancel.cancel_time
    error('build_remaining_operation_set:CancelMismatch', ...
        'state.cancel.cancel_time must match cancel.cancel_time.');
end
end

function operation = normalize_operation(sourceOperation)
operation = struct();
operation.job_id = sourceOperation.job_id;
operation.operation_id = sourceOperation.operation_id;
operation.machine_id = optional_value(sourceOperation, 'machine_id');
operation.block_index = optional_value(sourceOperation, 'block_index');
operation.start_time = optional_value(sourceOperation, 'start_time');
operation.end_time = optional_value(sourceOperation, 'end_time');
operation.status = optional_value(sourceOperation, 'status');
operation.source = 'state.remaining_unfinished_operations';
operation.exclude_reason = '';
end

function excludedOperations = add_exclude_reason(sourceOperations)
excludedOperations = empty_operation_array();
for i = 1:numel(sourceOperations)
    operation = normalize_operation(sourceOperations(i));
    operation.exclude_reason = 'cancelled_order_unfinished_operation';
    excludedOperations(end + 1) = operation;
end
end

function exists = is_operation_in_set(operation, operationSet)
exists = false;
for i = 1:numel(operationSet)
    if operation.job_id == operationSet(i).job_id && ...
            operation.operation_id == operationSet(i).operation_id
        exists = true;
        return
    end
end
end

function value = optional_value(record, fieldName)
if isfield(record, fieldName)
    value = record.(fieldName);
else
    value = [];
end
end

function remainingSet = empty_remaining_set()
remainingSet = struct();
remainingSet.cancel = struct();
remainingSet.operations = empty_operation_array();
remainingSet.excluded_operations = empty_operation_array();
remainingSet.isFeasible = true;
remainingSet.report = struct();
remainingSet.report.errors = {};
remainingSet.report.warnings = {};
remainingSet.report.rejectedReasons = {};
remainingSet.report.operationCount = 0;
remainingSet.report.excludedOperationCount = 0;
end

function operations = empty_operation_array()
operations = repmat(struct( ...
    'job_id', [], ...
    'operation_id', [], ...
    'machine_id', [], ...
    'block_index', [], ...
    'start_time', [], ...
    'end_time', [], ...
    'status', '', ...
    'source', '', ...
    'exclude_reason', ''), 1, 0);
end
