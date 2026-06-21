function event = order_cancellation_to_schedule_change_event(cancel, eventId)
%ORDER_CANCELLATION_TO_SCHEDULE_CHANGE_EVENT Wrap cancel as a change event.
%   event = ORDER_CANCELLATION_TO_SCHEDULE_CHANGE_EVENT(cancel, eventId)
%   maps the existing cancellation event structure into the stage J unified
%   schedule-change event structure.

if nargin < 1
    error('order_cancellation_to_schedule_change_event:MissingInput', ...
        'cancel is required.');
end

if nargin < 2 || isempty(eventId)
    eventId = 1;
end

requiredFields = {'job_id', 'cancel_time', 'policy'};
for idx = 1:numel(requiredFields)
    fieldName = requiredFields{idx};
    if ~isfield(cancel, fieldName)
        error('order_cancellation_to_schedule_change_event:MissingField', ...
            'cancel.%s is required.', fieldName);
    end
end

payload = struct();
payload.job_id = cancel.job_id;

event = create_schedule_change_event( ...
    eventId, ...
    'cancel_order', ...
    cancel.cancel_time, ...
    cancel.policy, ...
    payload);
end
