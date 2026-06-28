function candidate = build_local_repair_candidate(problem, schedule, state, cancel)
%BUILD_LOCAL_REPAIR_CANDIDATE Build first-version local repair candidate.
%   candidate = BUILD_LOCAL_REPAIR_CANDIDATE(problem, schedule, state,
%   cancel) combines machine deletion, AGV deletion, and feasibility checks.
%   It does not move remaining tasks or run search.

if nargin < 4
    error('build_local_repair_candidate:MissingInput', ...
        'problem, schedule, state, and cancel are required.');
end

candidate = remove_cancelled_machine_operations( ...
    problem, schedule, state, cancel);
[machineIsFeasible, machineReport] = ...
    check_machine_table_feasibility(candidate.machineTable);
candidate.report.machineConflictCheck = machineReport;
if ~candidate.isFeasible
    candidate.AGVTable = prune_unstarted_cancelled_agv_tasks( ...
        candidate.AGVTable, cancel);
    candidate = mark_final_feasibility(candidate);
    return
end

intermediateSchedule = struct();
intermediateSchedule.machineTable = candidate.machineTable;
intermediateSchedule.AGVTable = candidate.AGVTable;

agvCandidate = remove_cancelled_agv_tasks( ...
    problem, intermediateSchedule, state, cancel);
if ~agvCandidate.isFeasible
    candidate.report.agvConflictCheck = agvCandidate.report;
    candidate = merge_agv_candidate(candidate, agvCandidate);
    candidate.AGVTable = prune_unstarted_cancelled_agv_tasks( ...
        candidate.AGVTable, cancel);
    candidate.report.removedFinalUnstartedCanceledAgvTaskCount = ...
        count_removed_unstarted_cancelled_agv_tasks( ...
        agvCandidate.AGVTable, candidate.AGVTable, cancel);
    candidate.report.remainingFinalUnstartedCanceledAgvTaskCount = ...
        count_remaining_unstarted_cancelled_agv_tasks(candidate.AGVTable, ...
        cancel);
    candidate = mark_final_feasibility(candidate);
    return
end

candidate.AGVTable = agvCandidate.AGVTable;
candidate.AGVTable = prune_unstarted_cancelled_agv_tasks( ...
    candidate.AGVTable, cancel);
candidate.removed_agv_tasks = agvCandidate.removed_agv_tasks;
candidate.report.removedAgvTaskCount = ...
    agvCandidate.report.removedAgvTaskCount;
candidate.report.frozenProcessingAgvTaskCount = ...
    agvCandidate.report.frozenProcessingAgvTaskCount;
candidate.report.frozenProcessingAgvTasks = ...
    agvCandidate.report.frozenProcessingAgvTasks;
candidate.report.unknownAgvTaskCount = ...
    agvCandidate.report.unknownAgvTaskCount;
candidate.report.unknownAgvTasks = agvCandidate.report.unknownAgvTasks;
candidate.report = append_check_errors(candidate.report, machineReport);

[agvIsFeasible, agvReport] = ...
    check_agv_table_feasibility(candidate.AGVTable);
candidate.report.agvConflictCheck = agvReport;
candidate.report = append_check_errors(candidate.report, agvReport);

[sequenceIsFeasible, sequenceReport] = ...
    check_job_operation_sequence(problem, candidate.machineTable, cancel);
candidate.report.jobSequenceCheck = sequenceReport;
candidate.report = append_check_errors(candidate.report, sequenceReport);

candidate.isFeasible = machineIsFeasible && agvIsFeasible && ...
    sequenceIsFeasible && isempty(candidate.report.errors) && ...
    isempty(candidate.report.rejectedReasons);
end

function AGVTable = prune_unstarted_cancelled_agv_tasks(AGVTable, cancel)
if ~iscell(AGVTable)
    return
end

for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    if isempty(blocks) || ~isstruct(blocks)
        continue
    end

    keep = true(1, numel(blocks));
    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if ~isfield(block, 'job') || block.job ~= cancel.job_id
            continue
        end

        startTime = read_optional_time(block, 'start');
        endTime = read_optional_time(block, 'end');
        if ~isempty(startTime) && ~isempty(endTime) && ...
                startTime > cancel.cancel_time
            keep(blockIdx) = false;
        end
    end
    AGVTable{agvIdx} = blocks(keep);
end
end

function count = count_removed_unstarted_cancelled_agv_tasks( ...
    beforeAGVTable, afterAGVTable, cancel)
count = count_unstarted_cancelled_agv_tasks(beforeAGVTable, cancel) - ...
    count_unstarted_cancelled_agv_tasks(afterAGVTable, cancel);
if count < 0
    count = 0;
end
end

function count = count_remaining_unstarted_cancelled_agv_tasks(AGVTable, ...
    cancel)
count = count_unstarted_cancelled_agv_tasks(AGVTable, cancel);
end

function count = count_unstarted_cancelled_agv_tasks(AGVTable, cancel)
count = 0;
if ~iscell(AGVTable) || ~isstruct(cancel) || ~isfield(cancel, 'job_id')
    return
end

for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    if isempty(blocks) || ~isstruct(blocks)
        continue
    end

    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if ~isfield(block, 'job') || block.job ~= cancel.job_id
            continue
        end

        startTime = read_optional_time(block, 'start');
        endTime = read_optional_time(block, 'end');
        if isempty(startTime) || isempty(endTime)
            continue
        end

        if startTime > cancel.cancel_time
            count = count + 1;
        end
    end
end
end

function value = read_optional_time(block, fieldName)
value = [];
if ~isstruct(block) || ~isfield(block, fieldName)
    return
end
fieldValue = block.(fieldName);
if ~isnumeric(fieldValue) || ~isscalar(fieldValue) || ~isfinite(fieldValue)
    return
end
value = fieldValue;
end

function candidate = merge_agv_candidate(candidate, agvCandidate)
candidate.AGVTable = agvCandidate.AGVTable;
candidate.removed_agv_tasks = agvCandidate.removed_agv_tasks;
candidate.report.errors = [candidate.report.errors, ...
    agvCandidate.report.errors];
candidate.report.warnings = [candidate.report.warnings, ...
    agvCandidate.report.warnings];
candidate.report.rejectedReasons = [candidate.report.rejectedReasons, ...
    agvCandidate.report.rejectedReasons];
candidate.report.removedAgvTaskCount = ...
    agvCandidate.report.removedAgvTaskCount;
end

function report = append_check_errors(report, checkReport)
for i = 1:numel(checkReport.errors)
    report.errors{end + 1} = checkReport.errors{i};
end

for i = 1:numel(checkReport.warnings)
    report.warnings{end + 1} = checkReport.warnings{i};
end
end

function candidate = mark_final_feasibility(candidate)
candidate.isFeasible = isempty(candidate.report.errors) && ...
    isempty(candidate.report.rejectedReasons);
end
