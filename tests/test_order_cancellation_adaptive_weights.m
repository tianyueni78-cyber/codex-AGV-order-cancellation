clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

baseConfig = make_base_config();

earlyFeatures = make_features();
earlyFeatures.cancel_time_ratio = 0.20;
[earlyWeights, earlyReport] = adapt_evaluation_weights( ...
    earlyFeatures, baseConfig);
assert(earlyWeights.Cmax_delta > baseConfig.weights.Cmax_delta, ...
    'Early cancellation should increase Cmax_delta weight.');
assert(earlyWeights.energy_delta > baseConfig.weights.energy_delta, ...
    'Early cancellation should increase energy_delta weight.');
assert_has_rule(earlyReport, 'early_cancel_efficiency_focus');
assert_weight_sum_one(earlyWeights);

lateFeatures = make_features();
lateFeatures.cancel_time_ratio = 0.80;
[lateWeights, lateReport] = adapt_evaluation_weights( ...
    lateFeatures, baseConfig);
assert(lateWeights.SD > baseConfig.weights.SD, ...
    'Late cancellation should increase SD weight.');
assert(lateWeights.TD > baseConfig.weights.TD, ...
    'Late cancellation should increase TD weight.');
assert_has_rule(lateReport, 'late_cancel_stability_focus');
assert_weight_sum_one(lateWeights);

frozenFeatures = make_features();
frozenFeatures.cancel_time_ratio = 0.50;
frozenFeatures.frozen_operation_ratio = 0.80;
[frozenWeights, frozenReport] = adapt_evaluation_weights( ...
    frozenFeatures, baseConfig);
assert(frozenWeights.SD > baseConfig.weights.SD, ...
    'High frozen ratio should increase SD weight.');
assert(frozenWeights.TD > baseConfig.weights.TD, ...
    'High frozen ratio should increase TD weight.');
assert_has_rule(frozenReport, 'high_frozen_ratio_stability_focus');
assert_weight_sum_one(frozenWeights);

remainingFeatures = make_features();
remainingFeatures.cancel_time_ratio = 0.50;
remainingFeatures.remaining_operation_count = 6;
[remainingWeights, remainingReport] = adapt_evaluation_weights( ...
    remainingFeatures, baseConfig);
assert(remainingWeights.Cmax_delta > baseConfig.weights.Cmax_delta, ...
    'Many remaining operations should increase Cmax_delta weight.');
assert(remainingWeights.energy_delta > baseConfig.weights.energy_delta, ...
    'Many remaining operations should increase energy_delta weight.');
assert_has_rule(remainingReport, ...
    'many_remaining_operations_efficiency_focus');
assert_weight_sum_one(remainingWeights);

unsupportedFeatures = make_features();
unsupportedFeatures.unsupported_flag = true;
[unsupportedWeights, unsupportedReport] = adapt_evaluation_weights( ...
    unsupportedFeatures, baseConfig);
assert_weights_equal(unsupportedWeights, baseConfig.weights);
assert(strcmp(unsupportedReport.reason, 'unsupported_state_keep_baseline'), ...
    'Unsupported state should keep baseline weights.');
assert_has_rule(unsupportedReport, 'unsupported_state');
assert_weight_sum_one(unsupportedWeights);

fprintf('test_order_cancellation_adaptive_weights passed\n');

function config = make_base_config()
config = struct();
config.weights = struct();
config.weights.Cmax_delta = 0.25;
config.weights.SD = 0.25;
config.weights.TD = 0.25;
config.weights.energy_delta = 0.25;
config.adaptive = struct();
config.adaptive.remaining_operation_count_high = 3;
end

function features = make_features()
features = struct();
features.cancel_time_ratio = 0.50;
features.remaining_operation_count = 1;
features.cancelled_operation_count = 1;
features.frozen_operation_ratio = 0.20;
features.remaining_agv_task_count = 1;
features.cancelled_agv_task_count = 1;
features.local_repair_feasible = true;
features.complete_rescheduling_feasible = true;
features.unsupported_flag = false;
end

function assert_has_rule(report, expectedRule)
assert(any(strcmp(report.applied_rules, expectedRule)), ...
    ['Expected applied rule: ', expectedRule]);
end

function assert_weight_sum_one(weights)
total = weights.Cmax_delta + weights.SD + weights.TD + ...
    weights.energy_delta;
assert(abs(total - 1) < 1e-12, 'Adaptive weights should sum to 1.');
assert(weights.Cmax_delta >= 0, 'Cmax_delta weight should be nonnegative.');
assert(weights.SD >= 0, 'SD weight should be nonnegative.');
assert(weights.TD >= 0, 'TD weight should be nonnegative.');
assert(weights.energy_delta >= 0, ...
    'energy_delta weight should be nonnegative.');
end

function assert_weights_equal(actual, expected)
assert(abs(actual.Cmax_delta - expected.Cmax_delta) < 1e-12, ...
    'Cmax_delta baseline weight mismatch.');
assert(abs(actual.SD - expected.SD) < 1e-12, ...
    'SD baseline weight mismatch.');
assert(abs(actual.TD - expected.TD) < 1e-12, ...
    'TD baseline weight mismatch.');
assert(abs(actual.energy_delta - expected.energy_delta) < 1e-12, ...
    'energy_delta baseline weight mismatch.');
end
