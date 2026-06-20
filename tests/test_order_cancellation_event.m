clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = struct();
problem.jobNum = 3;

cancel = create_order_cancellation_event(2, 10);
assert(cancel.job_id == 2, 'cancel.job_id should match input.');
assert(cancel.cancel_time == 10, 'cancel.cancel_time should match input.');
assert(strcmp(cancel.policy, 'cancel_unstarted_operations_only'), ...
    'Default policy should be cancel_unstarted_operations_only.');
expect_valid(cancel, problem);

cancel = create_order_cancellation_event(1, 0, ...
    'cancel_unstarted_operations_only');
expect_valid(cancel, problem);

cancel = create_order_cancellation_event(0, 10);
expect_invalid(cancel, problem, 'cancel.job_id must be in');

cancel = create_order_cancellation_event(problem.jobNum + 1, 10);
expect_invalid(cancel, problem, 'cancel.job_id must be in');

cancel = create_order_cancellation_event(1.5, 10);
expect_invalid(cancel, problem, 'cancel.job_id must be a finite integer');

cancel = create_order_cancellation_event(1, -1);
expect_invalid(cancel, problem, 'cancel.cancel_time must be nonnegative');

cancel = create_order_cancellation_event(1, inf);
expect_invalid(cancel, problem, 'cancel.cancel_time must be a finite');

cancel = create_order_cancellation_event(1, 10, 'cancel_anything');
expect_invalid(cancel, problem, 'Unsupported cancel.policy');

cancel = create_order_cancellation_event(1, 10);
cancel = rmfield(cancel, 'policy');
expect_invalid(cancel, problem, 'cancel.policy is required');

fprintf('test_order_cancellation_event passed\n');

function expect_valid(cancel, problem)
[isValid, report] = validate_order_cancellation_event(cancel, problem);
assert(isValid, ['Expected cancel event to be valid. Errors:', newline, ...
    strjoin(report.errors, newline)]);
end

function expect_invalid(cancel, problem, expectedMessage)
[isValid, report] = validate_order_cancellation_event(cancel, problem);
assert(~isValid, 'Expected cancel event to be invalid.');
assert_has_error(report, expectedMessage);
end

function assert_has_error(report, expectedMessage)
joinedErrors = strjoin(report.errors, newline);
assert(~isempty(strfind(joinedErrors, expectedMessage)), ...
    ['Expected error containing: ', expectedMessage, newline, ...
    'Actual errors:', newline, joinedErrors]);
end
