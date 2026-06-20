function candidate = build_complete_rescheduling_candidate( ...
    problem, machineData, agvData, schedule, state, cancel, chrom, config)
%BUILD_COMPLETE_RESCHEDULING_CANDIDATE Build first complete rescheduling candidate.
%   This function combines stage D3-D9. It decodes one caller-provided
%   chromosome through the independent decoder adapter; it does not start
%   population search or compare against local repair.

if nargin < 8
    error('build_complete_rescheduling_candidate:MissingInput', ...
        ['problem, machineData, agvData, schedule, state, cancel, ', ...
        'chrom, and config are required.']);
end

candidate = empty_candidate();

[isCancelValid, cancelReport] = validate_order_cancellation_event( ...
    cancel, problem);
candidate.report.cancelValidation = cancelReport;
if ~isCancelValid
    candidate = reject_candidate(candidate, ...
        'invalid_cancel_event', cancelReport.errors);
    return
end

if ~is_state_consistent(state, cancel)
    candidate = reject_candidate(candidate, ...
        'state_cancel_mismatch', ...
        {'state.cancel must match cancel.'});
    return
end

if has_unsupported_state(state)
    candidate = reject_candidate(candidate, ...
        'unsupported_processing_state', ...
        {'Stage D first version rejects processing operations or AGV tasks.'});
    return
end

prefix = extract_frozen_schedule_prefix(schedule, state, cancel);
candidate.report.prefix = prefix.report;
if ~prefix.isFeasible
    candidate = reject_candidate(candidate, ...
        'frozen_prefix_infeasible', prefix.report.rejectedReasons);
    return
end

remainingSet = build_remaining_operation_set(state, cancel);
candidate.report.remainingSet = remainingSet.report;
if ~remainingSet.isFeasible
    candidate = reject_candidate(candidate, ...
        'remaining_operation_set_infeasible', remainingSet.report.errors);
    return
end

reschedulingProblem = build_rescheduling_problem( ...
    problem, machineData, agvData, remainingSet, cancel);
candidate.report.reschedulingProblem = reschedulingProblem.report;
if ~reschedulingProblem.isFeasible
    candidate = reject_candidate(candidate, ...
        'rescheduling_problem_infeasible', reschedulingProblem.report.errors);
    return
end

constraints = build_rescheduling_constraints(prefix, remainingSet, cancel);
candidate.report.constraints = constraints.report;
if ~constraints.isFeasible
    candidate = reject_candidate(candidate, ...
        'rescheduling_constraints_infeasible', constraints.report.errors);
    return
end

decodedCandidate = decode_complete_rescheduling_candidate( ...
    reschedulingProblem, constraints, chrom, config);
candidate.report.decode = decodedCandidate.report;
if ~decodedCandidate.isFeasible
    candidate = reject_candidate(candidate, ...
        'complete_rescheduling_decode_infeasible', ...
        decodedCandidate.report.errors);
    return
end

pipelineReport = candidate.report;
mergedCandidate = merge_frozen_and_rescheduled_schedule( ...
    constraints, decodedCandidate, cancel);
candidate = mergedCandidate;
candidate.report.pipeline = pipelineReport;
candidate.frozen_operations = prefix.frozen_operations;
candidate.frozen_agv_tasks = prefix.frozen_agv_tasks;
candidate.excluded_operations = reschedulingProblem.excluded_operations;

[isFeasible, feasibilityReport] = check_complete_rescheduling_candidate( ...
    problem, candidate, constraints, cancel);
candidate.report.completeFeasibilityCheck = feasibilityReport;
candidate.isFeasible = isFeasible;
if ~isFeasible
    candidate.report.errors = [candidate.report.errors, ...
        feasibilityReport.errors];
end
end

function isConsistent = is_state_consistent(state, cancel)
isConsistent = isstruct(state) && isfield(state, 'cancel') && ...
    isfield(state.cancel, 'job_id') && isfield(state.cancel, 'cancel_time') && ...
    state.cancel.job_id == cancel.job_id && ...
    state.cancel.cancel_time == cancel.cancel_time;
end

function hasUnsupported = has_unsupported_state(state)
hasUnsupported = false;
if isfield(state, 'has_unsupported_operations')
    hasUnsupported = hasUnsupported || state.has_unsupported_operations;
end
if isfield(state, 'has_unsupported_agv_tasks')
    hasUnsupported = hasUnsupported || state.has_unsupported_agv_tasks;
end
end

function candidate = reject_candidate(candidate, reason, errors)
candidate.isFeasible = false;
candidate.report.rejectedReasons{end + 1} = reason;
if ischar(errors)
    candidate.report.errors{end + 1} = errors;
    return
end

for i = 1:numel(errors)
    candidate.report.errors{end + 1} = errors{i};
end
end

function candidate = empty_candidate()
candidate = struct();
candidate.machineTable = {};
candidate.AGVTable = {};
candidate.jobCompleteUnLoad = [];
candidate.frozen_operations = struct([]);
candidate.frozen_agv_tasks = struct([]);
candidate.rescheduled_operations = struct([]);
candidate.excluded_operations = struct([]);
candidate.isFeasible = false;
candidate.report = struct();
candidate.report.errors = {};
candidate.report.warnings = {};
candidate.report.rejectedReasons = {};
end
