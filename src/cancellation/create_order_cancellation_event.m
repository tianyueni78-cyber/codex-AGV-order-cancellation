function cancel = create_order_cancellation_event(jobId, cancelTime, policy)
%CREATE_ORDER_CANCELLATION_EVENT Build a single order-cancellation event.
%   cancel = CREATE_ORDER_CANCELLATION_EVENT(jobId, cancelTime) creates the
%   minimal event used by the first order-cancellation stage. The default
%   policy is cancel_unstarted_operations_only.

if nargin < 2
    error('create_order_cancellation_event:MissingInput', ...
        'jobId and cancelTime are required.');
end

if nargin < 3 || isempty(policy)
    policy = 'cancel_unstarted_operations_only';
end

cancel = struct();
cancel.job_id = jobId;
cancel.cancel_time = cancelTime;
cancel.policy = policy;
end
