function candidate = merge_frozen_and_rescheduled_schedule( ...
    constraints, decodedCandidate, cancel)
%MERGE_FROZEN_AND_RESCHEDULED_SCHEDULE Merge frozen prefix with decoded suffix.
%   candidate = MERGE_FROZEN_AND_RESCHEDULED_SCHEDULE(constraints,
%   decodedCandidate, cancel) creates complete machineTable and AGVTable
%   candidates by combining frozen occupancy with rescheduled suffix tasks.

if nargin < 3
    error('merge_frozen_and_rescheduled_schedule:MissingInput', ...
        'constraints, decodedCandidate, and cancel are required.');
end

require_constraints(constraints);
require_decoded_candidate(decodedCandidate);
require_cancel_consistency(constraints.cancel, cancel);

candidate = decodedCandidate;
candidate.machineTable = merge_machine_tables( ...
    constraints.frozen_machine_occupancy, decodedCandidate.machineTable, ...
    constraints.earliest_start_time);
candidate.AGVTable = merge_agv_tables( ...
    constraints.frozen_agv_occupancy, decodedCandidate.AGVTable, ...
    constraints.earliest_start_time);
candidate.report.mergeCheck = check_merged_candidate(candidate, cancel);
candidate.isFeasible = decodedCandidate.isFeasible && ...
    candidate.report.mergeCheck.isFeasible;

if ~candidate.report.mergeCheck.isFeasible
    candidate.report.errors = [candidate.report.errors, ...
        candidate.report.mergeCheck.errors];
end
end

function require_constraints(constraints)
requiredFields = {'cancel', 'earliest_start_time', ...
    'frozen_machine_occupancy', 'frozen_agv_occupancy'};

for i = 1:numel(requiredFields)
    if ~isstruct(constraints) || ~isfield(constraints, requiredFields{i})
        error('merge_frozen_and_rescheduled_schedule:InvalidConstraints', ...
            'constraints.%s is required.', requiredFields{i});
    end
end
end

function require_decoded_candidate(decodedCandidate)
requiredFields = {'machineTable', 'AGVTable', 'excluded_operations', ...
    'isFeasible', 'report'};

for i = 1:numel(requiredFields)
    if ~isstruct(decodedCandidate) || ...
            ~isfield(decodedCandidate, requiredFields{i})
        error('merge_frozen_and_rescheduled_schedule:InvalidCandidate', ...
            'decodedCandidate.%s is required.', requiredFields{i});
    end
end
end

function require_cancel_consistency(sourceCancel, cancel)
if ~isfield(sourceCancel, 'job_id') || ~isfield(cancel, 'job_id') || ...
        sourceCancel.job_id ~= cancel.job_id
    error('merge_frozen_and_rescheduled_schedule:CancelMismatch', ...
        'constraints.cancel.job_id must match cancel.job_id.');
end

if ~isfield(sourceCancel, 'cancel_time') || ...
        ~isfield(cancel, 'cancel_time') || ...
        sourceCancel.cancel_time ~= cancel.cancel_time
    error('merge_frozen_and_rescheduled_schedule:CancelMismatch', ...
        'constraints.cancel.cancel_time must match cancel.cancel_time.');
end
end

function machineTable = merge_machine_tables( ...
    frozenOccupancy, suffixMachineTable, earliestStartTime)
machineNum = max(numel(suffixMachineTable), max_machine_id(frozenOccupancy));
machineTable = cell(1, machineNum);

for machineIdx = 1:machineNum
    blocks = empty_machine_blocks();
    blocks = append_frozen_machine_blocks(blocks, frozenOccupancy, machineIdx);
    blocks = append_suffix_machine_blocks( ...
        blocks, suffixMachineTable, machineIdx, earliestStartTime);
    machineTable{machineIdx} = finalize_machine_blocks(blocks);
end
end

function AGVTable = merge_agv_tables( ...
    frozenOccupancy, suffixAGVTable, earliestStartTime)
agvNum = max(numel(suffixAGVTable), max_agv_id(frozenOccupancy));
AGVTable = cell(1, agvNum);

for agvIdx = 1:agvNum
    blocks = empty_agv_blocks();
    blocks = append_frozen_agv_blocks(blocks, frozenOccupancy, agvIdx);
    blocks = append_suffix_agv_blocks( ...
        blocks, suffixAGVTable, agvIdx, earliestStartTime);
    AGVTable{agvIdx} = finalize_agv_blocks(blocks);
end
end

function blocks = append_frozen_machine_blocks(blocks, occupancy, machineIdx)
for i = 1:numel(occupancy)
    if occupancy(i).machine_id ~= machineIdx
        continue
    end

    blocks(end + 1) = make_machine_block( ...
        occupancy(i).start_time, occupancy(i).end_time, ...
        occupancy(i).job_id, occupancy(i).operation_id);
end
end

function blocks = append_suffix_machine_blocks( ...
    blocks, suffixMachineTable, machineIdx, earliestStartTime)
if machineIdx > numel(suffixMachineTable)
    return
end

suffixBlocks = suffixMachineTable{machineIdx};
for i = 1:numel(suffixBlocks)
    block = suffixBlocks(i);
    if block.job <= 0
        continue
    end
    if block.start < earliestStartTime
        error('merge_frozen_and_rescheduled_schedule:InvalidSuffixStart', ...
            'Rescheduled machine operation starts before cancel_time.');
    end

    blocks(end + 1) = make_machine_block( ...
        block.start, block.end, block.job, block.opera);
end
end

function blocks = append_frozen_agv_blocks(blocks, occupancy, agvIdx)
for i = 1:numel(occupancy)
    if occupancy(i).agv_id ~= agvIdx
        continue
    end

    blocks(end + 1) = make_agv_block( ...
        occupancy(i).start_time, occupancy(i).end_time, ...
        occupancy(i).job_id, occupancy(i).operation_id, ...
        occupancy(i).from_machine, occupancy(i).to_machine, 0);
end
end

function blocks = append_suffix_agv_blocks( ...
    blocks, suffixAGVTable, agvIdx, earliestStartTime)
if agvIdx > numel(suffixAGVTable)
    return
end

suffixBlocks = suffixAGVTable{agvIdx};
for i = 1:numel(suffixBlocks)
    block = suffixBlocks(i);
    if block.job <= 0
        continue
    end
    if block.start < earliestStartTime
        error('merge_frozen_and_rescheduled_schedule:InvalidSuffixStart', ...
            'Rescheduled AGV task starts before cancel_time.');
    end

    blocks(end + 1) = make_agv_block( ...
        block.start, block.end, block.job, block.opera, ...
        field_or_default(block, 'from_machine', -1), ...
        field_or_default(block, 'to_machine', -1), ...
        field_or_default(block, 'status', 0));
end
end

function blocks = finalize_machine_blocks(blocks)
if isempty(blocks)
    blocks = make_machine_block(0, inf, 0, 0);
    return
end

[~, order] = sortrows([[blocks.start]', [blocks.end]'], [1, 2]);
blocks = blocks(order);
lastEnd = max([blocks.end]);
blocks(end + 1) = make_machine_block(lastEnd, inf, 0, 0);
end

function blocks = finalize_agv_blocks(blocks)
if isempty(blocks)
    blocks = make_agv_block(0, 0, 0, 0, -1, -1, 0);
    blocks(2) = make_agv_block(0, inf, 0, 0, -1, -1, 0);
    return
end

[~, order] = sortrows([[blocks.start]', [blocks.end]'], [1, 2]);
blocks = blocks(order);
lastEnd = max([blocks.end]);
lastToMachine = blocks(end).to_machine;
blocks(end + 1) = make_agv_block( ...
    lastEnd, inf, 0, 0, lastToMachine, lastToMachine, 0);
end

function report = check_merged_candidate(candidate, cancel)
report = struct();
report.errors = {};

report = check_excluded_operations_absent( ...
    report, candidate.machineTable, candidate.excluded_operations);
report = check_cancelled_unfinished_agv_absent( ...
    report, candidate.AGVTable, candidate.excluded_operations);

report.isFeasible = isempty(report.errors);
end

function report = check_excluded_operations_absent( ...
    report, machineTable, excludedOperations)
for i = 1:numel(excludedOperations)
    excluded = excludedOperations(i);
    if operation_exists(machineTable, ...
            excluded.job_id, excluded.operation_id)
        report.errors{end + 1} = sprintf( ...
            'Excluded operation job %d operation %d appears in machineTable.', ...
            excluded.job_id, excluded.operation_id);
    end
end
end

function report = check_cancelled_unfinished_agv_absent( ...
    report, AGVTable, excludedOperations)
for i = 1:numel(excludedOperations)
    excluded = excludedOperations(i);
    if agv_task_exists(AGVTable, excluded.job_id, excluded.operation_id)
        report.errors{end + 1} = sprintf( ...
            'Excluded operation job %d operation %d appears in AGVTable.', ...
            excluded.job_id, excluded.operation_id);
    end
end
end

function exists = operation_exists(machineTable, jobId, operationId)
exists = false;
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            exists = true;
            return
        end
    end
end
end

function exists = agv_task_exists(AGVTable, jobId, operationId)
exists = false;
for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            exists = true;
            return
        end
    end
end
end

function value = field_or_default(record, fieldName, defaultValue)
if isfield(record, fieldName)
    value = record.(fieldName);
else
    value = defaultValue;
end
end

function machineId = max_machine_id(occupancy)
if isempty(occupancy)
    machineId = 0;
else
    machineId = max([occupancy.machine_id]);
end
end

function agvId = max_agv_id(occupancy)
if isempty(occupancy)
    agvId = 0;
else
    agvId = max([occupancy.agv_id]);
end
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end

function block = make_agv_block(startTime, endTime, jobId, operationId, ...
    fromMachine, toMachine, status)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.from_machine = fromMachine;
block.to_machine = toMachine;
block.status = status;
block.load_status = [];
block.charge = [];
end

function blocks = empty_machine_blocks()
blocks = repmat(make_machine_block([], [], [], []), 1, 0);
end

function blocks = empty_agv_blocks()
blocks = repmat(make_agv_block([], [], [], [], [], [], []), 1, 0);
end

