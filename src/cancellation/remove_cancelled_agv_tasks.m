function candidate = remove_cancelled_agv_tasks(problem, schedule, state, cancel)
%REMOVE_CANCELLED_AGV_TASKS Remove unstarted cancelled AGV tasks.
%   candidate = REMOVE_CANCELLED_AGV_TASKS(problem, schedule, state, cancel)
%   removes only unstarted AGV transport tasks for the cancelled job. It
%   does not move remaining AGV tasks or touch machine operations.

if nargin < 4
    error('remove_cancelled_agv_tasks:MissingInput', ...
        'problem, schedule, state, and cancel are required.');
end

candidate = create_empty_candidate();
candidate.report = validate_inputs(problem, schedule, state, cancel, ...
    candidate.report);

if isstruct(schedule) && isfield(schedule, 'machineTable')
    candidate.machineTable = schedule.machineTable;
end

if isstruct(schedule) && isfield(schedule, 'AGVTable')
    candidate.AGVTable = schedule.AGVTable;
end

if ~isempty(candidate.report.rejectedReasons) || ...
        ~isempty(candidate.report.errors)
    candidate.isFeasible = false;
    return
end

agvTasksToRemove = select_removable_agv_tasks( ...
    state.cancelled_unfinished_agv_tasks, cancel);

for i = 1:numel(agvTasksToRemove)
    agvTask = agvTasksToRemove(i);
    candidate.AGVTable{agvTask.agv_id}(agvTask.block_index) = [];
    candidate.removed_agv_tasks(end + 1) = agvTask;
end

candidate.report.removedAgvTaskCount = ...
    numel(candidate.removed_agv_tasks);
candidate.isFeasible = true;
end

function candidate = create_empty_candidate()
candidate = struct();
candidate.machineTable = [];
candidate.AGVTable = [];
candidate.removed_operations = empty_operation_array();
candidate.removed_agv_tasks = empty_agv_task_array();
candidate.isFeasible = false;
candidate.report = empty_report();
end

function report = validate_inputs(problem, schedule, state, cancel, report)
if ~isstruct(problem)
    report.errors{end + 1} = 'problem must be a struct.';
end

if ~isstruct(schedule) || ~isfield(schedule, 'machineTable') || ...
        ~isfield(schedule, 'AGVTable')
    report.errors{end + 1} = ...
        'schedule.machineTable and schedule.AGVTable are required.';
end

requiredStateFields = {'cancelled_unfinished_operations', ...
    'cancelled_unfinished_agv_tasks', 'has_unsupported_operations', ...
    'has_unsupported_agv_tasks', 'cancel'};
for i = 1:numel(requiredStateFields)
    if ~isstruct(state) || ~isfield(state, requiredStateFields{i})
        report.errors{end + 1} = sprintf( ...
            'state.%s is required.', requiredStateFields{i});
    end
end

if ~isempty(report.errors)
    return
end

if ~strcmp(cancel.policy, 'cancel_unstarted_operations_only')
    report.rejectedReasons{end + 1} = ...
        'Only cancel_unstarted_operations_only is supported.';
end

if state.has_unsupported_operations
    report.rejectedReasons{end + 1} = ...
        'Cancelled job has processing machine operations.';
end

if state.has_unsupported_agv_tasks
    report.rejectedReasons{end + 1} = ...
        'Cancelled job has processing AGV tasks.';
end

if state.cancel.job_id ~= cancel.job_id
    report.rejectedReasons{end + 1} = ...
        'state.cancel.job_id does not match cancel.job_id.';
end

if state.cancel.cancel_time ~= cancel.cancel_time
    report.rejectedReasons{end + 1} = ...
        'state.cancel.cancel_time does not match cancel.cancel_time.';
end
end

function agvTasksToRemove = select_removable_agv_tasks(agvTasks, cancel)
agvTasksToRemove = empty_agv_task_array();

for i = 1:numel(agvTasks)
    agvTask = agvTasks(i);
    if agvTask.job_id == cancel.job_id && ...
            strcmp(agvTask.status, 'unstarted')
        agvTasksToRemove(end + 1) = agvTask;
    end
end

agvTasksToRemove = sort_agv_tasks_for_deletion(agvTasksToRemove);
end

function agvTasks = sort_agv_tasks_for_deletion(agvTasks)
if isempty(agvTasks)
    return
end

keys = zeros(numel(agvTasks), 2);
for i = 1:numel(agvTasks)
    keys(i, :) = [agvTasks(i).agv_id, agvTasks(i).block_index];
end

[~, order] = sortrows(keys, [-1, -2]);
agvTasks = agvTasks(order);
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.rejectedReasons = {};
report.removedOperationCount = 0;
report.removedAgvTaskCount = 0;
report.machineConflictCheck = struct();
report.agvConflictCheck = struct();
report.jobSequenceCheck = struct();
end

function operations = empty_operation_array()
operations = repmat(struct( ...
    'job_id', [], ...
    'operation_id', [], ...
    'machine_id', [], ...
    'block_index', [], ...
    'start_time', [], ...
    'end_time', [], ...
    'status', ''), 1, 0);
end

function agvTasks = empty_agv_task_array()
agvTasks = repmat(struct( ...
    'job_id', [], ...
    'operation_id', [], ...
    'agv_id', [], ...
    'block_index', [], ...
    'start_time', [], ...
    'end_time', [], ...
    'from_machine', [], ...
    'to_machine', [], ...
    'status', '', ...
    'load_status', [], ...
    'charge', []), 1, 0);
end
