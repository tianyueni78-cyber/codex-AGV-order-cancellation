function makespan = compute_makespan_from_schedule(schedule)
%COMPUTE_MAKESPAN_FROM_SCHEDULE Compute makespan from decoded schedule data.
%   makespan = COMPUTE_MAKESPAN_FROM_SCHEDULE(schedule) reads
%   schedule.jobCompleteUnLoad and returns its maximum value, matching the
%   raw fitness.m makespan rule.

if nargin < 1
    error('compute_makespan_from_schedule:MissingInput', ...
        'schedule is required.');
end
if ~isstruct(schedule) || ~isfield(schedule, 'jobCompleteUnLoad')
    error('compute_makespan_from_schedule:MissingField', ...
        'schedule.jobCompleteUnLoad is required.');
end

jobCompleteUnLoad = schedule.jobCompleteUnLoad;
if ~isnumeric(jobCompleteUnLoad) || isempty(jobCompleteUnLoad)
    error('compute_makespan_from_schedule:InvalidInput', ...
        'schedule.jobCompleteUnLoad must be a non-empty numeric array.');
end

makespan = max(jobCompleteUnLoad);
end
