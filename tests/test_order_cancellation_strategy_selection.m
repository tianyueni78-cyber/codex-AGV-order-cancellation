clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

localEvaluation = make_evaluation('local_repair', true, 0.20);
completeEvaluation = make_evaluation('complete_rescheduling', true, 0.35);
selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);
assert(selection.isSelected, 'Selection should succeed.');
assert(strcmp(selection.name, 'local_repair'), ...
    'Smaller local repair Y should be selected.');
assert(strcmp(selection.reason, 'smaller_Y'), ...
    'Selection should record smaller_Y reason.');

localEvaluation = make_evaluation('local_repair', true, 0.60);
completeEvaluation = make_evaluation('complete_rescheduling', true, 0.25);
selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);
assert(selection.isSelected, 'Selection should succeed.');
assert(strcmp(selection.name, 'complete_rescheduling'), ...
    'Smaller complete rescheduling Y should be selected.');
assert(strcmp(selection.reason, 'smaller_Y'), ...
    'Selection should record smaller_Y reason.');

localEvaluation = make_evaluation('local_repair', false, []);
completeEvaluation = make_evaluation('complete_rescheduling', true, 0.25);
selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);
assert(selection.isSelected, ...
    'Single feasible complete rescheduling candidate should be selected.');
assert(strcmp(selection.name, 'complete_rescheduling'), ...
    'Only feasible complete rescheduling candidate should be selected.');
assert(strcmp(selection.reason, 'only_feasible_candidate'), ...
    'Selection should record only_feasible_candidate reason.');

localEvaluation = make_evaluation('local_repair', true, 0.25);
completeEvaluation = make_evaluation('complete_rescheduling', false, []);
selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);
assert(selection.isSelected, ...
    'Single feasible local repair candidate should be selected.');
assert(strcmp(selection.name, 'local_repair'), ...
    'Only feasible local repair candidate should be selected.');

localEvaluation = make_evaluation('local_repair', false, []);
completeEvaluation = make_evaluation('complete_rescheduling', false, []);
selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);
assert(~selection.isSelected, ...
    'Two infeasible candidates should reject strategy selection.');
assert(strcmp(selection.reason, 'no_feasible_candidate'), ...
    'Two infeasible candidates should record no_feasible_candidate.');
assert(~isempty(selection.report.errors), ...
    'Rejected selection should record an error.');

localEvaluation = make_evaluation('local_repair', true, 0.30);
completeEvaluation = make_evaluation('complete_rescheduling', true, 0.30);
selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);
assert(selection.isSelected, 'Tie selection should succeed.');
assert(strcmp(selection.name, 'local_repair'), ...
    'Tie should choose local repair in the first version.');
assert(strcmp(selection.reason, 'tie_break_local_repair'), ...
    'Tie should record tie_break_local_repair reason.');

fprintf('test_order_cancellation_strategy_selection passed\n');

function evaluation = make_evaluation(strategyName, isFeasible, Y)
evaluation = struct();
evaluation.strategyName = strategyName;
evaluation.metrics = struct();
evaluation.metrics.isFeasible = isFeasible;
evaluation.metrics.Y = Y;
evaluation.report = struct();
evaluation.report.rejectedReasons = {};
if ~isFeasible
    evaluation.report.rejectedReasons{end + 1} = ...
        'test_infeasible_candidate';
end
end
