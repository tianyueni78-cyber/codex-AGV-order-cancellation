function [isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidate, constraints, cancel)
%CHECK_COMPLETE_RESCHEDULING_CANDIDATE Validate complete rescheduling result.
%   This function reuses stage C feasibility checks, then verifies stage D
%   frozen-task consistency and cancelled-task exclusion.

if nargin < 4
    error('check_complete_rescheduling_candidate:MissingInput', ...
        'problem, candidate, constraints, and cancel are required.');
end

require_candidate(candidate);
require_constraints(constraints);
require_cancel_consistency(constraints.cancel, cancel);

report = empty_report();

[report.machineConflictCheck.isFeasible, ...
    report.machineConflictCheck] = check_machine_table_feasibility( ...
    candidate.machineTable);
[report.agvConflictCheck.isFeasible, ...
    report.agvConflictCheck] = check_agv_table_feasibility( ...
    candidate.AGVTable);
[report.jobSequenceCheck.isFeasible, ...
    report.jobSequenceCheck] = check_job_operation_sequence( ...
    problem, candidate.machineTable, cancel);

report.frozenConsistencyCheck = check_frozen_consistency( ...
    candidate, constraints);
report.cancelledTaskExclusionCheck = check_cancelled_task_exclusion( ...
    candidate, cancel);

report.errors = collect_errors(report);
isFeasible = isempty(report.errors);
report.isFeasible = isFeasible;
end

function require_candidate(candidate)
requiredFields = {'machineTable', 'AGVTable'};

for i = 1:numel(requiredFields)
    if ~isstruct(candidate) || ~isfield(candidate, requiredFields{i})
        error('check_complete_rescheduling_candidate:InvalidCandidate', ...
            'candidate.%s is required.', requiredFields{i});
    end
end
end

function require_constraints(constraints)
requiredFields = {'cancel', 'frozen_machine_occupancy', ...
    'frozen_agv_occupancy'};

for i = 1:numel(requiredFields)
    if ~isstruct(constraints) || ~isfield(constraints, requiredFields{i})
        error('check_complete_rescheduling_candidate:InvalidConstraints', ...
            'constraints.%s is required.', requiredFields{i});
    end
end
end

function require_cancel_consistency(sourceCancel, cancel)
if ~isfield(sourceCancel, 'job_id') || ~isfield(cancel, 'job_id') || ...
        sourceCancel.job_id ~= cancel.job_id
    error('check_complete_rescheduling_candidate:CancelMismatch', ...
        'constraints.cancel.job_id must match cancel.job_id.');
end

if ~isfield(sourceCancel, 'cancel_time') || ...
        ~isfield(cancel, 'cancel_time') || ...
        sourceCancel.cancel_time ~= cancel.cancel_time
    error('check_complete_rescheduling_candidate:CancelMismatch', ...
        'constraints.cancel.cancel_time must match cancel.cancel_time.');
end
end

function report = check_frozen_consistency(candidate, constraints)
report = struct();
report.errors = {};
report.checkedFrozenOperationCount = ...
    numel(constraints.frozen_machine_occupancy);
report.checkedFrozenAgvTaskCount = ...
    numel(constraints.frozen_agv_occupancy);

for i = 1:numel(constraints.frozen_machine_occupancy)
    frozen = constraints.frozen_machine_occupancy(i);
    actual = find_machine_operation(candidate.machineTable, ...
        frozen.job_id, frozen.operation_id);
    if isempty(actual)
        report.errors{end + 1} = sprintf( ...
            'Frozen operation job %d operation %d is missing.', ...
            frozen.job_id, frozen.operation_id);
        continue
    end

    if actual.machine_id ~= frozen.machine_id || ...
            actual.start_time ~= frozen.start_time || ...
            actual.end_time ~= frozen.end_time
        report.errors{end + 1} = sprintf( ...
            'Frozen operation job %d operation %d changed.', ...
            frozen.job_id, frozen.operation_id);
    end
end

for i = 1:numel(constraints.frozen_agv_occupancy)
    frozen = constraints.frozen_agv_occupancy(i);
    actual = find_agv_task(candidate.AGVTable, ...
        frozen.job_id, frozen.operation_id);
    if isempty(actual)
        report.errors{end + 1} = sprintf( ...
            'Frozen AGV task job %d operation %d is missing.', ...
            frozen.job_id, frozen.operation_id);
        continue
    end

    if actual.agv_id ~= frozen.agv_id || ...
            actual.start_time ~= frozen.start_time || ...
            actual.end_time ~= frozen.end_time
        report.errors{end + 1} = sprintf( ...
            'Frozen AGV task job %d operation %d changed.', ...
            frozen.job_id, frozen.operation_id);
    end
end

report.isFeasible = isempty(report.errors);
end

function report = check_cancelled_task_exclusion(candidate, cancel)
report = struct();
report.errors = {};

if isfield(candidate, 'excluded_operations')
    excludedOperations = candidate.excluded_operations;
else
    excludedOperations = struct([]);
end

for i = 1:numel(excludedOperations)
    excluded = excludedOperations(i);
    if operation_exists(candidate.machineTable, ...
            excluded.job_id, excluded.operation_id)
        report.errors{end + 1} = sprintf( ...
            'Excluded operation job %d operation %d appears in machineTable.', ...
            excluded.job_id, excluded.operation_id);
    end

    if agv_task_exists(candidate.AGVTable, ...
            excluded.job_id, excluded.operation_id)
        report.errors{end + 1} = sprintf( ...
            'Excluded operation job %d operation %d appears in AGVTable.', ...
            excluded.job_id, excluded.operation_id);
    end
end

report.isFeasible = isempty(report.errors);
end

function errors = collect_errors(report)
errors = {};
errors = append_check_errors(errors, report.machineConflictCheck, ...
    'machineConflictCheck');
errors = append_check_errors(errors, report.agvConflictCheck, ...
    'agvConflictCheck');
errors = append_check_errors(errors, report.jobSequenceCheck, ...
    'jobSequenceCheck');
errors = append_check_errors(errors, report.frozenConsistencyCheck, ...
    'frozenConsistencyCheck');
errors = append_check_errors(errors, report.cancelledTaskExclusionCheck, ...
    'cancelledTaskExclusionCheck');
end

function errors = append_check_errors(errors, checkReport, label)
if isfield(checkReport, 'errors')
    for i = 1:numel(checkReport.errors)
        errors{end + 1} = sprintf('%s: %s', label, ...
            checkReport.errors{i});
    end
end
end

function operation = find_machine_operation(machineTable, jobId, operationId)
operation = [];
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            operation = struct();
            operation.machine_id = machineIdx;
            operation.block_index = blockIdx;
            operation.start_time = blocks(blockIdx).start;
            operation.end_time = blocks(blockIdx).end;
            return
        end
    end
end
end

function agvTask = find_agv_task(AGVTable, jobId, operationId)
agvTask = [];
for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            agvTask = struct();
            agvTask.agv_id = agvIdx;
            agvTask.block_index = blockIdx;
            agvTask.start_time = blocks(blockIdx).start;
            agvTask.end_time = blocks(blockIdx).end;
            return
        end
    end
end
end

function exists = operation_exists(machineTable, jobId, operationId)
exists = ~isempty(find_machine_operation(machineTable, jobId, operationId));
end

function exists = agv_task_exists(AGVTable, jobId, operationId)
exists = ~isempty(find_agv_task(AGVTable, jobId, operationId));
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.machineConflictCheck = struct();
report.agvConflictCheck = struct();
report.jobSequenceCheck = struct();
report.frozenConsistencyCheck = struct();
report.cancelledTaskExclusionCheck = struct();
report.isFeasible = false;
end
