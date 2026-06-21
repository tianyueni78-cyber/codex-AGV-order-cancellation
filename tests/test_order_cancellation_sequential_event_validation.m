clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = struct();
problem.jobNum = 4;

events = [
    make_event(2, 3, 20)
    make_event(1, 1, 10)
];
[isValid, sortedEvents, report] = validate_sequential_cancellation_events( ...
    events, problem);
assert(isValid, ['Expected sequential events to be valid. Errors:', ...
    newline, strjoin(report.errors, newline)]);
assert(sortedEvents(1).event_id == 1, ...
    'Events should be sorted by cancel_time ascending.');
assert(sortedEvents(2).event_id == 2, ...
    'Events should preserve the later cancel_time second.');
assert(isequal(report.sorted_order, [2, 1]), ...
    'sorted_order should record stable sorting from original input.');

events = [
    make_event(1, 1, 10)
    make_event(2, 1, 20)
];
expect_invalid(events, problem, 'Duplicate cancellation for job_id');

events = [
    make_event(1, 0, 10)
    make_event(2, 1, 20)
];
expect_invalid(events, problem, 'cancel.job_id must be in');

events = [
    make_event(1, 1, -1)
    make_event(2, 2, 20)
];
expect_invalid(events, problem, 'cancel.cancel_time must be nonnegative');

events = [
    make_event(1, 1, 10, 'cancel_anything')
    make_event(2, 2, 20)
];
expect_invalid(events, problem, 'Unsupported cancel.policy');

events = make_event(1, 1, 10);
expect_invalid(events, problem, 'at least 2 events');

events = [
    make_event(2, 2, 10)
    make_event(1, 1, 10)
];
[isValid, sortedEvents, ~] = validate_sequential_cancellation_events( ...
    events, problem);
assert(isValid, 'Equal cancel_time events should be valid.');
assert(isequal([sortedEvents.event_id], [2, 1]), ...
    'Equal cancel_time events should preserve input order.');

fprintf('test_order_cancellation_sequential_event_validation passed\n');

function event = make_event(eventId, jobId, cancelTime, policy)
if nargin < 4
    policy = 'cancel_unstarted_operations_only';
end

event = struct();
event.event_id = eventId;
event.job_id = jobId;
event.cancel_time = cancelTime;
event.policy = policy;
end

function expect_invalid(events, problem, expectedMessage)
[isValid, ~, report] = validate_sequential_cancellation_events( ...
    events, problem);
assert(~isValid, 'Expected sequential events to be invalid.');
assert_has_error(report, expectedMessage);
end

function assert_has_error(report, expectedMessage)
joinedErrors = strjoin(report.errors, newline);
assert(~isempty(strfind(joinedErrors, expectedMessage)), ...
    ['Expected error containing: ', expectedMessage, newline, ...
    'Actual errors:', newline, joinedErrors]);
end
