function [metrics, report] = evaluate_candidate_td( ...
    baselineSchedule, candidateSchedule, cancel)
%EVALUATE_CANDIDATE_TD Calculate AGV transport disturbance.
%   TD = sum(abs(candidate_start - baseline_start)) for non-cancelled AGV
%   transport tasks. Idle or charging blocks with job <= 0 are ignored.
%   Cancelled-job AGV tasks are excluded from TD and must not reappear in
%   the candidate schedule.

if nargin < 3
    error('evaluate_candidate_td:MissingInput', ...
        'baselineSchedule, candidateSchedule, and cancel are required.');
end

require_cancel(cancel);

metrics = empty_metrics();
report = empty_report();

[baselineTasks, baselineCancelledTasks, baselineReport] = ...
    collect_agv_tasks(baselineSchedule, cancel, 'baselineSchedule');
[candidateTasks, candidateCancelledTasks, candidateReport] = ...
    collect_agv_tasks(candidateSchedule, cancel, 'candidateSchedule');

report.baseline = baselineReport;
report.candidate = candidateReport;
report.errors = [report.errors, baselineReport.errors, ...
    candidateReport.errors];
report.checkedBaselineTaskCount = baselineReport.checkedTaskCount;
report.checkedCandidateTaskCount = candidateReport.checkedTaskCount;
report.baselineCancelledTaskCount = numel(baselineCancelledTasks);
report.candidateCancelledTaskCount = numel(candidateCancelledTasks);

if ~isempty(candidateCancelledTasks)
    for i = 1:numel(candidateCancelledTasks)
        task = candidateCancelledTasks(i);
        if is_cancelled_task_completed_history(task, cancel)
            continue
        end
        report.errors{end + 1} = sprintf( ...
            'Cancelled job %d AGV task operation %d appears in candidate.', ...
            task.job_id, task.operation_id);
    end
end

if isempty(report.errors)
    report = check_task_sets_match(baselineTasks, candidateTasks, report);
end

if isempty(report.errors)
    TD = 0;
    for i = 1:numel(baselineTasks)
        baselineTask = baselineTasks(i);
        candidateTask = find_task(candidateTasks, baselineTask);
        TD = TD + abs(candidateTask.start_time - ...
            baselineTask.start_time);
    end

    metrics.TD = TD;
    metrics.isFeasible = true;
end

report.isFeasible = isempty(report.errors);
end

function require_cancel(cancel)
if ~isstruct(cancel) || ~isfield(cancel, 'job_id')
    error('evaluate_candidate_td:InvalidCancel', ...
        'cancel.job_id is required.');
end
end

function isCompletedHistory = is_cancelled_task_completed_history(task, cancel)
isCompletedHistory = false;
if ~isfield(cancel, 'cancel_time')
    return
end
if ~isnumeric(cancel.cancel_time) || ~isscalar(cancel.cancel_time)
    return
end
isCompletedHistory = task.end_time <= cancel.cancel_time;
end

function [tasks, cancelledTasks, report] = collect_agv_tasks( ...
    schedule, cancel, scheduleName)
tasks = empty_task_array();
cancelledTasks = empty_task_array();
report = empty_schedule_report();

if ~isstruct(schedule) || ~isfield(schedule, 'AGVTable')
    report.errors{end + 1} = sprintf( ...
        '%s.AGVTable is required.', scheduleName);
    return
end

AGVTable = schedule.AGVTable;
if ~iscell(AGVTable)
    report.errors{end + 1} = sprintf( ...
        '%s.AGVTable must be a cell array.', scheduleName);
    return
end

for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    if isempty(blocks)
        continue
    end

    report = require_block_fields(blocks, scheduleName, agvIdx, report);
    if ~isempty(report.errors)
        continue
    end

    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job <= 0 || block.opera <= 0
            continue
        end

        task = make_agv_task(block, agvIdx, blockIdx, scheduleName);

        if task.end_time < task.start_time
            report.errors{end + 1} = sprintf( ...
                ['%s.AGVTable{%d} block %d has end < start: ', ...
                'job %d operation %d, start %.6f, end %.6f.'], ...
                scheduleName, agvIdx, blockIdx, task.job_id, ...
                task.operation_id, task.start_time, task.end_time);
            continue
        end

        if task.job_id == cancel.job_id
            cancelledTasks(end + 1) = task;
            continue
        end

        duplicate = find_task(tasks, task);
        if ~isempty(duplicate)
            report.errors{end + 1} = sprintf( ...
                ['%s contains duplicate AGV task job %d operation %d ', ...
                'load_status %g from_machine %g to_machine %g charge %g.'], ...
                scheduleName, task.job_id, task.operation_id, ...
                task.load_status, task.from_machine, task.to_machine, ...
                task.charge);
            continue
        end

        tasks(end + 1) = task;
        report.checkedTaskCount = report.checkedTaskCount + 1;
    end
end

report.isFeasible = isempty(report.errors);
end

function report = require_block_fields(blocks, scheduleName, agvIdx, ...
    report)
requiredFields = {'start', 'end', 'job', 'opera'};
for i = 1:numel(requiredFields)
    if ~isfield(blocks, requiredFields{i})
        report.errors{end + 1} = sprintf( ...
            '%s.AGVTable{%d} blocks require field %s.', ...
            scheduleName, agvIdx, requiredFields{i});
    end
end
end

function value = require_scalar_time(value, scheduleName, agvIdx, ...
    blockIdx, fieldName)
if isempty(value) || ~isnumeric(value) || ~isscalar(value)
    error('evaluate_candidate_td:InvalidTimeValue', ...
        '%s.AGVTable{%d} block %d field %s must be a numeric scalar.', ...
        scheduleName, agvIdx, blockIdx, fieldName);
end
end

function report = check_task_sets_match(baselineTasks, candidateTasks, ...
    report)
for i = 1:numel(baselineTasks)
    baselineTask = baselineTasks(i);
    candidateTask = find_task(candidateTasks, baselineTask);
    if isempty(candidateTask)
        report.errors{end + 1} = sprintf( ...
            'Candidate is missing AGV task job %d operation %d for TD.', ...
            baselineTask.job_id, baselineTask.operation_id);
    end
end

for i = 1:numel(candidateTasks)
    candidateTask = candidateTasks(i);
    baselineTask = find_task(baselineTasks, candidateTask);
    if isempty(baselineTask)
        report.errors{end + 1} = sprintf( ...
            'Candidate has extra AGV task job %d operation %d for TD.', ...
            candidateTask.job_id, candidateTask.operation_id);
    end
end
end

function task = find_task(tasks, queryTask)
task = [];
for i = 1:numel(tasks)
    if same_task(tasks(i), queryTask)
        task = tasks(i);
        return
    end
end
end

function tf = same_task(taskA, taskB)
tf = isequaln(taskA.job_id, taskB.job_id) && ...
    isequaln(taskA.operation_id, taskB.operation_id) && ...
    isequaln(taskA.load_status, taskB.load_status) && ...
    isequaln(taskA.from_machine, taskB.from_machine) && ...
    isequaln(taskA.to_machine, taskB.to_machine) && ...
    isequaln(taskA.charge, taskB.charge);
end

function value = read_task_numeric_field(block, fieldName, defaultValue)
value = defaultValue;
if ~isstruct(block) || ~isfield(block, fieldName)
    return
end

fieldValue = block.(fieldName);
if isempty(fieldValue) || ~isnumeric(fieldValue) || ~isscalar(fieldValue) || ...
        ~isfinite(fieldValue)
    return
end

value = fieldValue;
end

function task = make_agv_task(block, agvIdx, blockIdx, scheduleName)
task = empty_task_template();
task.job_id = block.job;
task.operation_id = block.opera;
task.load_status = read_task_numeric_field(block, 'load_status', 0);
task.from_machine = read_task_numeric_field(block, 'from_machine', NaN);
task.to_machine = read_task_numeric_field(block, 'to_machine', NaN);
task.charge = read_task_numeric_field(block, 'charge', NaN);
task.agv_id = agvIdx;
task.block_index = blockIdx;
task.start_time = require_scalar_time(block.start, ...
    scheduleName, agvIdx, blockIdx, 'start');
task.end_time = require_scalar_time(block.end, ...
    scheduleName, agvIdx, blockIdx, 'end');
end

function metrics = empty_metrics()
metrics = struct();
metrics.TD = [];
metrics.isFeasible = false;
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.baseline = struct();
report.candidate = struct();
report.checkedBaselineTaskCount = 0;
report.checkedCandidateTaskCount = 0;
report.baselineCancelledTaskCount = 0;
report.candidateCancelledTaskCount = 0;
report.isFeasible = false;
end

function report = empty_schedule_report()
report = struct();
report.errors = {};
report.warnings = {};
report.checkedTaskCount = 0;
report.isFeasible = false;
end

function tasks = empty_task_array()
tasks = repmat(empty_task_template(), 1, 0);
end

function task = empty_task_template()
task = struct( ...
    'job_id', [], ...
    'operation_id', [], ...
    'load_status', [], ...
    'from_machine', [], ...
    'to_machine', [], ...
    'charge', [], ...
    'agv_id', [], ...
    'block_index', [], ...
    'start_time', [], ...
    'end_time', []);
end
