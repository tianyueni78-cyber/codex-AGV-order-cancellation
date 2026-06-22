clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'events'));

problem = struct();
problem.jobNum = 3;

cancel = create_order_cancellation_event(2, 10);
event = order_cancellation_to_schedule_change_event(cancel, 101);

assert(event.event_id == 101, 'event_id should match input.');
assert(strcmp(event.event_type, 'cancel_order'), ...
    'cancel_order event_type should be set.');
assert(event.event_time == cancel.cancel_time, ...
    'event_time should map from cancel.cancel_time.');
assert(strcmp(event.policy, cancel.policy), ...
    'event.policy should map from cancel.policy.');
assert(event.payload.job_id == cancel.job_id, ...
    'event.payload.job_id should map from cancel.job_id.');

expect_valid(event, problem);

restoredCancel = schedule_change_event_to_order_cancellation(event);
assert(restoredCancel.job_id == cancel.job_id, ...
    'Restored cancel.job_id should match original cancel.');
assert(restoredCancel.cancel_time == cancel.cancel_time, ...
    'Restored cancel.cancel_time should match original cancel.');
assert(strcmp(restoredCancel.policy, cancel.policy), ...
    'Restored cancel.policy should match original cancel.');

[isCancelValid, cancelReport] = validate_order_cancellation_event( ...
    restoredCancel, problem);
assert(isCancelValid, ['Restored cancel should pass existing validator.', ...
    newline, strjoin(cancelReport.errors, newline)]);

newJob = make_new_job(4);
insertEvent = insert_order_to_schedule_change_event(newJob, 12, 201);
assert(strcmp(insertEvent.event_type, 'insert_order'), ...
    'insert_order event_type should be set.');
assert(insertEvent.event_time == 12, ...
    'insert_order event_time should match input.');
assert(strcmp(insertEvent.policy, 'insert_order_interface_only'), ...
    'insert_order default policy should be interface-only.');
assert(insertEvent.payload.new_job.job_id == newJob.job_id, ...
    'insert_order payload should keep new_job.');

expect_pending(insertEvent, problem);

invalidTypeEvent = event;
invalidTypeEvent.event_type = 'machine_fault';
expect_invalid(invalidTypeEvent, problem, 'Unsupported event.event_type');

invalidTimeEvent = event;
invalidTimeEvent.event_time = -1;
expect_invalid(invalidTimeEvent, problem, ...
    'event.event_time must be nonnegative');

missingCancelJobEvent = event;
missingCancelJobEvent.payload = struct();
expect_invalid(missingCancelJobEvent, problem, ...
    'event.payload.job_id is required');

missingNewJobEvent = insertEvent;
missingNewJobEvent.payload = struct();
expect_invalid(missingNewJobEvent, problem, ...
    'event.payload.new_job is required');

fprintf('test_schedule_change_event passed\n');

function newJob = make_new_job(jobId)
newJob = struct();
newJob.job_id = jobId;
newJob.operations = [1, 2];
newJob.processing_times = [3, 4];
newJob.machine_options = {[1, 2], [2]};
newJob.due_date = 30;
end

function expect_valid(event, problem)
[isValid, report] = validate_schedule_change_event(event, problem);
assert(isValid, ['Expected schedule change event to be valid. Errors:', ...
    newline, strjoin(report.errors, newline)]);
assert(~report.isPending, 'cancel_order should not be marked pending.');
assert(strcmp(report.status, 'valid'), 'cancel_order status should be valid.');
end

function expect_pending(event, problem)
[isValid, report] = validate_schedule_change_event(event, problem);
assert(isValid, ['Expected insert_order interface event to be valid. Errors:', ...
    newline, strjoin(report.errors, newline)]);
assert(report.isPending, 'insert_order should be marked pending.');
assert(strcmp(report.status, 'pending'), 'insert_order status should be pending.');
end

function expect_invalid(event, problem, expectedMessage)
[isValid, report] = validate_schedule_change_event(event, problem);
assert(~isValid, 'Expected schedule change event to be invalid.');
assert_has_error(report, expectedMessage);
end

function assert_has_error(report, expectedMessage)
joinedErrors = strjoin(report.errors, newline);
assert(~isempty(strfind(joinedErrors, expectedMessage)), ...
    ['Expected error containing: ', expectedMessage, newline, ...
    'Actual errors:', newline, joinedErrors]);
end
