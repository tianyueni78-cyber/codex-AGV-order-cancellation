function [isValid, sortedEvents, report] = ...
    validate_sequential_cancellation_events(cancelEvents, problem)
%VALIDATE_SEQUENTIAL_CANCELLATION_EVENTS Validate sequential cancellations.
%   This function validates and stably sorts a list of cancellation events.
%   It does not extract state, repair schedules, reschedule operations, or
%   write outputs.

if nargin < 2
    error('validate_sequential_cancellation_events:MissingInput', ...
        'cancelEvents and problem are required.');
end

sortedEvents = cancelEvents;
report = struct();
report.errors = {};
report.warnings = {};
report.sorted_order = [];
report.unsupported_events = {};

if ~isstruct(cancelEvents)
    report.errors{end + 1} = 'cancelEvents must be a struct array.';
    isValid = false;
    report.isValid = isValid;
    return
end

if numel(cancelEvents) < 2
    report.errors{end + 1} = ...
        'cancelEvents must contain at least 2 events.';
end

if ~isstruct(problem) || ~isfield(problem, 'jobNum')
    report.errors{end + 1} = 'problem.jobNum is required.';
end

for i = 1:numel(cancelEvents)
    report = validate_event_fields(cancelEvents(i), i, report);
end

if isempty(report.errors)
    [sortedEvents, report] = stable_sort_events(cancelEvents, report);
    report = validate_sorted_events(sortedEvents, problem, report);
end

isValid = isempty(report.errors);
report.isValid = isValid;
end

function report = validate_event_fields(event, eventIndex, report)
requiredFields = {'event_id', 'job_id', 'cancel_time', 'policy'};
for i = 1:numel(requiredFields)
    fieldName = requiredFields{i};
    if ~isfield(event, fieldName)
        report.errors{end + 1} = sprintf( ...
            'cancelEvents(%d).%s is required.', eventIndex, fieldName);
    end
end

if isfield(event, 'event_id') && ...
        (~isnumeric(event.event_id) || ~isscalar(event.event_id) || ...
        ~isfinite(event.event_id) || event.event_id ~= fix(event.event_id))
    report.errors{end + 1} = sprintf( ...
        'cancelEvents(%d).event_id must be a finite integer scalar.', ...
        eventIndex);
end

if isfield(event, 'cancel_time') && ...
        (~isnumeric(event.cancel_time) || ~isscalar(event.cancel_time) || ...
        ~isfinite(event.cancel_time))
    report.errors{end + 1} = sprintf( ...
        'cancelEvents(%d).cancel_time must be a finite numeric scalar.', ...
        eventIndex);
end
end

function [sortedEvents, report] = stable_sort_events(cancelEvents, report)
cancelTimes = zeros(numel(cancelEvents), 1);
for i = 1:numel(cancelEvents)
    cancelTimes(i) = cancelEvents(i).cancel_time;
end

originalOrder = (1:numel(cancelEvents))';
[~, order] = sortrows([cancelTimes, originalOrder], [1, 2]);
sortedEvents = cancelEvents(order);
report.sorted_order = order';
end

function report = validate_sorted_events(sortedEvents, problem, report)
jobIds = zeros(1, numel(sortedEvents));
for i = 1:numel(sortedEvents)
    cancel = struct();
    cancel.job_id = sortedEvents(i).job_id;
    cancel.cancel_time = sortedEvents(i).cancel_time;
    cancel.policy = sortedEvents(i).policy;

    [isEventValid, eventReport] = validate_order_cancellation_event( ...
        cancel, problem);
    if ~isEventValid
        report = append_event_errors(report, eventReport, i);
    end

    if isnumeric(sortedEvents(i).job_id) && ...
            isscalar(sortedEvents(i).job_id)
        jobIds(i) = sortedEvents(i).job_id;
    else
        jobIds(i) = NaN;
    end
end

report = reject_duplicate_job_ids(jobIds, sortedEvents, report);
end

function report = append_event_errors(report, eventReport, eventIndex)
for i = 1:numel(eventReport.errors)
    report.errors{end + 1} = sprintf( ...
        'cancelEvents(%d): %s', eventIndex, eventReport.errors{i});
end
end

function report = reject_duplicate_job_ids(jobIds, sortedEvents, report)
finiteJobIds = jobIds(isfinite(jobIds));
uniqueJobIds = unique(finiteJobIds);
for i = 1:numel(uniqueJobIds)
    jobId = uniqueJobIds(i);
    if sum(finiteJobIds == jobId) > 1
        report.errors{end + 1} = sprintf( ...
            ['Duplicate cancellation for job_id %g is not supported ', ...
            'in stage I.'], jobId);
        report.unsupported_events{end + 1} = duplicate_report( ...
            jobId, sortedEvents);
    end
end
end

function duplicate = duplicate_report(jobId, sortedEvents)
duplicate = struct();
duplicate.job_id = jobId;
duplicate.reason = 'duplicate_job_cancellation';
duplicate.event_ids = [];
for i = 1:numel(sortedEvents)
    if isnumeric(sortedEvents(i).job_id) && ...
            isscalar(sortedEvents(i).job_id) && ...
            sortedEvents(i).job_id == jobId
        duplicate.event_ids(end + 1) = sortedEvents(i).event_id;
    end
end
end
