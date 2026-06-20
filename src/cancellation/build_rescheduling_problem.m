function reschedulingProblem = build_rescheduling_problem( ...
    problem, machineData, agvData, remainingSet, cancel)
%BUILD_RESCHEDULING_PROBLEM Build a temporary problem for remaining tasks.
%   reschedulingProblem = BUILD_RESCHEDULING_PROBLEM(problem, machineData,
%   agvData, remainingSet, cancel) creates a reduced FJSP-AGV problem that
%   contains only unfinished non-cancelled operations.

if nargin < 5
    error('build_rescheduling_problem:MissingInput', ...
        'problem, machineData, agvData, remainingSet, and cancel are required.');
end

require_problem(problem);
require_remaining_set(remainingSet);
require_cancel_consistency(remainingSet, cancel);

reschedulingProblem = empty_rescheduling_problem();
reschedulingProblem.cancel = cancel;
reschedulingProblem.machineData = machineData;
reschedulingProblem.agvData = agvData;
reschedulingProblem.excluded_operations = remainingSet.excluded_operations;

if ~remainingSet.isFeasible
    reschedulingProblem.isFeasible = false;
    reschedulingProblem.report.errors{end + 1} = ...
        'Remaining operation set is infeasible.';
    reschedulingProblem.report.rejectedReasons{end + 1} = ...
        'remaining_operation_set_infeasible';
    return
end

[tempProblem, operationMap, errors] = build_temporary_problem( ...
    problem, remainingSet.operations, cancel);

reschedulingProblem.problem = tempProblem;
reschedulingProblem.operation_map = operationMap;
reschedulingProblem.report.errors = [reschedulingProblem.report.errors, errors];
reschedulingProblem.report.remainingOperationCount = ...
    numel(remainingSet.operations);
reschedulingProblem.report.tempJobCount = tempProblem.jobNum;
reschedulingProblem.report.excludedOperationCount = ...
    numel(reschedulingProblem.excluded_operations);
reschedulingProblem.isFeasible = isempty(reschedulingProblem.report.errors);
end

function require_problem(problem)
requiredFields = {'jobNum', 'machineNum', 'operaNumVec', ...
    'candidateMachine', 'jobInfo'};

for i = 1:numel(requiredFields)
    if ~isstruct(problem) || ~isfield(problem, requiredFields{i})
        error('build_rescheduling_problem:InvalidProblem', ...
            'problem.%s is required.', requiredFields{i});
    end
end
end

function require_remaining_set(remainingSet)
requiredFields = {'cancel', 'operations', 'excluded_operations', 'isFeasible'};

for i = 1:numel(requiredFields)
    if ~isstruct(remainingSet) || ~isfield(remainingSet, requiredFields{i})
        error('build_rescheduling_problem:InvalidRemainingSet', ...
            'remainingSet.%s is required.', requiredFields{i});
    end
end
end

function require_cancel_consistency(remainingSet, cancel)
if ~isfield(remainingSet.cancel, 'job_id') || ...
        ~isfield(cancel, 'job_id') || ...
        remainingSet.cancel.job_id ~= cancel.job_id
    error('build_rescheduling_problem:CancelMismatch', ...
        'remainingSet.cancel.job_id must match cancel.job_id.');
end

if ~isfield(remainingSet.cancel, 'cancel_time') || ...
        ~isfield(cancel, 'cancel_time') || ...
        remainingSet.cancel.cancel_time ~= cancel.cancel_time
    error('build_rescheduling_problem:CancelMismatch', ...
        'remainingSet.cancel.cancel_time must match cancel.cancel_time.');
end
end

function [tempProblem, operationMap, errors] = build_temporary_problem( ...
    problem, operations, cancel)
errors = {};
tempProblem = struct();
tempProblem.jobNum = 0;
tempProblem.machineNum = problem.machineNum;
tempProblem.operaNumVec = [];
tempProblem.candidateMachine = {};
tempProblem.jobInfo = {};
tempProblem.original_job_ids = [];

operationMap = empty_operation_map();

originalJobIds = unique([operations.job_id], 'stable');
originalJobIds = originalJobIds(originalJobIds ~= cancel.job_id);
tempProblem.jobNum = numel(originalJobIds);
tempProblem.original_job_ids = originalJobIds;
tempProblem.operaNumVec = zeros(1, tempProblem.jobNum);
tempProblem.candidateMachine = cell(tempProblem.jobNum, 0);
tempProblem.jobInfo = cell(1, tempProblem.jobNum);

maxRemainingOps = 0;
for tempJobId = 1:numel(originalJobIds)
    originalJobId = originalJobIds(tempJobId);
    jobOperations = operations([operations.job_id] == originalJobId);
    [~, order] = sort([jobOperations.operation_id]);
    jobOperations = jobOperations(order);

    opCount = numel(jobOperations);
    tempProblem.operaNumVec(tempJobId) = opCount;
    maxRemainingOps = max(maxRemainingOps, opCount);
    tempProblem.jobInfo{tempJobId} = zeros(opCount, problem.machineNum);

    for tempOperationId = 1:opCount
        originalOperation = jobOperations(tempOperationId);
        originalOperationId = originalOperation.operation_id;

        if originalJobId > numel(problem.jobInfo) || ...
                originalOperationId > size(problem.jobInfo{originalJobId}, 1)
            errors{end + 1} = 'Remaining operation is outside problem.jobInfo.';
            continue
        end

        tempProblem.jobInfo{tempJobId}(tempOperationId, :) = ...
            problem.jobInfo{originalJobId}(originalOperationId, :);

        if size(problem.candidateMachine, 1) >= originalJobId && ...
                size(problem.candidateMachine, 2) >= originalOperationId
            tempProblem.candidateMachine{tempJobId, tempOperationId} = ...
                problem.candidateMachine{originalJobId, originalOperationId};
        else
            tempProblem.candidateMachine{tempJobId, tempOperationId} = ...
                candidate_from_job_info( ...
                tempProblem.jobInfo{tempJobId}(tempOperationId, :));
        end

        operationMap(end + 1) = make_operation_map( ...
            tempJobId, tempOperationId, originalOperation);
    end
end

if maxRemainingOps > 0
    tempProblem.candidateMachine = ...
        tempProblem.candidateMachine(:, 1:maxRemainingOps);
end
end

function candidateMachines = candidate_from_job_info(jobInfoRow)
candidateMachines = find(isfinite(jobInfoRow));
end

function mapRecord = make_operation_map(tempJobId, tempOperationId, ...
    originalOperation)
mapRecord = struct();
mapRecord.temp_job_id = tempJobId;
mapRecord.temp_operation_id = tempOperationId;
mapRecord.original_job_id = originalOperation.job_id;
mapRecord.original_operation_id = originalOperation.operation_id;
mapRecord.original_machine_id = originalOperation.machine_id;
mapRecord.original_start_time = originalOperation.start_time;
mapRecord.original_end_time = originalOperation.end_time;
end

function reschedulingProblem = empty_rescheduling_problem()
reschedulingProblem = struct();
reschedulingProblem.cancel = struct();
reschedulingProblem.problem = struct();
reschedulingProblem.machineData = struct();
reschedulingProblem.agvData = struct();
reschedulingProblem.operation_map = empty_operation_map();
reschedulingProblem.excluded_operations = struct([]);
reschedulingProblem.isFeasible = true;
reschedulingProblem.report = struct();
reschedulingProblem.report.errors = {};
reschedulingProblem.report.warnings = {};
reschedulingProblem.report.rejectedReasons = {};
reschedulingProblem.report.remainingOperationCount = 0;
reschedulingProblem.report.tempJobCount = 0;
reschedulingProblem.report.excludedOperationCount = 0;
end

function operationMap = empty_operation_map()
operationMap = repmat(struct( ...
    'temp_job_id', [], ...
    'temp_operation_id', [], ...
    'original_job_id', [], ...
    'original_operation_id', [], ...
    'original_machine_id', [], ...
    'original_start_time', [], ...
    'original_end_time', []), 1, 0);
end

