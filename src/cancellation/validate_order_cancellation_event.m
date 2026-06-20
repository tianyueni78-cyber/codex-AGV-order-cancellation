function [isValid, report] = validate_order_cancellation_event(cancel, problem)
%VALIDATE_ORDER_CANCELLATION_EVENT Validate a single cancellation event.
%   [isValid, report] = VALIDATE_ORDER_CANCELLATION_EVENT(cancel, problem)
%   checks the first-stage order-cancellation event contract. This function
%   only validates the event; it does not extract state or build schedules.

if nargin < 2
    error('validate_order_cancellation_event:MissingInput', ...
        'cancel and problem are required.');
end

report = struct();
report.errors = {};
report.warnings = {};

report = require_fields(cancel, {'job_id', 'cancel_time', 'policy'}, ...
    'cancel', report);
report = require_fields(problem, {'jobNum'}, 'problem', report);

if isempty(report.errors)
    report = check_job_id(cancel.job_id, problem.jobNum, report);
    report = check_cancel_time(cancel.cancel_time, report);
    report = check_policy(cancel.policy, report);
end

isValid = isempty(report.errors);
report.isValid = isValid;
end

function report = check_job_id(jobId, jobNum, report)
if ~isnumeric(jobId) || ~isscalar(jobId) || ~isfinite(jobId) || ...
        jobId ~= fix(jobId)
    report.errors{end + 1} = 'cancel.job_id must be a finite integer scalar.';
    return
end

if jobId < 1 || jobId > jobNum
    report.errors{end + 1} = sprintf( ...
        'cancel.job_id must be in 1...problem.jobNum; got %g.', jobId);
end
end

function report = check_cancel_time(cancelTime, report)
if ~isnumeric(cancelTime) || ~isscalar(cancelTime) || ...
        ~isfinite(cancelTime)
    report.errors{end + 1} = ...
        'cancel.cancel_time must be a finite numeric scalar.';
    return
end

if cancelTime < 0
    report.errors{end + 1} = ...
        'cancel.cancel_time must be nonnegative.';
end
end

function report = check_policy(policy, report)
supportedPolicies = {'cancel_unstarted_operations_only'};

if ~(ischar(policy) || (isstring(policy) && isscalar(policy)))
    report.errors{end + 1} = 'cancel.policy must be a character vector.';
    return
end

policy = char(policy);
if ~any(strcmp(policy, supportedPolicies))
    report.errors{end + 1} = sprintf( ...
        'Unsupported cancel.policy: %s.', policy);
end
end

function report = require_fields(s, fields, structName, report)
if ~isstruct(s)
    report.errors{end + 1} = sprintf('%s must be a struct.', structName);
    return
end

for i = 1:numel(fields)
    if ~isfield(s, fields{i})
        report.errors{end + 1} = sprintf( ...
            '%s.%s is required.', structName, fields{i});
    end
end
end
