function features = extract_cancellation_features( ...
    baselineSchedule, state, cancel, localRepairCandidate, completeReschedulingCandidate)
%EXTRACT_CANCELLATION_FEATURES Build features for adaptive strategy rules.
%   features = EXTRACT_CANCELLATION_FEATURES(baselineSchedule, state,
%   cancel, localRepairCandidate, completeReschedulingCandidate) extracts
%   lightweight scenario features from the existing stage B-H structures.

if nargin < 5
    error('extract_cancellation_features:MissingInput', ...
        ['baselineSchedule, state, cancel, localRepairCandidate, ', ...
        'and completeReschedulingCandidate are required.']);
end

baselineCmax = calculate_baseline_cmax(baselineSchedule);
operationCount = get_numeric_field(state, 'operation_count', ...
    count_field(state, 'completed_operations') + ...
    count_field(state, 'remaining_unfinished_operations') + ...
    count_field(state, 'cancelled_unfinished_operations'));

completedOperationCount = count_field(state, 'completed_operations');
cancelledOperationCount = count_field(state, ...
    'cancelled_unfinished_operations');

features = struct();
features.cancel_time_ratio = safe_ratio(cancel.cancel_time, baselineCmax);
features.remaining_operation_count = count_field(state, ...
    'remaining_unfinished_operations');
features.cancelled_operation_count = cancelledOperationCount;
features.frozen_operation_ratio = safe_ratio( ...
    completedOperationCount, operationCount);
features.remaining_agv_task_count = calculate_remaining_agv_task_count(state);
features.cancelled_agv_task_count = count_field(state, ...
    'cancelled_unfinished_agv_tasks');
features.local_repair_feasible = get_logical_field( ...
    localRepairCandidate, 'isFeasible');
features.complete_rescheduling_feasible = get_logical_field( ...
    completeReschedulingCandidate, 'isFeasible');
features.unsupported_flag = has_unsupported_state(state);
end

function cmax = calculate_baseline_cmax(schedule)
if ~isstruct(schedule) || ~isfield(schedule, 'machineTable') || ...
        ~iscell(schedule.machineTable)
    error('extract_cancellation_features:InvalidBaselineSchedule', ...
        'baselineSchedule.machineTable must be a cell array.');
end

cmax = 0;
for machineIdx = 1:numel(schedule.machineTable)
    blocks = schedule.machineTable{machineIdx};
    if isempty(blocks)
        continue
    end

    if ~isfield(blocks, 'job') || ~isfield(blocks, 'end')
        error('extract_cancellation_features:InvalidMachineBlock', ...
            'machineTable blocks require job and end fields.');
    end

    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job > 0
            cmax = max(cmax, block.end);
        end
    end
end
end

function count = calculate_remaining_agv_task_count(state)
agvTaskCount = get_numeric_field(state, 'agv_task_count', 0);
completedCount = count_field(state, 'completed_agv_tasks');
cancelledCount = count_field(state, 'cancelled_unfinished_agv_tasks');

if agvTaskCount > 0
    count = max(0, agvTaskCount - completedCount - cancelledCount);
else
    count = 0;
end
end

function tf = has_unsupported_state(state)
tf = false;
tf = tf || get_logical_field(state, 'has_unsupported_operations');
tf = tf || get_logical_field(state, 'has_unsupported_agv_tasks');
tf = tf || count_field(state, 'unsupported_operations') > 0;
tf = tf || count_field(state, 'unsupported_agv_tasks') > 0;
end

function count = count_field(s, fieldName)
if isstruct(s) && isfield(s, fieldName)
    count = numel(s.(fieldName));
else
    count = 0;
end
end

function value = get_numeric_field(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && isnumeric(s.(fieldName)) && ...
        isscalar(s.(fieldName)) && isfinite(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = get_logical_field(s, fieldName)
if isstruct(s) && isfield(s, fieldName)
    value = logical(s.(fieldName));
else
    value = false;
end
end

function value = safe_ratio(numerator, denominator)
if denominator <= 0
    value = 0;
else
    value = numerator / denominator;
end
end
