function decision = select_hybrid_cancellation_policy( ...
    localRepairCandidate, completeReschedulingCandidate, ...
    localRepairEvaluation, completeReschedulingEvaluation, config)
%SELECT_HYBRID_CANCELLATION_POLICY Select a hybrid cancellation policy.
%   The hybrid policy layer only reads already-built candidates and already
%   computed evaluations. It does not extract state, repair schedules,
%   reschedule operations, calculate metrics, or write outputs.

if nargin < 5
    decision = empty_decision();
    decision.reason = 'missing_required_input';
    decision.report.errors{end + 1} = ...
        ['localRepairCandidate, completeReschedulingCandidate, ', ...
        'localRepairEvaluation, completeReschedulingEvaluation, ', ...
        'and config are required.'];
    return
end

decision = empty_decision();
hybridConfig = read_hybrid_policy_config(config, decision);
decision.report = hybridConfig.report;
if ~isempty(decision.report.errors)
    decision.reason = 'unsupported_config';
    return
end

localStatus = candidate_status(localRepairCandidate, ...
    localRepairEvaluation, 'local_repair');
completeStatus = candidate_status(completeReschedulingCandidate, ...
    completeReschedulingEvaluation, 'complete_rescheduling');

decision.local_repair_evaluation = localRepairEvaluation;
decision.complete_rescheduling_evaluation = completeReschedulingEvaluation;
decision.local_repair_isFeasible = localStatus.isFeasible;
decision.complete_rescheduling_isFeasible = completeStatus.isFeasible;
decision.threshold_report = build_threshold_report( ...
    localRepairEvaluation, localRepairCandidate, hybridConfig);

if localStatus.isFeasible && completeStatus.isFeasible
    decision.triggered_complete_rescheduling = true;
    decision = select_between_feasible_candidates( ...
        decision, localRepairCandidate, completeReschedulingCandidate, ...
        localStatus, completeStatus, hybridConfig);
elseif localStatus.isFeasible
    decision = select_local_or_triggered_fallback( ...
        decision, localRepairCandidate, localStatus, hybridConfig);
elseif completeStatus.isFeasible && ...
        hybridConfig.enable_complete_if_local_infeasible
    decision.triggered_complete_rescheduling = true;
    decision = select_complete(decision, completeReschedulingCandidate, ...
        completeStatus, 'local_infeasible_trigger_complete');
else
    decision.reason = 'both_infeasible';
    decision.report.rejectedReasons{end + 1} = ...
        'Both local repair and complete rescheduling are infeasible.';
end

decision.report.isFeasible = decision.isSelected;
end

function decision = select_between_feasible_candidates( ...
    decision, localCandidate, completeCandidate, localStatus, ...
    completeStatus, hybridConfig)
if hybridConfig.use_stage_e_y_selection
    if completeStatus.Y < localStatus.Y
        decision = select_complete(decision, completeCandidate, ...
            completeStatus, 'complete_better_Y');
    elseif localStatus.Y < completeStatus.Y
        decision = select_local(decision, localCandidate, ...
            localStatus, 'local_better_Y');
    else
        decision = select_local(decision, localCandidate, ...
            localStatus, 'tie_break_local');
    end
elseif threshold_triggered(decision.threshold_report)
    decision = select_complete(decision, completeCandidate, ...
        completeStatus, 'threshold_trigger_complete');
else
    decision.triggered_complete_rescheduling = false;
    decision = select_local(decision, localCandidate, ...
        localStatus, 'local_stable_enough');
end
end

function decision = select_local_or_triggered_fallback( ...
    decision, localCandidate, localStatus, hybridConfig)
if threshold_triggered(decision.threshold_report)
    decision.triggered_complete_rescheduling = true;
    decision.report.rejectedReasons{end + 1} = ...
        'Complete rescheduling was triggered but is infeasible.';
    decision = select_local(decision, localCandidate, localStatus, ...
        'complete_triggered_but_infeasible');
else
    decision.triggered_complete_rescheduling = false;
    decision = select_local(decision, localCandidate, localStatus, ...
        'local_stable_enough');
end
end

function decision = select_local(decision, candidate, status, reason)
decision.isSelected = true;
decision.selected_strategy = 'local_repair';
decision.selected_candidate = candidate;
decision.reason = reason;
decision.report.selectedY = status.Y;
end

function decision = select_complete(decision, candidate, status, reason)
decision.isSelected = true;
decision.selected_strategy = 'complete_rescheduling';
decision.selected_candidate = candidate;
decision.reason = reason;
decision.report.selectedY = status.Y;
end

function status = candidate_status(candidate, evaluation, defaultName)
status = struct();
status.name = defaultName;
status.isFeasible = false;
status.Y = Inf;
status.rejectedReasons = {};

if ~isstruct(candidate)
    status.rejectedReasons{end + 1} = 'invalid_candidate';
    return
end

if ~isfield(candidate, 'isFeasible') || ~candidate.isFeasible
    status.rejectedReasons{end + 1} = 'candidate_infeasible';
    return
end

if ~isstruct(evaluation) || ~isfield(evaluation, 'metrics') || ...
        ~isfield(evaluation.metrics, 'isFeasible') || ...
        ~evaluation.metrics.isFeasible
    status.rejectedReasons{end + 1} = 'evaluation_infeasible';
    return
end

if isfield(evaluation, 'strategyName') && ~isempty(evaluation.strategyName)
    status.name = evaluation.strategyName;
end

if isfield(evaluation.metrics, 'Y') && ...
        isnumeric(evaluation.metrics.Y) && isscalar(evaluation.metrics.Y)
    status.Y = evaluation.metrics.Y;
else
    status.rejectedReasons{end + 1} = 'missing_Y';
    return
end

status.isFeasible = true;
end

function thresholdReport = build_threshold_report( ...
    localEvaluation, localCandidate, hybridConfig)
thresholdReport = struct();
thresholdReport.cmax_delta = metric_value(localEvaluation, 'Cmax_delta');
thresholdReport.energy_delta = metric_value(localEvaluation, 'energy_delta');
thresholdReport.idle_waste = idle_waste_value(localEvaluation, localCandidate);
thresholdReport.cmax_delta_threshold = hybridConfig.cmax_delta_threshold;
thresholdReport.energy_delta_threshold = hybridConfig.energy_delta_threshold;
thresholdReport.idle_waste_threshold = hybridConfig.idle_waste_threshold;
thresholdReport.cmax_delta_triggered = thresholdReport.cmax_delta > ...
    hybridConfig.cmax_delta_threshold;
thresholdReport.energy_delta_triggered = thresholdReport.energy_delta > ...
    hybridConfig.energy_delta_threshold;
thresholdReport.idle_waste_triggered = thresholdReport.idle_waste > ...
    hybridConfig.idle_waste_threshold;
thresholdReport.any_triggered = threshold_triggered(thresholdReport);
end

function value = metric_value(evaluation, fieldName)
value = -Inf;
if isstruct(evaluation) && isfield(evaluation, 'metrics') && ...
        isfield(evaluation.metrics, fieldName) && ...
        isnumeric(evaluation.metrics.(fieldName)) && ...
        isscalar(evaluation.metrics.(fieldName))
    value = evaluation.metrics.(fieldName);
end
end

function value = idle_waste_value(evaluation, candidate)
value = 0;
if isstruct(evaluation) && isfield(evaluation, 'metrics') && ...
        isfield(evaluation.metrics, 'idle_waste') && ...
        isnumeric(evaluation.metrics.idle_waste) && ...
        isscalar(evaluation.metrics.idle_waste)
    value = evaluation.metrics.idle_waste;
elseif isstruct(candidate) && isfield(candidate, 'idle_waste') && ...
        isnumeric(candidate.idle_waste) && isscalar(candidate.idle_waste)
    value = candidate.idle_waste;
end
end

function isTriggered = threshold_triggered(thresholdReport)
isTriggered = thresholdReport.cmax_delta_triggered || ...
    thresholdReport.energy_delta_triggered || ...
    thresholdReport.idle_waste_triggered;
end

function hybridConfig = read_hybrid_policy_config(config, decision)
hybridConfig = default_hybrid_config();
hybridConfig.report = decision.report;

if ~isstruct(config)
    hybridConfig.report.errors{end + 1} = 'config must be a struct.';
    return
end

if ~isfield(config, 'hybrid_policy') || ...
        ~isstruct(config.hybrid_policy)
    hybridConfig.report.warnings{end + 1} = ...
        'config.hybrid_policy missing; using documented defaults.';
    hybridConfig.report.defaultConfigSource = 'documented_stage_h_defaults';
    return
end

fieldNames = {'enable_complete_if_local_infeasible', ...
    'use_stage_e_y_selection', 'cmax_delta_threshold', ...
    'energy_delta_threshold', 'idle_waste_threshold', ...
    'threshold_validation_status'};
for i = 1:numel(fieldNames)
    fieldName = fieldNames{i};
    if isfield(config.hybrid_policy, fieldName)
        hybridConfig.(fieldName) = config.hybrid_policy.(fieldName);
    else
        hybridConfig.report.warnings{end + 1} = sprintf( ...
            'config.hybrid_policy.%s missing; using default.', fieldName);
    end
end

hybridConfig = validate_hybrid_config(hybridConfig);
end

function hybridConfig = validate_hybrid_config(hybridConfig)
if ~islogical_scalar(hybridConfig.enable_complete_if_local_infeasible)
    hybridConfig.report.errors{end + 1} = ...
        ['config.hybrid_policy.enable_complete_if_local_infeasible ', ...
        'must be a logical scalar.'];
end
if ~islogical_scalar(hybridConfig.use_stage_e_y_selection)
    hybridConfig.report.errors{end + 1} = ...
        'config.hybrid_policy.use_stage_e_y_selection must be a logical scalar.';
end

numericFields = {'cmax_delta_threshold', 'energy_delta_threshold', ...
    'idle_waste_threshold'};
for i = 1:numel(numericFields)
    fieldName = numericFields{i};
    if ~isnumeric(hybridConfig.(fieldName)) || ...
            ~isscalar(hybridConfig.(fieldName))
        hybridConfig.report.errors{end + 1} = sprintf( ...
            'config.hybrid_policy.%s must be a numeric scalar.', fieldName);
    end
end

if ~ischar(hybridConfig.threshold_validation_status) && ...
        ~isstring(hybridConfig.threshold_validation_status)
    hybridConfig.report.errors{end + 1} = ...
        ['config.hybrid_policy.threshold_validation_status ', ...
        'must be a char or string scalar.'];
end
end

function tf = islogical_scalar(value)
tf = (islogical(value) || isnumeric(value)) && isscalar(value) && ...
    (value == 0 || value == 1);
end

function hybridConfig = default_hybrid_config()
hybridConfig = struct();
hybridConfig.enable_complete_if_local_infeasible = true;
hybridConfig.use_stage_e_y_selection = true;
hybridConfig.cmax_delta_threshold = 0;
hybridConfig.energy_delta_threshold = 0;
hybridConfig.idle_waste_threshold = Inf;
hybridConfig.threshold_validation_status = 'pending_stage_l_validation';
end

function decision = empty_decision()
decision = struct();
decision.isSelected = false;
decision.selected_strategy = '';
decision.selected_candidate = [];
decision.reason = '';
decision.triggered_complete_rescheduling = false;
decision.local_repair_evaluation = struct();
decision.complete_rescheduling_evaluation = struct();
decision.local_repair_isFeasible = false;
decision.complete_rescheduling_isFeasible = false;
decision.threshold_report = struct();
decision.report = struct();
decision.report.errors = {};
decision.report.warnings = {};
decision.report.rejectedReasons = {};
decision.report.defaultConfigSource = '';
decision.report.selectedY = [];
decision.report.isFeasible = false;
end
