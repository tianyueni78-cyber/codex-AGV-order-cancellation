function [isValid, report] = validate_schedule_change_event(event, problem)
%VALIDATE_SCHEDULE_CHANGE_EVENT Validate a unified schedule-change event.
%   [isValid, report] = VALIDATE_SCHEDULE_CHANGE_EVENT(event, problem)
%   checks the stage J event wrapper. insert_order is validated as an
%   interface-level event and reported as pending because full insertion
%   scheduling is outside stage J.

if nargin < 1
    error('validate_schedule_change_event:MissingInput', ...
        'event is required.');
end

if nargin < 2
    problem = struct();
end

report = struct();
report.errors = {};
report.warnings = {};
report.status = 'valid';
report.isPending = false;

report = require_fields(event, ...
    {'event_id', 'event_type', 'event_time', 'policy', 'payload'}, ...
    'event', report);

if isempty(report.errors)
    report = check_event_type(event.event_type, report);
    report = check_event_time(event.event_time, report);
end

if isempty(report.errors)
    eventType = normalize_text(event.event_type);
    if strcmp(eventType, 'cancel_order')
        report = check_cancel_order_payload(event.payload, problem, report);
    elseif strcmp(eventType, 'insert_order')
        report = check_insert_order_payload(event.payload, report);
        report.status = 'pending';
        report.isPending = true;
        report.warnings{end + 1} = ...
            'insert_order is interface-only in stage J; full insertion scheduling is not implemented.';
    end
end

isValid = isempty(report.errors);
report.isValid = isValid;
end

function report = check_event_type(eventType, report)
supportedTypes = {'cancel_order', 'insert_order'};

if ~(ischar(eventType) || (isstring(eventType) && isscalar(eventType)))
    report.errors{end + 1} = 'event.event_type must be a character vector.';
    return
end

eventType = normalize_text(eventType);
if ~any(strcmp(eventType, supportedTypes))
    report.errors{end + 1} = sprintf( ...
        'Unsupported event.event_type: %s.', eventType);
end
end

function report = check_event_time(eventTime, report)
if ~isnumeric(eventTime) || ~isscalar(eventTime) || ~isfinite(eventTime)
    report.errors{end + 1} = ...
        'event.event_time must be a finite numeric scalar.';
    return
end

if eventTime < 0
    report.errors{end + 1} = 'event.event_time must be nonnegative.';
end
end

function report = check_cancel_order_payload(payload, problem, report)
report = require_fields(payload, {'job_id'}, 'event.payload', report);
if ~isempty(report.errors)
    return
end

jobId = payload.job_id;
if ~isnumeric(jobId) || ~isscalar(jobId) || ~isfinite(jobId) || ...
        jobId ~= fix(jobId)
    report.errors{end + 1} = ...
        'event.payload.job_id must be a finite integer scalar.';
    return
end

if isfield(problem, 'jobNum')
    if jobId < 1 || jobId > problem.jobNum
        report.errors{end + 1} = sprintf( ...
            'event.payload.job_id must be in 1...problem.jobNum; got %g.', jobId);
    end
elseif jobId < 1
    report.errors{end + 1} = 'event.payload.job_id must be positive.';
end
end

function report = check_insert_order_payload(payload, report)
report = require_fields(payload, {'new_job'}, 'event.payload', report);
if ~isempty(report.errors)
    return
end

newJob = payload.new_job;
requiredFields = { ...
    'job_id', ...
    'operations', ...
    'processing_times', ...
    'machine_options', ...
    'due_date'};
report = require_fields(newJob, requiredFields, 'event.payload.new_job', report);
end

function report = require_fields(s, fields, structName, report)
if ~isstruct(s)
    report.errors{end + 1} = sprintf('%s must be a struct.', structName);
    return
end

for idx = 1:numel(fields)
    if ~isfield(s, fields{idx})
        report.errors{end + 1} = sprintf( ...
            '%s.%s is required.', structName, fields{idx});
    end
end
end

function value = normalize_text(value)
if isstring(value) && isscalar(value)
    value = char(value);
end
end
