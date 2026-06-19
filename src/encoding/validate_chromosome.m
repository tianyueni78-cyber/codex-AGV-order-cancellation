function [isValid, report] = validate_chromosome(chrom, problem, agvData)
%VALIDATE_CHROMOSOME Check basic FJSP-AGV chromosome encoding validity.
%   [isValid, report] = VALIDATE_CHROMOSOME(chrom, problem, agvData)
%   checks one chromosome's OS, MS, AS, and SS segments. This function only
%   validates encoding ranges and structure; it does not decode schedules,
%   call fitness, run NSGA-II, or write files.

if nargin < 3
    error('validate_chromosome:MissingInput', ...
        'chrom, problem, and agvData are required.');
end

require_fields(problem, {'jobNum', 'operaNumVec', 'candidateMachine'}, ...
    'problem');
require_fields(agvData, {'AGVNum', 'AGVSpeed'}, 'agvData');

report = struct();
report.errors = {};
report.warnings = {};
report.extraColumnCount = 0;

try
    parts = split_chromosome(chrom, problem);
catch err
    report.errors{end + 1} = err.message;
    isValid = false;
    report.isValid = isValid;
    return
end

report.operaNum = parts.operaNum;
report.dim = parts.dim;
report.extraColumnCount = numel(parts.extraColumns);
if report.extraColumnCount > 0
    report.warnings{end + 1} = ...
        'chrom contains extra trailing columns after the core encoding.';
end

report = check_os(parts.OS, problem, report);
report = check_ms(parts.MS, problem, report);
report = check_range(parts.AS, 1, agvData.AGVNum, 'AS', report);
report = check_range(parts.SS, 1, numel(agvData.AGVSpeed), 'SS', report);

isValid = isempty(report.errors);
report.isValid = isValid;
end

function report = check_os(OS, problem, report)
if ~all(is_integer_values(OS))
    report.errors{end + 1} = 'OS must contain integer job ids.';
end

if any(OS < 1) || any(OS > problem.jobNum)
    report.errors{end + 1} = 'OS job ids must be in 1...problem.jobNum.';
end

for jobIdx = 1:problem.jobNum
    actualCount = sum(OS == jobIdx);
    expectedCount = problem.operaNumVec(jobIdx);
    if actualCount ~= expectedCount
        report.errors{end + 1} = sprintf( ...
            'OS job %d appears %d times, expected %d.', ...
            jobIdx, actualCount, expectedCount);
    end
end
end

function report = check_ms(MS, problem, report)
if ~all(is_integer_values(MS))
    report.errors{end + 1} = 'MS must contain integer candidate indexes.';
end

pos = 1;
for jobIdx = 1:problem.jobNum
    for operaIdx = 1:problem.operaNumVec(jobIdx)
        if size(problem.candidateMachine, 1) < jobIdx || ...
                size(problem.candidateMachine, 2) < operaIdx
            report.errors{end + 1} = sprintf( ...
                'candidateMachine{%d,%d} is missing.', jobIdx, operaIdx);
            pos = pos + 1;
            continue
        end

        candidates = problem.candidateMachine{jobIdx, operaIdx};
        upper = numel(candidates);
        if upper < 1
            report.errors{end + 1} = sprintf( ...
                'candidateMachine{%d,%d} is empty.', jobIdx, operaIdx);
        elseif MS(pos) < 1 || MS(pos) > upper
            report.errors{end + 1} = sprintf( ...
                ['MS position %d for job %d operation %d is %g, ', ...
                'expected 1...%d.'], ...
                pos, jobIdx, operaIdx, MS(pos), upper);
        end
        pos = pos + 1;
    end
end
end

function report = check_range(values, lower, upper, segmentName, report)
if ~all(is_integer_values(values))
    report.errors{end + 1} = sprintf( ...
        '%s must contain integer values.', segmentName);
end

if upper < lower
    report.errors{end + 1} = sprintf( ...
        '%s has invalid bounds %d...%d.', segmentName, lower, upper);
    return
end

bad = values < lower | values > upper;
if any(bad)
    report.errors{end + 1} = sprintf( ...
        '%s values must be in %d...%d.', segmentName, lower, upper);
end
end

function tf = is_integer_values(values)
tf = isfinite(values) & values == fix(values);
end

function require_fields(s, fields, structName)
for i = 1:numel(fields)
    if ~isfield(s, fields{i})
        error('validate_chromosome:MissingField', ...
            '%s.%s is required.', structName, fields{i});
    end
end
end
