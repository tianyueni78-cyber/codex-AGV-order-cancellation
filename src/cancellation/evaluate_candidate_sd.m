function [metrics, report] = evaluate_candidate_sd( ...
    baselineSchedule, candidateSchedule, cancel)
%EVALUATE_CANDIDATE_SD Calculate machine-operation schedule disturbance.
%   SD = sum(abs(candidate_start - baseline_start)) for non-cancelled job
%   operations. Idle blocks with job <= 0 are ignored. Operations from the
%   cancelled job are excluded from SD in the first version.

if nargin < 3
    error('evaluate_candidate_sd:MissingInput', ...
        'baselineSchedule, candidateSchedule, and cancel are required.');
end

require_cancel(cancel);

metrics = empty_metrics();
report = empty_report();

[baselineOperations, baselineReport] = collect_machine_operations( ...
    baselineSchedule, cancel, 'baselineSchedule');
[candidateOperations, candidateReport] = collect_machine_operations( ...
    candidateSchedule, cancel, 'candidateSchedule');

report.baseline = baselineReport;
report.candidate = candidateReport;
report.errors = [report.errors, baselineReport.errors, ...
    candidateReport.errors];
report.checkedBaselineOperationCount = ...
    baselineReport.checkedOperationCount;
report.checkedCandidateOperationCount = ...
    candidateReport.checkedOperationCount;

if isempty(report.errors)
    report = check_operation_sets_match( ...
        baselineOperations, candidateOperations, report);
end

if isempty(report.errors)
    SD = 0;
    for i = 1:numel(baselineOperations)
        baselineOperation = baselineOperations(i);
        candidateOperation = find_operation( ...
            candidateOperations, baselineOperation.job_id, ...
            baselineOperation.operation_id);
        SD = SD + abs(candidateOperation.start_time - ...
            baselineOperation.start_time);
    end

    metrics.SD = SD;
    metrics.isFeasible = true;
end

report.isFeasible = isempty(report.errors);
end

function require_cancel(cancel)
if ~isstruct(cancel) || ~isfield(cancel, 'job_id')
    error('evaluate_candidate_sd:InvalidCancel', ...
        'cancel.job_id is required.');
end
end

function [operations, report] = collect_machine_operations( ...
    schedule, cancel, scheduleName)
operations = empty_operation_array();
report = empty_schedule_report();

if ~isstruct(schedule) || ~isfield(schedule, 'machineTable')
    report.errors{end + 1} = sprintf( ...
        '%s.machineTable is required.', scheduleName);
    return
end

machineTable = schedule.machineTable;
if ~iscell(machineTable)
    report.errors{end + 1} = sprintf( ...
        '%s.machineTable must be a cell array.', scheduleName);
    return
end

for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    if isempty(blocks)
        continue
    end

    report = require_block_fields(blocks, scheduleName, machineIdx, report);
    if ~isempty(report.errors)
        continue
    end

    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job <= 0 || block.job == cancel.job_id
            continue
        end

        operation = struct();
        operation.job_id = block.job;
        operation.operation_id = block.opera;
        operation.machine_id = machineIdx;
        operation.block_index = blockIdx;
        operation.start_time = require_scalar_time(block.start, ...
            scheduleName, machineIdx, blockIdx, 'start');
        operation.end_time = require_scalar_time(block.end, ...
            scheduleName, machineIdx, blockIdx, 'end');

        if operation.end_time < operation.start_time
            report.errors{end + 1} = sprintf( ...
                ['%s.machineTable{%d} block %d has end < start: ', ...
                'job %d operation %d, start %.6f, end %.6f.'], ...
                scheduleName, machineIdx, blockIdx, ...
                operation.job_id, operation.operation_id, ...
                operation.start_time, operation.end_time);
            continue
        end

        duplicate = find_operation(operations, ...
            operation.job_id, operation.operation_id);
        if ~isempty(duplicate)
            report.errors{end + 1} = sprintf( ...
                '%s contains duplicate job %d operation %d.', ...
                scheduleName, operation.job_id, operation.operation_id);
            continue
        end

        operations(end + 1) = operation;
        report.checkedOperationCount = report.checkedOperationCount + 1;
    end
end

report.isFeasible = isempty(report.errors);
end

function report = require_block_fields(blocks, scheduleName, machineIdx, ...
    report)
requiredFields = {'start', 'end', 'job', 'opera'};
for i = 1:numel(requiredFields)
    if ~isfield(blocks, requiredFields{i})
        report.errors{end + 1} = sprintf( ...
            '%s.machineTable{%d} blocks require field %s.', ...
            scheduleName, machineIdx, requiredFields{i});
    end
end
end

function value = require_scalar_time(value, scheduleName, machineIdx, ...
    blockIdx, fieldName)
if isempty(value) || ~isnumeric(value) || ~isscalar(value)
    error('evaluate_candidate_sd:InvalidTimeValue', ...
        '%s.machineTable{%d} block %d field %s must be a numeric scalar.', ...
        scheduleName, machineIdx, blockIdx, fieldName);
end
end

function report = check_operation_sets_match( ...
    baselineOperations, candidateOperations, report)
for i = 1:numel(baselineOperations)
    baselineOperation = baselineOperations(i);
    candidateOperation = find_operation( ...
        candidateOperations, baselineOperation.job_id, ...
        baselineOperation.operation_id);
    if isempty(candidateOperation)
        report.errors{end + 1} = sprintf( ...
            'Candidate is missing job %d operation %d for SD.', ...
            baselineOperation.job_id, baselineOperation.operation_id);
    end
end

for i = 1:numel(candidateOperations)
    candidateOperation = candidateOperations(i);
    baselineOperation = find_operation( ...
        baselineOperations, candidateOperation.job_id, ...
        candidateOperation.operation_id);
    if isempty(baselineOperation)
        report.errors{end + 1} = sprintf( ...
            'Candidate has extra job %d operation %d for SD.', ...
            candidateOperation.job_id, candidateOperation.operation_id);
    end
end
end

function operation = find_operation(operations, jobId, operationId)
operation = [];
for i = 1:numel(operations)
    if operations(i).job_id == jobId && ...
            operations(i).operation_id == operationId
        operation = operations(i);
        return
    end
end
end

function metrics = empty_metrics()
metrics = struct();
metrics.SD = [];
metrics.isFeasible = false;
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.baseline = struct();
report.candidate = struct();
report.checkedBaselineOperationCount = 0;
report.checkedCandidateOperationCount = 0;
report.isFeasible = false;
end

function report = empty_schedule_report()
report = struct();
report.errors = {};
report.warnings = {};
report.checkedOperationCount = 0;
report.isFeasible = false;
end

function operations = empty_operation_array()
operations = repmat(struct( ...
    'job_id', [], ...
    'operation_id', [], ...
    'machine_id', [], ...
    'block_index', [], ...
    'start_time', [], ...
    'end_time', []), 1, 0);
end
