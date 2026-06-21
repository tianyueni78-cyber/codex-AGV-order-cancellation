function event = insert_order_to_schedule_change_event(newJob, insertTime, eventId, policy)
%INSERT_ORDER_TO_SCHEDULE_CHANGE_EVENT Wrap newJob as insert_order event.
%   event = INSERT_ORDER_TO_SCHEDULE_CHANGE_EVENT(newJob, insertTime,
%   eventId, policy) creates a stage J insert_order event. This is an
%   interface placeholder only; it does not modify problem data or decode a
%   new schedule.

if nargin < 2
    error('insert_order_to_schedule_change_event:MissingInput', ...
        'newJob and insertTime are required.');
end

if nargin < 3 || isempty(eventId)
    eventId = 1;
end

if nargin < 4 || isempty(policy)
    policy = 'insert_order_interface_only';
end

requiredFields = { ...
    'job_id', ...
    'operations', ...
    'processing_times', ...
    'machine_options', ...
    'due_date'};

for idx = 1:numel(requiredFields)
    fieldName = requiredFields{idx};
    if ~isfield(newJob, fieldName)
        error('insert_order_to_schedule_change_event:MissingField', ...
            'newJob.%s is required.', fieldName);
    end
end

payload = struct();
payload.new_job = newJob;

event = create_schedule_change_event( ...
    eventId, ...
    'insert_order', ...
    insertTime, ...
    policy, ...
    payload);
end
