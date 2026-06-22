function result = select_adaptive_cancellation_strategy( ...
    baselineSchedule, state, cancel, localRepairCandidate, ...
    completeReschedulingCandidate, machineData, agvData, baseConfig)
%SELECT_ADAPTIVE_CANCELLATION_STRATEGY Select strategy with adaptive weights.
%   result = SELECT_ADAPTIVE_CANCELLATION_STRATEGY(...) extracts stage K
%   features, adapts config.weights, evaluates the local repair and complete
%   rescheduling candidates, then reuses the existing stage E selector.

if nargin < 8
    error('select_adaptive_cancellation_strategy:MissingInput', ...
        ['baselineSchedule, state, cancel, localRepairCandidate, ', ...
        'completeReschedulingCandidate, machineData, agvData, ', ...
        'and baseConfig are required.']);
end

result = empty_result();

features = extract_cancellation_features( ...
    baselineSchedule, state, cancel, localRepairCandidate, ...
    completeReschedulingCandidate);
[weights, adaptiveReport] = adapt_evaluation_weights(features, baseConfig);

adaptiveConfig = baseConfig;
adaptiveConfig.weights = weights;

localEvaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, localRepairCandidate, cancel, machineData, agvData, ...
    adaptiveConfig, 'local_repair');
completeEvaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, completeReschedulingCandidate, cancel, ...
    machineData, agvData, adaptiveConfig, 'complete_rescheduling');

selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);

result.features = features;
result.weights = weights;
result.adaptive_report = adaptiveReport;
result.config = adaptiveConfig;
result.localRepairEvaluation = localEvaluation;
result.completeReschedulingEvaluation = completeEvaluation;
result.selection = selection;
result.isSelected = selection.isSelected;
end

function result = empty_result()
result = struct();
result.features = struct();
result.weights = struct();
result.adaptive_report = struct();
result.config = struct();
result.localRepairEvaluation = struct();
result.completeReschedulingEvaluation = struct();
result.selection = struct();
result.isSelected = false;
end
