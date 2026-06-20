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
    candidate = merge_agv_candidate(candidate, agvCandidate);
    candidate = mark_final_feasibility(candidate);
    return
end

candidate.AGVTable = agvCandidate.AGVTable;
candidate.removed_agv_tasks = agvCandidate.removed_agv_tasks;
candidate.report.removedAgvTaskCount = ...
    agvCandidate.report.removedAgvTaskCount;

[machineIsFeasible, machineReport] = ...
    check_machine_table_feasibility(candidate.machineTable);
candidate.report.machineConflictCheck = machineReport;
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
