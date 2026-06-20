function candidate = decode_complete_rescheduling_candidate( ...
    reschedulingProblem, constraints, chrom, config)
%DECODE_COMPLETE_RESCHEDULING_CANDIDATE Decode a complete rescheduling chrom.
%   candidate = DECODE_COMPLETE_RESCHEDULING_CANDIDATE(reschedulingProblem,
%   constraints, chrom, config) reuses decode_chromosome_independent for the
%   temporary remaining-operation problem, then maps temporary job and
%   operation ids back to the original problem ids.

if nargin < 4
    error('decode_complete_rescheduling_candidate:MissingInput', ...
        'reschedulingProblem, constraints, chrom, and config are required.');
end

require_rescheduling_problem(reschedulingProblem);
require_constraints(constraints);

candidate = empty_candidate();
candidate.excluded_operations = reschedulingProblem.excluded_operations;

if ~reschedulingProblem.isFeasible
    candidate.report.rejectedReasons{end + 1} = ...
        'rescheduling_problem_infeasible';
    candidate.report.errors{end + 1} = ...
        'Rescheduling problem is infeasible.';
    return
end

if ~constraints.isFeasible
    candidate.report.rejectedReasons{end + 1} = ...
        'rescheduling_constraints_infeasible';
    candidate.report.errors{end + 1} = ...
        'Rescheduling constraints are infeasible.';
    return
end

decodeConfig = prepare_decode_config(config, ...
    reschedulingProblem.problem, reschedulingProblem.agvData, constraints);

[decodedSchedule, decodeReport] = decode_chromosome_independent( ...
    chrom, reschedulingProblem.problem, reschedulingProblem.machineData, ...
    reschedulingProblem.agvData, decodeConfig);

candidate.report.decodeReport = decodeReport;
if ~decodeReport.isValid
    candidate.report.errors = [candidate.report.errors, decodeReport.errors];
    candidate.report.rejectedReasons{end + 1} = ...
        'independent_decode_failed';
    return
end

candidate.decodedSchedule = decodedSchedule;
candidate.machineTable = map_machine_table_to_original_ids( ...
    decodedSchedule.machineTable, reschedulingProblem.operation_map);
candidate.AGVTable = map_agv_table_to_original_ids( ...
    decodedSchedule.AGVTable, reschedulingProblem.operation_map);
candidate.jobCompleteUnLoad = map_job_complete_unload( ...
    decodedSchedule.jobCompleteUnLoad, reschedulingProblem.operation_map);
candidate.rescheduled_operations = collect_rescheduled_operations( ...
    candidate.machineTable);

candidate.report.rescheduledOperationCount = ...
    numel(candidate.rescheduled_operations);
candidate.report.excludedOperationCount = ...
    numel(candidate.excluded_operations);
candidate.report.cancelledTaskExclusionCheck = ...
    check_cancelled_task_exclusion(candidate, reschedulingProblem.cancel);
candidate.isFeasible = candidate.report.cancelledTaskExclusionCheck.isFeasible;
end

function require_rescheduling_problem(reschedulingProblem)
requiredFields = {'cancel', 'problem', 'machineData', 'agvData', ...
    'operation_map', 'excluded_operations', 'isFeasible'};

for i = 1:numel(requiredFields)
    if ~isstruct(reschedulingProblem) || ...
            ~isfield(reschedulingProblem, requiredFields{i})
        error('decode_complete_rescheduling_candidate:InvalidProblem', ...
            'reschedulingProblem.%s is required.', requiredFields{i});
    end
end
end

function require_constraints(constraints)
requiredFields = {'earliest_start_time', 'isFeasible'};

for i = 1:numel(requiredFields)
    if ~isstruct(constraints) || ~isfield(constraints, requiredFields{i})
        error('decode_complete_rescheduling_candidate:InvalidConstraints', ...
            'constraints.%s is required.', requiredFields{i});
    end
end
end

function decodeConfig = prepare_decode_config(config, problem, agvData, ...
    constraints)
decodeConfig = config;

if ~isfield(decodeConfig, 'machineTable') || ...
        isempty(decodeConfig.machineTable)
    decodeConfig.machineTable = create_initial_machine_table( ...
        problem.machineNum, constraints.earliest_start_time);
end

if ~isfield(decodeConfig, 'AGVTable') || isempty(decodeConfig.AGVTable)
    decodeConfig.AGVTable = create_initial_agv_table( ...
        agvData.AGVNum, constraints.earliest_start_time);
end
end

function machineTable = create_initial_machine_table(machineNum, startTime)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = struct( ...
        'start', startTime, ...
        'end', inf, ...
        'job', 0, ...
        'opera', 0);
end
end

function AGVTable = create_initial_agv_table(AGVNum, startTime)
AGVTable = cell(1, AGVNum);
for agvIdx = 1:AGVNum
    AGVTable{agvIdx} = repmat(struct( ...
        'start', startTime, ...
        'end', startTime, ...
        'job', 0, ...
        'opera', 0, ...
        'from_machine', -1, ...
        'to_machine', -1, ...
        'status', 0), 1, 2);
    AGVTable{agvIdx}(2).end = inf;
end
end

function machineTable = map_machine_table_to_original_ids( ...
    machineTable, operationMap)
for machineIdx = 1:numel(machineTable)
    for blockIdx = 1:numel(machineTable{machineIdx})
        block = machineTable{machineIdx}(blockIdx);
        if block.job <= 0
            continue
        end

        mapRecord = find_operation_map(operationMap, block.job, block.opera);
        machineTable{machineIdx}(blockIdx).job = mapRecord.original_job_id;
        machineTable{machineIdx}(blockIdx).opera = ...
            mapRecord.original_operation_id;
    end
end
end

function AGVTable = map_agv_table_to_original_ids(AGVTable, operationMap)
for agvIdx = 1:numel(AGVTable)
    for blockIdx = 1:numel(AGVTable{agvIdx})
        block = AGVTable{agvIdx}(blockIdx);
        if block.job <= 0 || block.opera <= 0
            continue
        end

        mapRecord = find_operation_map(operationMap, block.job, block.opera);
        AGVTable{agvIdx}(blockIdx).job = mapRecord.original_job_id;
        AGVTable{agvIdx}(blockIdx).opera = mapRecord.original_operation_id;
    end
end
end

function jobCompleteUnLoad = map_job_complete_unload( ...
    tempJobCompleteUnLoad, operationMap)
if isempty(operationMap)
    jobCompleteUnLoad = [];
    return
end

originalJobIds = unique([operationMap.original_job_id], 'stable');
jobCompleteUnLoad = zeros(1, max(originalJobIds));
for i = 1:numel(originalJobIds)
    originalJobId = originalJobIds(i);
    tempJobId = operationMap(find( ...
        [operationMap.original_job_id] == originalJobId, 1)).temp_job_id;
    jobCompleteUnLoad(originalJobId) = tempJobCompleteUnLoad(tempJobId);
end
end

function mapRecord = find_operation_map(operationMap, tempJobId, ...
    tempOperationId)
for i = 1:numel(operationMap)
    if operationMap(i).temp_job_id == tempJobId && ...
            operationMap(i).temp_operation_id == tempOperationId
        mapRecord = operationMap(i);
        return
    end
end

error('decode_complete_rescheduling_candidate:MissingOperationMap', ...
    'operation_map does not contain temp job %d operation %d.', ...
    tempJobId, tempOperationId);
end

function operations = collect_rescheduled_operations(machineTable)
operations = empty_operation_array();
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
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
        operations(end + 1) = operation;
    end
end
end

function report = check_cancelled_task_exclusion(candidate, cancel)
report = struct();
report.errors = {};
report.isFeasible = true;

for i = 1:numel(candidate.rescheduled_operations)
    operation = candidate.rescheduled_operations(i);
    if operation.job_id == cancel.job_id
        report.errors{end + 1} = sprintf( ...
            'Cancelled job %d operation %d appeared in decoded schedule.', ...
            operation.job_id, operation.operation_id);
    end
end

report.isFeasible = isempty(report.errors);
end

function candidate = empty_candidate()
candidate = struct();
candidate.machineTable = {};
candidate.AGVTable = {};
candidate.jobCompleteUnLoad = [];
candidate.decodedSchedule = struct();
candidate.rescheduled_operations = empty_operation_array();
candidate.excluded_operations = struct([]);
candidate.isFeasible = false;
candidate.report = struct();
candidate.report.errors = {};
candidate.report.warnings = {};
candidate.report.rejectedReasons = {};
candidate.report.decodeReport = struct();
candidate.report.rescheduledOperationCount = 0;
candidate.report.excludedOperationCount = 0;
candidate.report.cancelledTaskExclusionCheck = struct();
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

