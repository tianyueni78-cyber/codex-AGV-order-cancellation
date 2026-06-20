function [isFeasible, report] = check_job_operation_sequence(problem, machineTable, cancel)
%CHECK_JOB_OPERATION_SEQUENCE Check per-job operation order in machineTable.
%   [isFeasible, report] = CHECK_JOB_OPERATION_SEQUENCE(problem,
%   machineTable, cancel) checks remaining real operations. Deleted
%   unfinished operations of the cancelled job are not required to exist.

if nargin < 3
    error('check_job_operation_sequence:MissingInput', ...
        'problem, machineTable, and cancel are required.');
end

report = empty_report();
report = validate_inputs(problem, machineTable, cancel, report);

if ~isempty(report.errors)
    isFeasible = false;
    report.isFeasible = isFeasible;
    return
end

operations = collect_real_operations(machineTable);
report.checkedOperationCount = numel(operations);

for jobId = 1:problem.jobNum
    jobOperations = select_job_operations(operations, jobId);
    if isempty(jobOperations)
        continue
    end

    report = check_operation_ids(problem, jobOperations, jobId, report);
    report = check_single_job_sequence(jobOperations, jobId, report);
end

isFeasible = isempty(report.errors);
report.isFeasible = isFeasible;
end

function report = validate_inputs(problem, machineTable, cancel, report)
if ~isstruct(problem) || ~isfield(problem, 'jobNum') || ...
        ~isfield(problem, 'operaNumVec')
    report.errors{end + 1} = ...
        'problem.jobNum and problem.operaNumVec are required.';
end

if ~iscell(machineTable)
    report.errors{end + 1} = 'machineTable must be a cell array.';
end

if ~isstruct(cancel) || ~isfield(cancel, 'job_id')
    report.errors{end + 1} = 'cancel.job_id is required.';
end
end

function operations = collect_real_operations(machineTable)
operations = empty_operation_array();

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
        operation.machine_id = machineIdx;
        operation.block_index = blockIdx;
        operation.job_id = block.job;
        operation.operation_id = block.opera;
        operation.start_time = block.start;
        operation.end_time = block.end;
        operations(end + 1) = operation;
    end
end
end

function require_block_fields(blocks, machineIdx)
requiredFields = {'start', 'end', 'job', 'opera'};
for i = 1:numel(requiredFields)
    if ~isfield(blocks, requiredFields{i})
        error('check_job_operation_sequence:InvalidMachineBlock', ...
            'machineTable{%d} blocks require field %s.', ...
            machineIdx, requiredFields{i});
    end
end
end

function jobOperations = select_job_operations(operations, jobId)
jobOperations = empty_operation_array();

for i = 1:numel(operations)
    if operations(i).job_id == jobId
        jobOperations(end + 1) = operations(i);
    end
end
end

function report = check_operation_ids(problem, jobOperations, jobId, report)
operationIds = [jobOperations.operation_id];
if any(operationIds < 1) || any(operationIds ~= fix(operationIds))
    report.errors{end + 1} = sprintf( ...
        'job %d has invalid operation ids.', jobId);
end

if jobId <= numel(problem.operaNumVec)
    maxOperationId = problem.operaNumVec(jobId);
    if any(operationIds > maxOperationId)
        report.errors{end + 1} = sprintf( ...
            'job %d has operation id beyond problem.operaNumVec.', jobId);
    end
end

if numel(unique(operationIds)) ~= numel(operationIds)
    report.errors{end + 1} = sprintf( ...
        'job %d has duplicate operation ids.', jobId);
end
end

function report = check_single_job_sequence(jobOperations, jobId, report)
[~, order] = sort([jobOperations.operation_id]);
jobOperations = jobOperations(order);

for i = 2:numel(jobOperations)
    previous = jobOperations(i - 1);
    current = jobOperations(i);

    if current.operation_id <= previous.operation_id
        report.errors{end + 1} = sprintf( ...
            'job %d operation ids are not strictly increasing.', jobId);
    end

    if current.start_time < previous.end_time
        report.errors{end + 1} = sprintf( ...
            ['job %d operation %d starts before operation %d completes: ', ...
            '%.6f < %.6f.'], jobId, current.operation_id, ...
            previous.operation_id, current.start_time, previous.end_time);
    end

    if current.end_time < previous.end_time
        report.errors{end + 1} = sprintf( ...
            ['job %d operation %d completes before operation %d: ', ...
            '%.6f < %.6f.'], jobId, current.operation_id, ...
            previous.operation_id, current.end_time, previous.end_time);
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
