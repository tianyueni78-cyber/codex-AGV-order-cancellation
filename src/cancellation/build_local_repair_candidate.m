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
[candidate.machineTable, candidate.AGVTable] = prune_cancelled_job_records( ...
    candidate.machineTable, candidate.AGVTable, cancel.job_id);
[machineIsFeasible, machineReport] = ...
    check_machine_table_feasibility(candidate.machineTable);
candidate.report.machineConflictCheck = machineReport;
if ~candidate.isFeasible
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
    [candidate.machineTable, candidate.AGVTable] = prune_cancelled_job_records( ...
        candidate.machineTable, candidate.AGVTable, cancel.job_id);
    candidate = mark_final_feasibility(candidate);
    return
end

candidate.AGVTable = agvCandidate.AGVTable;
candidate.removed_agv_tasks = agvCandidate.removed_agv_tasks;
candidate.report.removedAgvTaskCount = ...
    agvCandidate.report.removedAgvTaskCount;
candidate.report = append_check_errors(candidate.report, machineReport);
[candidate.machineTable, candidate.AGVTable] = prune_cancelled_job_records( ...
    candidate.machineTable, candidate.AGVTable, cancel.job_id);

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

function [machineTable, AGVTable] = prune_cancelled_job_records( ...
    machineTable, AGVTable, jobId)
machineTable = prune_job_from_table(machineTable, jobId, 'job');
AGVTable = prune_job_from_table(AGVTable, jobId, 'job');
end

function tableValue = prune_job_from_table(tableValue, jobId, fieldName)
if ~iscell(tableValue)
    return
end

for outerIdx = 1:numel(tableValue)
    blocks = tableValue{outerIdx};
    if isempty(blocks) || ~isstruct(blocks)
        continue
    end

    keep = true(1, numel(blocks));
    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if isfield(block, fieldName) && block.(fieldName) == jobId
            keep(blockIdx) = false;
        end
    end
    tableValue{outerIdx} = blocks(keep);
end
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
