function [isFeasible, report] = check_agv_table_feasibility(AGVTable)
%CHECK_AGV_TABLE_FEASIBILITY Check AGV transport time conflicts.
%   [isFeasible, report] = CHECK_AGV_TABLE_FEASIBILITY(AGVTable) checks
%   order transport tasks only. Idle or charging blocks with job <= 0 are
%   ignored in the first version.

if nargin < 1
    error('check_agv_table_feasibility:MissingInput', ...
        'AGVTable is required.');
end

report = empty_report();

if ~iscell(AGVTable)
    report.errors{end + 1} = 'AGVTable must be a cell array.';
    isFeasible = false;
    report.isFeasible = isFeasible;
    return
end

for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    if isempty(blocks)
        continue
    end

    report = require_block_fields(blocks, agvIdx, report);
    if ~isempty(report.errors)
        continue
    end

    agvTasks = collect_real_agv_tasks(blocks, agvIdx);
    report.checkedAgvTaskCount = ...
        report.checkedAgvTaskCount + numel(agvTasks);
    report = check_agv_task_times(agvTasks, report);
    report = check_agv_overlaps(agvTasks, report);
end

isFeasible = isempty(report.errors);
report.isFeasible = isFeasible;
end

function report = require_block_fields(blocks, agvIdx, report)
requiredFields = {'start', 'end', 'job', 'opera'};
for i = 1:numel(requiredFields)
    if ~isfield(blocks, requiredFields{i})
        report.errors{end + 1} = sprintf( ...
            'AGVTable{%d} blocks require field %s.', ...
            agvIdx, requiredFields{i});
    end
end
end

function agvTasks = collect_real_agv_tasks(blocks, agvIdx)
agvTasks = empty_agv_task_array();

for blockIdx = 1:numel(blocks)
    block = blocks(blockIdx);
    if block.job <= 0
        continue
    end

    agvTask = struct();
    agvTask.agv_id = agvIdx;
    agvTask.block_index = blockIdx;
    agvTask.job_id = block.job;
    agvTask.operation_id = block.opera;
    agvTask.start_time = require_scalar_time(block.start, ...
        agvIdx, blockIdx, 'start');
    agvTask.end_time = require_scalar_time(block.end, ...
        agvIdx, blockIdx, 'end');
    agvTasks(end + 1) = agvTask;
end
end

function value = require_scalar_time(value, agvIdx, blockIdx, fieldName)
if isempty(value) || ~isnumeric(value) || ~isscalar(value)
    error('check_agv_table_feasibility:InvalidTimeValue', ...
        'AGVTable{%d} block %d field %s must be a numeric scalar.', ...
        agvIdx, blockIdx, fieldName);
end
end

function report = check_agv_task_times(agvTasks, report)
for i = 1:numel(agvTasks)
    agvTask = agvTasks(i);
    if agvTask.end_time < agvTask.start_time
        report.errors{end + 1} = sprintf( ...
            ['AGV %d block %d has end < start: ', ...
            'job %d operation %d, start %.6f, end %.6f.'], ...
            agvTask.agv_id, agvTask.block_index, ...
            agvTask.job_id, agvTask.operation_id, ...
            agvTask.start_time, agvTask.end_time);
    end
end
end

function report = check_agv_overlaps(agvTasks, report)
if numel(agvTasks) < 2
    return
end

startTimes = [agvTasks.start_time]';
endTimes = [agvTasks.end_time]';
[~, order] = sortrows([startTimes, endTimes], [1, 2]);
agvTasks = agvTasks(order);

for i = 2:numel(agvTasks)
    previous = agvTasks(i - 1);
    current = agvTasks(i);
    if current.start_time < previous.end_time
        report.errors{end + 1} = sprintf( ...
            ['AGV %d has overlapping transport tasks: ', ...
            'block %d job %d operation %d [%.6f, %.6f] and ', ...
            'block %d job %d operation %d [%.6f, %.6f].'], ...
            current.agv_id, previous.block_index, previous.job_id, ...
            previous.operation_id, previous.start_time, ...
            previous.end_time, current.block_index, current.job_id, ...
            current.operation_id, current.start_time, current.end_time);
    end
end
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.checkedAgvTaskCount = 0;
report.isFeasible = false;
end

function agvTasks = empty_agv_task_array()
agvTasks = repmat(struct( ...
    'agv_id', [], ...
    'block_index', [], ...
    'job_id', [], ...
    'operation_id', [], ...
    'start_time', [], ...
    'end_time', []), 1, 0);
end
