function cancel = schedule_change_event_to_order_cancellation(event)
%SCHEDULE_CHANGE_EVENT_TO_ORDER_CANCELLATION Restore cancel from event.
%   cancel = SCHEDULE_CHANGE_EVENT_TO_ORDER_CANCELLATION(event) maps a
%   stage J cancel_order event back to the existing cancellation structure
%   used by stages B-I.

if nargin < 1
    error('schedule_change_event_to_order_cancellation:MissingInput', ...
        'event is required.');
end

requiredFields = {'event_type', 'event_time', 'policy', 'payload'};
for idx = 1:numel(requiredFields)
    fieldName = requiredFields{idx};
    if ~isfield(event, fieldName)
        error('schedule_change_event_to_order_cancellation:MissingField', ...
            'event.%s is required.', fieldName);
    end
end

eventType = normalize_text(event.event_type);
if ~strcmp(eventType, 'cancel_order')
    error('schedule_change_event_to_order_cancellation:UnsupportedEventType', ...
        'event.event_type must be cancel_order.');
end

if ~isfield(event.payload, 'job_id')
    error('schedule_change_event_to_order_cancellation:MissingPayloadField', ...
        'event.payload.job_id is required.');
end

cancel = struct();
cancel.job_id = event.payload.job_id;
cancel.cancel_time = event.event_time;
cancel.policy = normalize_text(event.policy);
end

function value = normalize_text(value)
if isstring(value) && isscalar(value)
    value = char(value);
end
end
