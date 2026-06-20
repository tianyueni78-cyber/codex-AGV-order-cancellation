function [metrics, report] = evaluate_candidate_cmax( ...
    baselineSchedule, candidateSchedule)
%EVALUATE_CANDIDATE_CMAX Calculate Cmax and Cmax_delta for a candidate.
%   [metrics, report] = EVALUATE_CANDIDATE_CMAX(baselineSchedule,
%   candidateSchedule) calculates baseline Cmax from the original normal
%   schedule, candidate Cmax from the candidate schedule, and
%   Cmax_delta = candidate Cmax - baseline Cmax. Idle blocks with job <= 0
%   are ignored.

if nargin < 2
    error('evaluate_candidate_cmax:MissingInput', ...
        'baselineSchedule and candidateSchedule are required.');
end

metrics = empty_metrics();
report = empty_report();

[baselineCmax, baselineReport] = calculate_schedule_cmax( ...
    baselineSchedule, 'baselineSchedule');
[candidateCmax, candidateReport] = calculate_schedule_cmax( ...
    candidateSchedule, 'candidateSchedule');

report.baseline = baselineReport;
report.candidate = candidateReport;
report.errors = [report.errors, baselineReport.errors, ...
    candidateReport.errors];
report.checkedBaselineOperationCount = ...
    baselineReport.checkedOperationCount;
report.checkedCandidateOperationCount = ...
    candidateReport.checkedOperationCount;

if isempty(report.errors)
    metrics.baseline_Cmax = baselineCmax;
    metrics.Cmax = candidateCmax;
    metrics.Cmax_delta = candidateCmax - baselineCmax;
    metrics.isFeasible = true;
end

report.isFeasible = isempty(report.errors);
end

function [Cmax, report] = calculate_schedule_cmax(schedule, scheduleName)
report = empty_schedule_report();
Cmax = [];

if ~isstruct(schedule) || ~isfield(schedule, 'machineTable')
    report.errors{end + 1} = sprintf( ...
        '%s.machineTable is required.', scheduleName);
    return
end

machineTable = schedule.machineTable;
if ~iscell(machineTable)
    report.errors{end + 1} = sprintf( ...
        '%s.machineTable must be a cell array.', scheduleName);
    return
end

realEndTimes = [];

for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    if isempty(blocks)
        continue
    end

    report = require_block_fields(blocks, scheduleName, machineIdx, report);
    if ~isempty(report.errors)
        continue
    end

    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job <= 0
            continue
        end

        startTime = require_scalar_time(block.start, ...
            scheduleName, machineIdx, blockIdx, 'start');
        endTime = require_scalar_time(block.end, ...
            scheduleName, machineIdx, blockIdx, 'end');

        if ~isfinite(endTime)
            report.errors{end + 1} = sprintf( ...
                ['%s.machineTable{%d} block %d real operation ', ...
                'end time must be finite.'], ...
                scheduleName, machineIdx, blockIdx);
            continue
        end

        if endTime < startTime
            report.errors{end + 1} = sprintf( ...
                ['%s.machineTable{%d} block %d has end < start: ', ...
                'start %.6f, end %.6f.'], ...
                scheduleName, machineIdx, blockIdx, startTime, endTime);
            continue
        end

        realEndTimes(end + 1) = endTime;
        report.checkedOperationCount = report.checkedOperationCount + 1;
    end
end

if isempty(report.errors)
    if isempty(realEndTimes)
        Cmax = 0;
    else
        Cmax = max(realEndTimes);
    end
end

report.Cmax = Cmax;
report.isFeasible = isempty(report.errors);
end

function report = require_block_fields(blocks, scheduleName, machineIdx, ...
    report)
requiredFields = {'start', 'end', 'job', 'opera'};
for i = 1:numel(requiredFields)
    if ~isfield(blocks, requiredFields{i})
        report.errors{end + 1} = sprintf( ...
            '%s.machineTable{%d} blocks require field %s.', ...
            scheduleName, machineIdx, requiredFields{i});
    end
end
end

function value = require_scalar_time(value, scheduleName, machineIdx, ...
    blockIdx, fieldName)
if isempty(value) || ~isnumeric(value) || ~isscalar(value)
    error('evaluate_candidate_cmax:InvalidTimeValue', ...
        '%s.machineTable{%d} block %d field %s must be a numeric scalar.', ...
        scheduleName, machineIdx, blockIdx, fieldName);
end
end

function metrics = empty_metrics()
metrics = struct();
metrics.baseline_Cmax = [];
metrics.Cmax = [];
metrics.Cmax_delta = [];
metrics.isFeasible = false;
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.baseline = struct();
report.candidate = struct();
report.checkedBaselineOperationCount = 0;
report.checkedCandidateOperationCount = 0;
report.isFeasible = false;
end

function report = empty_schedule_report()
report = struct();
report.errors = {};
report.warnings = {};
report.Cmax = [];
report.checkedOperationCount = 0;
report.isFeasible = false;
end
