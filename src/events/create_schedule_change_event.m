function event = create_schedule_change_event(eventId, eventType, eventTime, policy, payload)
%CREATE_SCHEDULE_CHANGE_EVENT Build a unified schedule-change event.
%   event = CREATE_SCHEDULE_CHANGE_EVENT(eventId, eventType, eventTime,
%   policy, payload) creates the common event wrapper used by stage J.
%   Supported event types are cancel_order and insert_order.

if nargin < 3
    error('create_schedule_change_event:MissingInput', ...
        'eventId, eventType, and eventTime are required.');
end

eventType = normalize_text(eventType);

if nargin < 4 || isempty(policy)
    policy = default_policy_for_event_type(eventType);
else
    policy = normalize_text(policy);
end

if nargin < 5 || isempty(payload)
    payload = struct();
end

if eventTime < 0
    error('create_schedule_change_event:InvalidEventTime', ...
        'eventTime must be nonnegative.');
end

if ~is_supported_event_type(eventType)
    error('create_schedule_change_event:UnsupportedEventType', ...
        'eventType must be cancel_order or insert_order.');
end

event = struct();
event.event_id = eventId;
event.event_type = eventType;
event.event_time = eventTime;
event.policy = policy;
event.payload = payload;
end

function tf = is_supported_event_type(eventType)
tf = ischar(eventType) && any(strcmp(eventType, {'cancel_order', 'insert_order'}));
end

function policy = default_policy_for_event_type(eventType)
if strcmp(eventType, 'cancel_order')
    policy = 'cancel_unstarted_operations_only';
elseif strcmp(eventType, 'insert_order')
    policy = 'insert_order_interface_only';
else
    policy = '';
end
end

function value = normalize_text(value)
if isstring(value) && isscalar(value)
    value = char(value);
end
end
