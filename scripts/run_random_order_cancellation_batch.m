% Random order cancellation batch acceptance.
% Local edit points:
%   seeds = 1:30;
%   cancelTimes = [5, 9, 13];
%   datasets = {'data_sample/Mk01.fjs'};
%
% Command-line override example:
% matlab -batch "cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation'); seeds=1:3; cancelTimes=[5 9]; run('scripts/run_random_order_cancellation_batch.m')"

clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'search'));
addpath(fullfile(projectRoot, 'src', 'baseline'));

if ~exist('seeds', 'var')
    seeds = 1:30;
end
if ~exist('cancelTimes', 'var')
    cancelTimes = [5, 9, 13];
end
if ~exist('datasets', 'var')
    datasets = {
        'raw_code/fjsp/Brandimarte_Data/Mk01.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk02.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk03.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk04.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk05.fjs'
    };
end
if ~exist('strategyPolicies', 'var')
    strategyPolicies = {'auto_selection'};
end
if ~exist('baseline_mode', 'var')
    baseline_mode = 'sample';
end
if ~exist('baselinePop', 'var')
    baselinePop = 20;
end
if ~exist('baselineMaxGen', 'var')
    baselineMaxGen = 10;
end
if ~exist('baselineSeed', 'var')
    baselineSeed = 1;
end

outputDir = make_output_dir(projectRoot);
outputCsv = fullfile(outputDir, 'batch_random_order_cancellation.csv');
rows = repmat(empty_row(), 1, 0);

for datasetIdx = 1:numel(datasets)
    dataset = datasets{datasetIdx};
    for policyIdx = 1:numel(strategyPolicies)
        strategyPolicy = strategyPolicies{policyIdx};
        try
            datasetState = load_dataset_state(projectRoot, dataset, ...
                baseline_mode, baselinePop, baselineMaxGen, baselineSeed);
        catch err
            rows = append_dataset_error_rows( ...
                rows, dataset, seeds, cancelTimes, strategyPolicy, ...
                format_exception(err));
            continue
        end

        for timeIdx = 1:numel(cancelTimes)
            cancelTime = cancelTimes(timeIdx);
            for seedIdx = 1:numel(seeds)
                seed = seeds(seedIdx);
                rows(end + 1) = run_one_random_case( ...
                    datasetState, dataset, seed, cancelTime, ...
                    strategyPolicy);
            end
        end
    end
end

write_rows_csv(outputCsv, rows);

fprintf('random order cancellation batch\n');
fprintf('dataset_count: %d\n', numel(datasets));
fprintf('seed_count: %d\n', numel(seeds));
fprintf('cancel_time_count: %d\n', numel(cancelTimes));
fprintf('strategy_policy_count: %d\n', numel(strategyPolicies));
fprintf('baseline_mode: %s\n', baseline_mode);
fprintf('row_count: %d\n', numel(rows));
fprintf('output_csv: %s\n', outputCsv);

function datasetState = load_dataset_state(projectRoot, dataset, baseline_mode, ...
    baselinePop, baselineMaxGen, baselineSeed)
datasetPath = fullfile(projectRoot, dataset);
problem = read_fjsp(datasetPath);
if strcmp(baseline_mode, 'sample')
    machineData = build_sample_machine_data(problem.machineNum);
    agvData = build_sample_agv_data();
    baselineSchedule = build_sample_schedule(problem.machineNum);
    decodeReport = struct();
elseif strcmp(baseline_mode, 'instance_decoded')
    baselineState = build_instance_driven_baseline_state(problem);
    machineData = baselineState.machineData;
    agvData = baselineState.agvData;
    baselineSchedule = baselineState.baselineSchedule;
    decodeReport = baselineState.decodeReport;
elseif strcmp(baseline_mode, 'static_solver')
    machineData = build_sample_machine_data(problem.machineNum);
    agvData = build_sample_agv_data();
    solverConfig = build_static_solver_config( ...
        baselinePop, baselineMaxGen, baselineSeed);
    baselineState = build_static_baseline_schedule( ...
        problem, machineData, agvData, solverConfig);
    baselineSchedule = baselineState.schedule;
    decodeReport = baselineState.decodeReport;
else
    error('random_order_cancellation_batch:InvalidBaselineMode', ...
        'Unsupported baseline_mode: %s', baseline_mode);
end

[baselineMetrics, baselineReport] = evaluate_candidate_cmax( ...
    baselineSchedule, baselineSchedule);
if ~baselineMetrics.isFeasible
    error('random_order_cancellation_batch:InvalidBaselineCmax', ...
        strjoin(baselineReport.errors, newline));
end

datasetState = struct();
datasetState.problem = problem;
datasetState.machineData = machineData;
datasetState.agvData = agvData;
datasetState.baselineSchedule = baselineSchedule;
datasetState.baselineCmax = baselineMetrics.Cmax;
datasetState.baselineMode = baseline_mode;
datasetState.decodeReport = decodeReport;
end

function row = run_one_random_case( ...
    datasetState, dataset, seed, cancelTime, strategyPolicy)
row = empty_row();
row.dataset = dataset;
row.seed = seed;
row.cancel_time = cancelTime;
row.strategy_policy = strategyPolicy;

try
    if cancelTime < 0 || cancelTime >= datasetState.baselineCmax
        error('random_order_cancellation_batch:InvalidCancelTime', ...
            'cancel_time must be >= 0 and < baseline Cmax %.6f.', ...
            datasetState.baselineCmax);
    end

    scenarioConfig = make_scenario_config(dataset, seed, cancelTime, ...
        datasetState.baselineCmax);
    [scenarios, ~] = build_order_cancellation_scenarios( ...
        datasetState.problem, datasetState.baselineSchedule, ...
        scenarioConfig);
    if isempty(scenarios)
        error('random_order_cancellation_batch:NoCancellableOrder', ...
            'No cancellable order exists at cancel_time %.6f.', ...
            cancelTime);
    end

    scenario = scenarios(1);
    runConfig = struct();
    runConfig.strategy_policy = strategyPolicy;
    result = run_order_cancellation_library_scenario( ...
        datasetState.problem, datasetState.machineData, ...
        datasetState.agvData, datasetState.baselineSchedule, ...
        scenario, runConfig);
    row = fill_success_row(row, result);
    if isfield(result, 'error_message') && ~isempty(result.error_message)
        row.error_message = result.error_message;
    end
catch err
    row.error_message = format_exception(err);
    row.diagnostic_note = row.error_message;
end
end

function config = make_scenario_config(dataset, seed, cancelTime, baselineCmax)
config = struct();
config.datasets = {dataset};
config.cancel_policy = 'cancel_unstarted_operations_only';
config.time_windows = struct();
config.time_windows.name = sprintf('time_%.6g', cancelTime);
config.time_windows.cancel_time_ratio = cancelTime / baselineCmax;
config.job_categories = {'random'};
config.seeds = seed;
end

function baselineState = build_instance_driven_baseline_state(problem)
machineData = build_sample_machine_data(problem.machineNum);
agvData = build_sample_agv_data();
decodeConfig = build_baseline_decode_config(problem, agvData);
chrom = build_deterministic_baseline_chromosome(problem, agvData);
[baselineSchedule, decodeReport] = decode_chromosome_independent( ...
    chrom, problem, machineData, agvData, decodeConfig);

if ~isfield(decodeReport, 'isValid') || ~decodeReport.isValid
    if isfield(decodeReport, 'errors') && ~isempty(decodeReport.errors)
        error('random_order_cancellation_batch:BaselineDecodeFailed', ...
            strjoin(decodeReport.errors, newline));
    end
    error('random_order_cancellation_batch:BaselineDecodeFailed', ...
        'Instance-driven baseline decoding failed.');
end

baselineState = struct();
baselineState.baselineSchedule = baselineSchedule;
baselineState.machineData = machineData;
baselineState.agvData = agvData;
baselineState.decodeReport = decodeReport;
baselineState.baselineMode = 'instance_decoded';
end

function config = build_static_solver_config(baselinePop, baselineMaxGen, ...
    baselineSeed)
config = struct();
config.algorithm = struct();
config.algorithm.name = 'Static Solver NSGA-II';
config.algorithm.p_cross = 0.8;
config.algorithm.p_mutation = 0.2;
config.algorithm.pop = baselinePop;
config.algorithm.max_gen = baselineMaxGen;
config.energy = struct();
config.energy.AGVEG_MAX = 100;
config.energy.eChargeSpeed = 20;
config.random = struct();
config.random.seed = baselineSeed;
end

function decodeConfig = build_baseline_decode_config(problem, agvData)
decodeConfig = struct();
decodeConfig.AGVEG_MAX = 100;
decodeConfig.AGVEG_MIN = 1;
decodeConfig.eChargeSpeed = 20;
decodeConfig.machineTable = build_decode_machine_table(problem.machineNum);
decodeConfig.AGVTable = build_decode_agv_table(agvData.AGVNum);
end

function chrom = build_deterministic_baseline_chromosome(problem, agvData)
operaNum = sum(problem.operaNumVec);
OS = build_os_sequence(problem);
MS = build_first_machine_selection(problem);
AS = mod(0:(operaNum - 1), agvData.AGVNum) + 1;
SS = ones(1, 2 * operaNum);
chrom = [OS, MS, AS, SS];
end

function OS = build_os_sequence(problem)
OS = zeros(1, sum(problem.operaNumVec));
pos = 1;
for jobIdx = 1:problem.jobNum
    for operaIdx = 1:problem.operaNumVec(jobIdx)
        OS(pos) = jobIdx;
        pos = pos + 1;
    end
end
end

function MS = build_first_machine_selection(problem)
MS = zeros(1, sum(problem.operaNumVec));
pos = 1;
for jobIdx = 1:problem.jobNum
    for operaIdx = 1:problem.operaNumVec(jobIdx)
        candidates = problem.candidateMachine{jobIdx, operaIdx};
        if isempty(candidates)
            error('random_order_cancellation_batch:MissingCandidateMachine', ...
                'candidateMachine{%d,%d} is empty.', jobIdx, operaIdx);
        end
        MS(pos) = 1;
        pos = pos + 1;
    end
end
end

function machineTable = build_decode_machine_table(machineNum)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = make_machine_block(0, inf, 0, 0);
end
end

function AGVTable = build_decode_agv_table(agvNum)
AGVTable = cell(1, agvNum);
for agvIdx = 1:agvNum
    AGVTable{agvIdx} = [
        make_agv_block(0, 0, 0, 0, -1, -1, 0)
        make_agv_block(0, inf, 0, 0, -1, -1, 0)
    ];
end
end

function row = fill_success_row(row, result)
row.canceled_order_id = result.cancel_job_id;
row.selected_strategy = result.selected_strategy;
if isfield(result, 'run_through')
    row.run_through = logical(result.run_through);
else
    row.run_through = result.local_candidate_isFeasible || ...
        result.complete_candidate_isFeasible;
end
if isfield(result, 'feasible')
    row.feasible = logical(result.feasible);
else
    row.feasible = result.local_isFeasible || result.complete_isFeasible;
end

switch result.selected_strategy
    case 'local_repair'
        row.Cmax_delta = result.local_Cmax_delta;
        row.SD = result.local_SD;
        row.TD = result.local_TD;
        row.Y = result.local_Y;
    case 'complete_rescheduling'
    row.Cmax_delta = result.complete_Cmax_delta;
    row.SD = result.complete_SD;
    row.TD = result.complete_TD;
    row.Y = result.complete_Y;
end

row = fill_diagnostic_fields(row, result);
end

function rows = append_dataset_error_rows(rows, dataset, seeds, cancelTimes, ...
    strategyPolicy, message)
for timeIdx = 1:numel(cancelTimes)
    for seedIdx = 1:numel(seeds)
        row = empty_row();
        row.dataset = dataset;
        row.seed = seeds(seedIdx);
        row.cancel_time = cancelTimes(timeIdx);
        row.strategy_policy = strategyPolicy;
        row.error_message = message;
        row.diagnostic_note = message;
        rows(end + 1) = row;
    end
end
end

function outputDir = make_output_dir(projectRoot)
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
outputDir = fullfile(projectRoot, 'outputs', ...
    'batch_random_order_cancellation', timestamp);
suffix = 1;
while exist(outputDir, 'dir')
    outputDir = fullfile(projectRoot, 'outputs', ...
        'batch_random_order_cancellation', ...
        sprintf('%s_%02d', timestamp, suffix));
    suffix = suffix + 1;
end
mkdir(outputDir);
end

function write_rows_csv(filePath, rows)
fid = fopen(filePath, 'w');
if fid < 0
    error('random_order_cancellation_batch:FileOpenFailed', ...
        'Cannot open CSV for writing: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['dataset,seed,cancel_time,canceled_order_id,', ...
    'strategy_policy,selected_strategy,run_through,feasible,', ...
    'Cmax_delta,SD,TD,Y,local_repair_status,local_repair_error,', ...
    'local_repair_validation_probe,', ...
    'complete_rescheduling_status,complete_rescheduling_error,', ...
    'canceled_order_state_at_cancel_time,', ...
    'canceled_order_started_op_count,', ...
    'canceled_order_finished_op_count,', ...
    'canceled_order_unstarted_op_count,', ...
    'frozen_operation_count,remaining_operation_count,', ...
    'diagnostic_note,error_message\n']);
for i = 1:numel(rows)
    row = rows(i);
    fprintf(fid, ['%s,%d,%.6f,%g,%s,%s,%d,%d,%.6f,%.6f,%.6f,%.6f,', ...
        '%s,%s,%s,%s,%s,%s,%d,%d,%d,%d,%d,%s,%s\n'], ...
        csv_text(row.dataset), row.seed, row.cancel_time, ...
        row.canceled_order_id, csv_text(row.strategy_policy), ...
        csv_text(row.selected_strategy), ...
        row.run_through, row.feasible, row.Cmax_delta, row.SD, row.TD, ...
        row.Y, csv_text(row.local_repair_status), ...
        csv_text(row.local_repair_error), ...
        csv_text(row.local_repair_validation_probe), ...
        csv_text(row.complete_rescheduling_status), ...
        csv_text(row.complete_rescheduling_error), ...
        csv_text(row.canceled_order_state_at_cancel_time), ...
        row.canceled_order_started_op_count, ...
        row.canceled_order_finished_op_count, ...
        row.canceled_order_unstarted_op_count, ...
        row.frozen_operation_count, row.remaining_operation_count, ...
        csv_text(row.diagnostic_note), csv_text(row.error_message));
end
end

function value = csv_text(value)
value = char(string(value));
value = strrep(value, '"', '""');
value = ['"', value, '"'];
end

function row = empty_row()
row = struct();
row.dataset = '';
row.seed = NaN;
row.cancel_time = NaN;
row.canceled_order_id = NaN;
row.strategy_policy = '';
row.selected_strategy = '';
row.run_through = false;
row.feasible = false;
row.Cmax_delta = NaN;
row.SD = NaN;
row.TD = NaN;
row.Y = NaN;
row.local_repair_status = 'not_called';
row.local_repair_error = 'unknown';
row.local_repair_validation_probe = '';
row.complete_rescheduling_status = 'not_called';
row.complete_rescheduling_error = 'unknown';
row.canceled_order_state_at_cancel_time = 'unknown';
row.canceled_order_started_op_count = 0;
row.canceled_order_finished_op_count = 0;
row.canceled_order_unstarted_op_count = 0;
row.frozen_operation_count = 0;
row.remaining_operation_count = 0;
row.diagnostic_note = '';
row.error_message = '';
end

function row = fill_diagnostic_fields(row, result)
if ~isstruct(result)
    row.diagnostic_note = 'result_missing';
    return
end

state = struct();
if isfield(result, 'details') && isstruct(result.details) && ...
        isfield(result.details, 'state')
    state = result.details.state;
end

cancel.job_id = read_numeric_field(result, 'cancel_job_id', NaN);
cancel.cancel_time = read_numeric_field(result, 'cancel_time', NaN);

[row.canceled_order_state_at_cancel_time, ...
    row.canceled_order_started_op_count, ...
    row.canceled_order_finished_op_count, ...
    row.canceled_order_unstarted_op_count, ...
    row.frozen_operation_count, row.remaining_operation_count] = ...
    summarize_cancellation_state(state, cancel);

localCandidate = struct();
completeCandidate = struct();
localEvaluation = struct();
completeEvaluation = struct();
selection = struct();
if isfield(result, 'details') && isstruct(result.details)
    if isfield(result.details, 'localCandidate')
        localCandidate = result.details.localCandidate;
    end
    if isfield(result.details, 'completeCandidate')
        completeCandidate = result.details.completeCandidate;
    end
    if isfield(result.details, 'localEvaluation')
        localEvaluation = result.details.localEvaluation;
    end
    if isfield(result.details, 'completeEvaluation')
        completeEvaluation = result.details.completeEvaluation;
    end
    if isfield(result.details, 'selection')
        selection = result.details.selection;
    end
end

[row.local_repair_status, row.local_repair_error] = ...
    summarize_candidate_diagnostics(localCandidate, localEvaluation, ...
    get_selection_candidate_status(selection, 'localRepair'), ...
    state, cancel, 'local_repair');
[row.local_repair_validation_probe] = build_validation_probe( ...
    localCandidate, localEvaluation, selection, 'local_repair');
[row.complete_rescheduling_status, row.complete_rescheduling_error] = ...
    summarize_candidate_diagnostics(completeCandidate, ...
    completeEvaluation, ...
    get_selection_candidate_status(selection, 'completeRescheduling'), ...
    state, cancel, 'complete_rescheduling');

row.diagnostic_note = build_diagnostic_note(row);
end

function [status, errorText] = summarize_candidate_diagnostics( ...
    candidate, evaluation, selectionStatus, state, cancel, candidateName)
status = 'unknown';
errorText = 'unknown';
report = struct();

if is_selection_status_feasible(selectionStatus)
    status = 'candidate_generated';
    errorText = '';
    return
end

if ~isstruct(candidate)
    status = 'not_called';
    return
end

if isempty_candidate(candidate)
    status = 'empty_candidate';
    errorText = summarize_rejection_reason(report, state, cancel, ...
        selectionStatus, candidateName);
    if strcmp(errorText, 'unknown')
        errorText = 'empty candidate';
    end
    return
end

if isfield(candidate, 'report') && isstruct(candidate.report)
    report = candidate.report;
end

if is_selection_status_infeasible(selectionStatus)
    [status, errorText] = summarize_selection_rejection( ...
        candidate, selectionStatus, report, evaluation, state, cancel, ...
        candidateName);
    return
end

if isfield(candidate, 'isFeasible') && ~logical(candidate.isFeasible)
    status = 'feasible_flag_false';
    errorText = 'feasible flag false';
    return
end

if is_nonempty_cell_field(report, 'errors') && ...
        isempty_cell_field(report, 'rejectedReasons')
    status = 'rejected_by_validation';
    errorText = 'validation failed';
    return
end

if is_nonempty_cell_field(report, 'rejectedReasons')
    status = 'infeasible_candidate';
    errorText = summarize_rejection_reason(report, state, cancel, ...
        selectionStatus, candidateName);
    if strcmp(errorText, 'canceled order still scheduled')
        residualSummary = summarize_canceled_order_residual(candidate, ...
            cancel);
        if ~isempty(residualSummary)
            errorText = [errorText, ': ', residualSummary];
        end
    end
    return
end

if is_evaluation_infeasible(evaluation)
    status = 'rejected_by_validation';
    errorText = 'validation failed';
    return
end

end

function status = get_selection_candidate_status(selection, fieldName)
status = struct();
if ~isstruct(selection) || ~isfield(selection, 'candidates') || ...
        ~isstruct(selection.candidates) || ...
        ~isfield(selection.candidates, fieldName)
    return
end
status = selection.candidates.(fieldName);
end

function tf = is_selection_status_feasible(selectionStatus)
tf = isstruct(selectionStatus) && isfield(selectionStatus, 'isFeasible') && ...
    logical(selectionStatus.isFeasible);
end

function tf = is_selection_status_infeasible(selectionStatus)
tf = isstruct(selectionStatus) && isfield(selectionStatus, 'isFeasible') && ...
    ~logical(selectionStatus.isFeasible);
end

function tf = isempty_candidate(candidate)
tf = false;
if isfield(candidate, 'machineTable')
    tf = tf || isempty(candidate.machineTable);
end
if isfield(candidate, 'AGVTable')
    tf = tf || isempty(candidate.AGVTable);
end
end

function tf = is_evaluation_infeasible(evaluation)
tf = ~isstruct(evaluation) || ~isfield(evaluation, 'metrics') || ...
    ~isfield(evaluation.metrics, 'isFeasible') || ...
    ~logical(evaluation.metrics.isFeasible);
end

function [status, errorText] = summarize_selection_rejection( ...
    candidate, selectionStatus, report, evaluation, state, cancel, ...
    candidateName)
status = 'unknown';
errorText = 'unknown';

if ~isstruct(selectionStatus)
    return
end

reasons = {};
if isfield(selectionStatus, 'rejectedReasons') && ...
        iscell(selectionStatus.rejectedReasons)
    reasons = selectionStatus.rejectedReasons;
end
joinedReasons = lower(strjoin(reasons, ' | '));

if contains(joinedReasons, 'candidate_infeasible')
    status = 'infeasible_candidate';
    errorText = summarize_validation_failure(candidate, evaluation, ...
        selectionStatus, cancel, candidateName);
    errorText = resolve_raw_validation_error(errorText, selectionStatus, ...
        report, evaluation, candidateName);
elseif contains(joinedReasons, 'evaluation_infeasible') || ...
        contains(joinedReasons, 'invalid_evaluation')
    status = 'rejected_by_validation';
    errorText = summarize_validation_failure(candidate, evaluation, ...
        selectionStatus, cancel, candidateName);
    errorText = resolve_raw_validation_error(errorText, selectionStatus, ...
        report, evaluation, candidateName);
elseif contains(joinedReasons, 'missing_y')
    status = 'rejected_by_validation';
    errorText = 'missing objective';
elseif contains(joinedReasons, 'invalid_candidate')
    status = 'empty_candidate';
    errorText = 'empty candidate';
else
    [status, errorText] = summarize_rejection_reason(report, state, cancel, ...
        selectionStatus, candidateName);
    if strcmp(errorText, 'unknown') && is_evaluation_infeasible(evaluation)
        status = 'rejected_by_validation';
        errorText = summarize_validation_failure(candidate, evaluation, ...
            selectionStatus, cancel, candidateName);
        errorText = resolve_raw_validation_error(errorText, selectionStatus, ...
            report, evaluation, candidateName);
    elseif strcmp(errorText, 'unknown')
        errorText = resolve_raw_validation_error(errorText, selectionStatus, ...
            report, evaluation, candidateName);
    end
end

if strcmp(errorText, 'canceled order still scheduled')
    residualSummary = summarize_canceled_order_residual(candidate, cancel);
    if ~isempty(residualSummary)
        errorText = [errorText, ': ', residualSummary];
    else
        fallbackReason = summarize_validation_failure(candidate, ...
            evaluation, selectionStatus, cancel, candidateName);
        if ~strcmp(fallbackReason, 'unknown validation failure')
            errorText = fallbackReason;
        else
            errorText = 'validation failed without report';
        end
    end
end
end

function errorText = summarize_validation_failure(candidate, evaluation, ...
    selectionStatus, cancel, candidateName)
errorText = 'unknown validation failure';

if isempty_candidate(candidate)
    errorText = 'empty candidate';
    return
end

if ~isstruct(candidate)
    return
end

if ~isfield(candidate, 'machineTable') || ~isfield(candidate, 'AGVTable')
    errorText = 'missing schedule';
    return
end

report = struct();
if isfield(candidate, 'report') && isstruct(candidate.report)
    report = candidate.report;
end

machineReason = classify_check_report(report, 'machineConflictCheck', ...
    'machine overlap', 'missing schedule');
if strcmp(machineReason, 'canceled order still scheduled') && ...
        isempty(summarize_canceled_order_residual(candidate, cancel))
    machineReason = '';
end
if ~isempty(machineReason)
    errorText = machineReason;
    return
end

agvReason = classify_check_report(report, 'agvConflictCheck', ...
    'agv overlap', 'missing schedule');
if strcmp(agvReason, 'canceled order still scheduled') && ...
        isempty(summarize_canceled_order_residual(candidate, cancel))
    agvReason = '';
end
if ~isempty(agvReason)
    errorText = agvReason;
    return
end

sequenceReason = classify_check_report(report, 'jobSequenceCheck', ...
    'precedence violation', 'missing schedule');
if ~isempty(sequenceReason)
    errorText = sequenceReason;
    return
end

if isfield(report, 'errors') && iscell(report.errors) && ~isempty(report.errors)
    errorText = classify_message_list(report.errors, candidateName);
    if strcmp(errorText, 'canceled order still scheduled') && ...
            isempty(summarize_canceled_order_residual(candidate, cancel))
        errorText = 'unknown validation failure';
    end
    if ~strcmp(errorText, 'unknown validation failure')
        return
    end
end

if isfield(report, 'rejectedReasons') && iscell(report.rejectedReasons) && ...
        ~isempty(report.rejectedReasons)
    errorText = classify_message_list(report.rejectedReasons, candidateName);
    if strcmp(errorText, 'canceled order still scheduled') && ...
            isempty(summarize_canceled_order_residual(candidate, cancel))
        errorText = 'unknown validation failure';
    end
    if ~strcmp(errorText, 'unknown validation failure')
        return
    end
end

if isstruct(evaluation) && isfield(evaluation, 'report') && ...
        isstruct(evaluation.report)
    if isfield(evaluation.report, 'errors') && ...
            iscell(evaluation.report.errors) && ...
            ~isempty(evaluation.report.errors)
        errorText = classify_evaluation_messages(evaluation.report.errors);
        if strcmp(errorText, 'candidate not added to feasible pool')
            gateReason = summarize_pool_gate_failure(candidate, evaluation, ...
                selectionStatus, report, candidateName);
            if ~isempty(gateReason)
                errorText = ['candidate not added to feasible pool: ', ...
                    gateReason];
            end
        end
        if strcmp(errorText, 'canceled order still scheduled') && ...
                isempty(summarize_canceled_order_residual(candidate, cancel))
            errorText = 'unknown validation failure';
        end
        return
    end
    if isfield(evaluation.report, 'rejectedReasons') && ...
            iscell(evaluation.report.rejectedReasons) && ...
            ~isempty(evaluation.report.rejectedReasons)
        errorText = classify_evaluation_messages( ...
            evaluation.report.rejectedReasons);
        if strcmp(errorText, 'candidate not added to feasible pool')
            gateReason = summarize_pool_gate_failure(candidate, evaluation, ...
                selectionStatus, report, candidateName);
            if ~isempty(gateReason)
                errorText = ['candidate not added to feasible pool: ', ...
                    gateReason];
            end
        end
        if strcmp(errorText, 'canceled order still scheduled') && ...
                isempty(summarize_canceled_order_residual(candidate, cancel))
            errorText = 'unknown validation failure';
        end
        return
    end
end

if isfield(candidate, 'isFeasible') && ~logical(candidate.isFeasible)
    gateReason = summarize_pool_gate_failure(candidate, evaluation, ...
        selectionStatus, report, candidateName);
    if isempty(gateReason)
        errorText = 'candidate not added to feasible pool';
    else
        errorText = ['candidate not added to feasible pool: ', gateReason];
    end
end

[rawMessage, hasValidationInfo] = extract_first_validation_message( ...
    candidate, evaluation);
if ~isempty(rawMessage)
    errorText = ['raw: ', rawMessage];
    return
end

if ~hasValidationInfo
    errorText = 'validation failed without report';
end
end

function errorText = resolve_raw_validation_error(errorText, selectionStatus, ...
    report, evaluation, candidateName)
if ~strcmp(errorText, 'unknown validation failure')
    return
end

rawReason = extract_first_validation_reason(selectionStatus, report, ...
    evaluation);
if isempty(rawReason)
    errorText = 'validation failed without report';
    return
end

if contains(lower(rawReason), 'metric_evaluation_failed')
    metricReason = summarize_metric_evaluation_failure(evaluation);
    if ~isempty(metricReason)
        errorText = ['metric_evaluation_failed: ', metricReason];
        return
    end
end

mappedReason = classify_message_list({rawReason}, candidateName);
if strcmp(mappedReason, 'unknown validation failure')
    mappedReason = classify_message_list({rawReason}, 'local_repair');
end
if strcmp(mappedReason, 'unknown validation failure')
    mappedReason = classify_evaluation_messages({rawReason});
end

if strcmp(mappedReason, 'unknown validation failure')
    errorText = ['raw: ', rawReason];
else
    errorText = mappedReason;
end
end

function reason = summarize_metric_evaluation_failure(evaluation)
reason = '';

if ~isstruct(evaluation) || ~isfield(evaluation, 'report') || ...
        ~isstruct(evaluation.report)
    return
end

metricOrder = {'Cmax', 'SD', 'TD', 'energy'};
if isfield(evaluation.report, 'metricReports') && ...
        isstruct(evaluation.report.metricReports)
    for i = 1:numel(metricOrder)
        stage = metricOrder{i};
        if ~isfield(evaluation.report.metricReports, stage)
            continue
        end

        stageReason = summarize_metric_stage_failure( ...
            stage, evaluation.report.metricReports.(stage));
        if ~isempty(stageReason)
            reason = stageReason;
            return
        end
    end
end

if isfield(evaluation.report, 'errors') && iscell(evaluation.report.errors) && ...
        ~isempty(evaluation.report.errors)
    reason = summarize_metric_error_text(evaluation.report.errors);
end
end

function reason = summarize_metric_stage_failure(stage, stageReport)
reason = '';
if ~isstruct(stageReport)
    return
end

if isfield(stageReport, 'errors') && iscell(stageReport.errors) && ...
        ~isempty(stageReport.errors)
    reason = summarize_metric_error_text(stageReport.errors);
    if isempty(reason)
        reason = [stage, ': validation report empty'];
    else
        reason = [stage, ': ', reason];
    end
    return
end

if isfield(stageReport, 'isFeasible') && ~logical(stageReport.isFeasible)
    reason = [stage, ': validation report empty'];
end
end

function text = summarize_metric_error_text(messages)
text = '';
firstText = first_meaningful_text(messages);
if isempty(firstText)
    return
end

prefixes = {'Cmax', 'SD', 'TD', 'energy'};
for i = 1:numel(prefixes)
    prefix = [prefixes{i}, ': '];
    if startsWith(firstText, prefix)
        text = strtrim(firstText(numel(prefix) + 1:end));
        return
    end
end

text = firstText;
end

function reason = extract_first_validation_reason(selectionStatus, report, ...
    evaluation)
reason = '';
sources = {};

if isstruct(selectionStatus) && isfield(selectionStatus, 'rejectedReasons')
    sources{end + 1} = selectionStatus.rejectedReasons;
end
if isstruct(report)
    if isfield(report, 'rejectedReasons')
        sources{end + 1} = report.rejectedReasons;
    end
    if isfield(report, 'errors')
        sources{end + 1} = report.errors;
    end
end
if isstruct(evaluation) && isfield(evaluation, 'report') && ...
        isstruct(evaluation.report)
    if isfield(evaluation.report, 'rejectedReasons')
        sources{end + 1} = evaluation.report.rejectedReasons;
    end
    if isfield(evaluation.report, 'errors')
        sources{end + 1} = evaluation.report.errors;
    end
end

for i = 1:numel(sources)
    reason = first_meaningful_text(sources{i});
    if ~isempty(reason)
        return
    end
end
end

function reason = first_meaningful_text(value)
reason = '';
if iscell(value)
    for i = 1:numel(value)
        reason = first_meaningful_text(value{i});
        if ~isempty(reason)
            return
        end
    end
    return
end

if isstruct(value)
    priorityFields = {'reason', 'message', 'type', 'id', 'errors', ...
        'rejectedReasons', 'report'};
    for i = 1:numel(priorityFields)
        fieldName = priorityFields{i};
        if isfield(value, fieldName)
            reason = first_meaningful_text(value.(fieldName));
            if ~isempty(reason)
                return
            end
        end
    end
    return
end

if isstring(value)
    if isscalar(value)
        reason = first_meaningful_text(char(value));
    elseif ~isempty(value)
        reason = first_meaningful_text(char(value(1)));
    end
    return
end

if ischar(value)
    text = shorten_validation_text(value);
    if isempty(text)
        return
    end
    genericReasons = {'invalid_candidate', 'invalid_evaluation', ...
        'candidate_infeasible', 'evaluation_infeasible', 'missing_y', ...
        'unknown validation failure'};
    if any(strcmpi(strtrim(lower(text)), genericReasons))
        return
    end
    reason = text;
    return
end

if isnumeric(value) || islogical(value)
    if isscalar(value) && isfinite(value)
        reason = shorten_validation_text(num2str(value));
    end
end
end

function reason = classify_check_report(report, fieldName, overlapText, ...
    missingText)
reason = '';
if ~isfield(report, fieldName) || ~isstruct(report.(fieldName))
    return
end
checkReport = report.(fieldName);
if isfield(checkReport, 'isFeasible') && logical(checkReport.isFeasible)
    return
end
if isfield(checkReport, 'errors') && iscell(checkReport.errors) && ...
        ~isempty(checkReport.errors)
    reason = classify_message_list(checkReport.errors, fieldName);
    if strcmp(reason, 'unknown validation failure')
        reason = overlapText;
    end
else
    return
end

if strcmp(reason, 'missing schedule')
    return
end

if strcmp(reason, 'unknown validation failure') && ...
        contains(lower(fieldName), 'jobsequence')
    reason = 'precedence violation';
elseif strcmp(reason, 'unknown validation failure')
    reason = overlapText;
end
end

function reason = classify_message_list(messages, candidateName)
joinedMessages = lower(strjoin(messages, ' | '));
if contains(joinedMessages, 'must be a cell array') || ...
        contains(joinedMessages, 'require field') || ...
        contains(joinedMessages, 'required.')
    reason = 'missing schedule';
elseif contains(joinedMessages, 'processing machine operations') || ...
        contains(joinedMessages, 'processing agv tasks') || ...
        contains(joinedMessages, 'already started')
    reason = 'canceled order still scheduled';
elseif contains(joinedMessages, 'contains unfinished tasks from already cancelled jobs') || ...
        contains(joinedMessages, 'backflow')
    reason = 'frozen operation modified';
elseif contains(joinedMessages, 'overlapping operations')
    reason = 'machine overlap';
elseif contains(joinedMessages, 'overlapping transport tasks')
    reason = 'agv overlap';
elseif contains(joinedMessages, 'starts before operation completes') || ...
        contains(joinedMessages, 'not strictly increasing') || ...
        contains(joinedMessages, 'completes before') || ...
        contains(joinedMessages, 'beyond problem.operaNumVec')
    reason = 'precedence violation';
elseif contains(joinedMessages, 'candidate.isfeasible must be true before evaluation')
    reason = 'candidate not added to feasible pool';
elseif contains(joinedMessages, 'missing') && contains(joinedMessages, 'schedule')
    reason = 'missing schedule';
elseif contains(joinedMessages, 'objective') || contains(joinedMessages, 'y_evaluation_failed') || ...
        contains(joinedMessages, 'config.weights') || ...
        contains(joinedMessages, 'config.normalization')
    reason = 'missing objective';
elseif contains(joinedMessages, 'candidate not added') || ...
        contains(joinedMessages, 'feasible pool')
    reason = 'candidate not added to feasible pool';
elseif contains(joinedMessages, 'empty')
    reason = 'validation report empty';
else
    if strcmp(candidateName, 'local_repair')
        reason = 'unknown validation failure';
    else
        reason = 'unknown validation failure';
    end
end
end

function reason = classify_evaluation_messages(messages)
reason = classify_message_list(messages, 'local_repair');
if strcmp(reason, 'unknown validation failure')
    joinedMessages = lower(strjoin(messages, ' | '));
    if contains(joinedMessages, 'candidate.isfeasible must be true before evaluation')
        reason = 'candidate not added to feasible pool';
    elseif contains(joinedMessages, 'contains unfinished tasks from already cancelled jobs') || ...
            contains(joinedMessages, 'backflow')
        reason = 'frozen operation modified';
    elseif contains(joinedMessages, 'processing machine operations') || ...
            contains(joinedMessages, 'processing agv tasks')
        reason = 'canceled order still scheduled';
    elseif contains(joinedMessages, 'validation report empty')
        reason = 'validation report empty';
    elseif contains(joinedMessages, 'missing schedule')
        reason = 'missing schedule';
    elseif contains(joinedMessages, 'objective') || ...
            contains(joinedMessages, 'config.weights') || ...
            contains(joinedMessages, 'config.normalization')
        reason = 'missing objective';
    end
end
if strcmp(reason, 'unknown validation failure')
    joinedMessages = lower(strjoin(messages, ' | '));
    if contains(joinedMessages, 'config.weights') || ...
            contains(joinedMessages, 'config.normalization') || ...
            contains(joinedMessages, 'objective')
        reason = 'missing objective';
    end
end
end

function reason = summarize_pool_gate_failure(candidate, evaluation, ...
    selectionStatus, report, candidateName)
reason = '';

if ~isstruct(candidate)
    reason = 'missing candidate';
    return
end

if ~isfield(candidate, 'machineTable') || ~isfield(candidate, 'AGVTable')
    reason = 'missing candidate schedule';
    return
end

machineReason = summarize_check_gate_failure(report, 'machineConflictCheck', ...
    'machine overlap');
if ~isempty(machineReason)
    reason = machineReason;
    return
end

agvReason = summarize_check_gate_failure(report, 'agvConflictCheck', ...
    'agv overlap');
if ~isempty(agvReason)
    reason = agvReason;
    return
end

sequenceReason = summarize_check_gate_failure(report, 'jobSequenceCheck', ...
    'precedence violation');
if ~isempty(sequenceReason)
    reason = sequenceReason;
    return
end

if ~isstruct(evaluation) || ~isfield(evaluation, 'metrics') || ...
        ~isstruct(evaluation.metrics)
    reason = 'metric evaluation missing';
    return
end

if ~isfield(evaluation.metrics, 'isFeasible') || ...
        ~logical(evaluation.metrics.isFeasible)
    metricReason = summarize_metric_evaluation_failure(evaluation);
    if ~isempty(metricReason)
        reason = ['metric_evaluation_failed: ', metricReason];
    else
        reason = 'metric evaluation missing';
    end
    return
end

if ~isstruct(selectionStatus) || isempty(fieldnames(selectionStatus))
    reason = 'selection status missing';
    return
end

if isfield(report, 'errors') && iscell(report.errors) && ~isempty(report.errors)
    reason = classify_message_list(report.errors, candidateName);
    if ~strcmp(reason, 'unknown validation failure')
        reason = ['validation failed after prune: ', reason];
        return
    end
end

if isfield(report, 'rejectedReasons') && iscell(report.rejectedReasons) && ...
        ~isempty(report.rejectedReasons)
    reason = classify_message_list(report.rejectedReasons, candidateName);
    if ~strcmp(reason, 'unknown validation failure')
        reason = ['validation failed after prune: ', reason];
        return
    end
end

if isfield(candidate, 'report') && isstruct(candidate.report)
    reason = 'isFeasible=false without rejectedReasons';
else
    reason = 'pool add condition false';
end
end

function reason = summarize_check_gate_failure(report, fieldName, fallbackText)
reason = '';
if ~isstruct(report) || ~isfield(report, fieldName) || ...
        ~isstruct(report.(fieldName))
    return
end

checkReport = report.(fieldName);
if isfield(checkReport, 'isFeasible') && logical(checkReport.isFeasible)
    return
end

if isfield(checkReport, 'errors') && iscell(checkReport.errors) && ...
        ~isempty(checkReport.errors)
    reason = classify_message_list(checkReport.errors, fieldName);
    if strcmp(reason, 'unknown validation failure')
        reason = '';
    end
elseif isfield(checkReport, 'rejectedReasons') && ...
        iscell(checkReport.rejectedReasons) && ...
        ~isempty(checkReport.rejectedReasons)
    reason = classify_message_list(checkReport.rejectedReasons, fieldName);
    if strcmp(reason, 'unknown validation failure')
        reason = '';
    end
else
    reason = '';
end

if isempty(reason)
    reason = [fallbackText, ': validation report empty'];
else
    reason = [fallbackText, ': ', reason];
end
end

function [rawMessage, hasValidationInfo] = extract_first_validation_message( ...
    candidate, evaluation)
rawMessage = '';
hasValidationInfo = false;

sources = {};
if isstruct(candidate) && isfield(candidate, 'report') && ...
        isstruct(candidate.report)
    sources{end + 1} = candidate.report;
end
if isstruct(evaluation) && isfield(evaluation, 'report') && ...
        isstruct(evaluation.report)
    sources{end + 1} = evaluation.report;
end

for i = 1:numel(sources)
    [rawMessage, sourceHasInfo] = extract_first_text_from_value(sources{i});
    hasValidationInfo = hasValidationInfo || sourceHasInfo;
    if ~isempty(rawMessage)
        return
    end
end
end

function [text, hasInfo] = extract_first_text_from_value(value)
text = '';
hasInfo = false;

if ischar(value)
    text = shorten_validation_text(value);
    hasInfo = ~isempty(strtrim(text));
    return
end

if isstring(value)
    if isscalar(value)
        text = shorten_validation_text(char(value));
        hasInfo = ~isempty(strtrim(text));
    elseif ~isempty(value)
        [text, hasInfo] = extract_first_text_from_value(value(1));
    end
    return
end

if iscell(value)
    for i = 1:numel(value)
        [text, hasInfo] = extract_first_text_from_value(value{i});
        if ~isempty(text) || hasInfo
            return
        end
    end
    return
end

if isstruct(value)
    fieldPriority = {'message', 'reason', 'type', 'id', 'error', ...
        'errors', 'rejectedReason', 'rejectedReasons', 'report'};
    for i = 1:numel(fieldPriority)
        fieldName = fieldPriority{i};
        if isfield(value, fieldName)
            [text, hasInfo] = extract_first_text_from_value(value.(fieldName));
            if ~isempty(text) || hasInfo
                return
            end
        end
    end

    fieldNames = fieldnames(value);
    for i = 1:numel(fieldNames)
        fieldName = fieldNames{i};
        if any(strcmp(fieldName, fieldPriority))
            continue
        end
        [text, hasInfo] = extract_first_text_from_value(value.(fieldName));
        if ~isempty(text) || hasInfo
            return
        end
    end
    return
end

if isnumeric(value) || islogical(value)
    if isscalar(value) && isfinite(value)
        text = shorten_validation_text(num2str(value));
        hasInfo = true;
    end
end
end

function text = shorten_validation_text(text)
text = strtrim(regexprep(char(string(text)), '[\r\n]+', ' '));
if numel(text) > 120
    text = [text(1:117), '...'];
end
end

function probe = build_validation_probe(candidate, evaluation, selection, ...
    candidateName)
probe = '';
parts = {};
selectionFieldName = candidate_selection_field_name(candidateName);

parts{end + 1} = ['selection_fields=', summarize_field_names(selection)];

if isstruct(selection) && isfield(selection, 'candidates') && ...
        isstruct(selection.candidates)
    parts{end + 1} = ['candidates_fields=', ...
        summarize_field_names(selection.candidates)];
    if isfield(selection.candidates, selectionFieldName)
        status = selection.candidates.(selectionFieldName);
        parts{end + 1} = ['status_fields=', summarize_field_names(status)];
        parts{end + 1} = ['reason_fields=', summarize_value_fields(status, ...
            {'reason', 'message', 'type', 'id', 'status', ...
            'rejectedReasons', 'errors'})];
    else
        parts{end + 1} = ['no ', selectionFieldName, ...
            ' candidate in selection'];
    end
else
    parts{end + 1} = 'no selection candidates';
end

if isstruct(candidate)
    parts{end + 1} = ['candidate_fields=', summarize_field_names(candidate)];
    if isfield(candidate, 'report') && isstruct(candidate.report)
        parts{end + 1} = ['report_fields=', summarize_field_names(candidate.report)];
        parts{end + 1} = ['report_check_statuses=', ...
            summarize_report_check_statuses(candidate.report)];
    else
        parts{end + 1} = 'no candidate report';
    end
else
    parts{end + 1} = 'no candidate';
end

if isstruct(evaluation)
    parts{end + 1} = ['evaluation_fields=', summarize_field_names(evaluation)];
    if isfield(evaluation, 'report') && isstruct(evaluation.report)
        parts{end + 1} = ['evaluation_report_fields=', ...
            summarize_field_names(evaluation.report)];
    else
        parts{end + 1} = 'no evaluation report';
    end
else
    parts{end + 1} = 'no evaluation';
end

probe = truncate_probe_text(strjoin(parts, '; '));
end

function text = summarize_field_names(s)
if ~isstruct(s)
    text = 'n/a';
    return
end
text = join_preview_names(fieldnames(s), 5);
end

function text = summarize_report_check_statuses(report)
text = 'n/a';
if ~isstruct(report)
    return
end

parts = {};
parts{end + 1} = ['machine=', summarize_single_check_status(report, ...
    'machineConflictCheck')];
parts{end + 1} = ['agv=', summarize_single_check_status(report, ...
    'agvConflictCheck')];
parts{end + 1} = ['job=', summarize_single_check_status(report, ...
    'jobSequenceCheck')];
text = strjoin(parts, '|');
end

function text = summarize_single_check_status(report, fieldName)
text = 'missing';
if ~isfield(report, fieldName) || ~isstruct(report.(fieldName))
    return
end

checkReport = report.(fieldName);
if isfield(checkReport, 'isFeasible') && ~isempty(checkReport.isFeasible)
    if logical(checkReport.isFeasible)
        text = 'true';
    else
        text = 'false';
    end
end

errorCount = 0;
if isfield(checkReport, 'errors') && iscell(checkReport.errors)
    errorCount = numel(checkReport.errors);
end
text = [text, '/', num2str(errorCount)];
end

function text = summarize_value_fields(s, fieldNames)
text = 'n/a';
if ~isstruct(s)
    return
end

parts = {};
for i = 1:numel(fieldNames)
    fieldName = fieldNames{i};
    if ~isfield(s, fieldName)
        continue
    end
    valueText = summarize_short_value(s.(fieldName));
    if ~isempty(valueText)
        parts{end + 1} = [fieldName, '=', valueText];
    end
end

if ~isempty(parts)
    text = strjoin(parts, ',');
end
end

function text = summarize_short_value(value)
text = '';
if ischar(value)
    text = shorten_validation_text(value);
elseif isstring(value)
    if isscalar(value)
        text = shorten_validation_text(char(value));
    elseif ~isempty(value)
        text = shorten_validation_text(char(value(1)));
    end
elseif isnumeric(value) || islogical(value)
    if isscalar(value) && isfinite(value)
        text = shorten_validation_text(num2str(value));
    end
elseif iscell(value) && ~isempty(value)
    text = summarize_short_value(value{1});
elseif isstruct(value)
    text = summarize_field_names(value);
end
end

function text = join_preview_names(names, maxCount)
if isempty(names)
    text = 'none';
    return
end

count = min(numel(names), maxCount);
text = strjoin(names(1:count), '|');
if numel(names) > maxCount
    text = [text, '|...'];
end
end

function text = truncate_probe_text(text)
text = strtrim(regexprep(char(string(text)), '[\r\n]+', ' '));
if numel(text) > 200
    text = [text(1:197), '...'];
end
end

function fieldName = candidate_selection_field_name(candidateName)
if strcmp(candidateName, 'local_repair')
    fieldName = 'localRepair';
elseif strcmp(candidateName, 'complete_rescheduling')
    fieldName = 'completeRescheduling';
else
    fieldName = candidateName;
end
end

function errorText = summarize_rejection_reason(report, state, cancel, ...
    selectionStatus, candidateName)
errorText = 'unknown';
reasons = {};
if isfield(report, 'rejectedReasons') && iscell(report.rejectedReasons)
    reasons = report.rejectedReasons;
end
joinedReasons = lower(strjoin(reasons, ' | '));

if contains(joinedReasons, 'processing') || ...
        contains(joinedReasons, 'unsupported')
    errorText = 'canceled order already started';
elseif contains(joinedReasons, 'finished')
    errorText = 'canceled order already finished';
elseif contains(joinedReasons, 'remaining_operation_set_infeasible') || ...
        contains(joinedReasons, 'no remaining') || ...
        (strcmp(candidateName, 'complete_rescheduling') && ...
        count_records(get_state_records(state, ...
        'remaining_unfinished_operations')) == 0)
    errorText = 'no remaining operations';
elseif is_selection_status_feasible(selectionStatus)
    errorText = '';
elseif contains(joinedReasons, 'invalid') || contains(joinedReasons, 'mismatch') || ...
        contains(joinedReasons, 'infeasible') || contains(joinedReasons, 'decode')
    errorText = 'validation failed';
elseif summarize_cancel_state_label(state, cancel) == "processing_at_cancel_time"
    errorText = 'canceled order already started';
elseif summarize_cancel_state_label(state, cancel) == "all_finished"
    errorText = 'canceled order already finished';
end
end

function [stateLabel, startedCount, finishedCount, unstartedCount, ...
    frozenCount, remainingCount] = summarize_cancellation_state(state, cancel)
stateLabel = 'unknown';
startedCount = 0;
finishedCount = 0;
unstartedCount = 0;
frozenCount = 0;
remainingCount = 0;

if ~isstruct(state) || ~isstruct(cancel) || ~isfield(cancel, 'job_id') || ...
        ~isfinite(cancel.job_id)
    return
end

finishedRecords = filter_records_by_job( ...
    get_state_records(state, 'completed_operations'), cancel.job_id);
processingRecords = filter_records_by_job( ...
    get_state_records(state, 'processing_operations'), cancel.job_id);
unstartedRecords = filter_records_by_job( ...
    get_state_records(state, 'unstarted_operations'), cancel.job_id);
cancelledRecords = filter_records_by_job( ...
    get_state_records(state, 'cancelled_unfinished_operations'), ...
    cancel.job_id);

finishedCount = count_records(finishedRecords);
startedCount = finishedCount + count_records(processingRecords);
unstartedCount = count_records(unstartedRecords);
if unstartedCount == 0
    unstartedCount = count_records(filter_records_by_job( ...
        cancelledRecords, cancel.job_id));
end
frozenCount = count_records(get_state_records(state, 'completed_operations'));
remainingCount = count_records(get_state_records(state, ...
    'remaining_unfinished_operations'));

if startedCount == 0 && unstartedCount == 0 && count_records(cancelledRecords) == 0 && ...
        finishedCount == 0
    stateLabel = 'not_found';
elseif count_records(processingRecords) > 0
    stateLabel = 'processing_at_cancel_time';
elseif finishedCount == 0 && unstartedCount > 0
    stateLabel = 'all_unstarted';
elseif finishedCount > 0 && unstartedCount == 0
    stateLabel = 'all_finished';
elseif finishedCount > 0 && unstartedCount > 0
    stateLabel = 'partially_started';
else
    stateLabel = 'unknown';
end
end

function records = get_state_records(state, fieldName)
records = [];
if ~isstruct(state) || ~isfield(state, fieldName)
    return
end
records = state.(fieldName);
end

function records = filter_records_by_job(records, jobId)
if isempty(records) || ~isfinite(jobId)
    return
end

if istable(records)
    if ~ismember('job_id', records.Properties.VariableNames)
        records = records([],:);
        return
    end
    records = records(records.job_id == jobId, :);
elseif iscell(records)
    kept = {};
    for i = 1:numel(records)
        item = records{i};
        if isstruct(item) && isfield(item, 'job_id') && item.job_id == jobId
            kept{end + 1} = item; %#ok<AGROW>
        end
    end
    if isempty(kept)
        records = {};
    else
        records = kept;
    end
elseif isstruct(records)
    if ~isfield(records, 'job_id')
        records = records([]); %#ok<NASGU>
        return
    end
    records = records([records.job_id] == jobId);
else
    records = [];
end
end

function count = count_records(records)
if isempty(records)
    count = 0;
elseif istable(records)
    count = height(records);
elseif iscell(records)
    count = numel(records);
elseif isstruct(records)
    count = numel(records);
else
    count = 0;
end
end

function tf = is_nonempty_cell_field(s, fieldName)
tf = false;
if ~isstruct(s) || ~isfield(s, fieldName)
    return
end
value = s.(fieldName);
tf = iscell(value) && ~isempty(value);
end

function tf = isempty_cell_field(s, fieldName)
tf = ~is_nonempty_cell_field(s, fieldName);
end

function label = summarize_cancel_state_label(state, cancel)
[label, ~, ~, ~, ~, ~] = summarize_cancellation_state(state, cancel);
label = string(label);
end

function note = build_diagnostic_note(row)
parts = {
    ['local=', row.local_repair_status, '/', row.local_repair_error]
    ['complete=', row.complete_rescheduling_status, '/', ...
        row.complete_rescheduling_error]
    ['state=', row.canceled_order_state_at_cancel_time]
};
note = strjoin(parts, '; ');
end

function summary = summarize_canceled_order_residual(candidate, cancel)
summary = '';
if ~isstruct(candidate) || ~isstruct(cancel) || ~isfield(cancel, 'job_id')
    return
end

[machineCount, machinePreview] = summarize_job_residual_in_table( ...
    candidate, 'machineTable', cancel.job_id, 'machine');
[agvCount, agvPreview] = summarize_job_residual_in_table( ...
    candidate, 'AGVTable', cancel.job_id, 'agv');

if machineCount == 0 && agvCount == 0
    return
end

parts = {};
parts{end + 1} = ['machine_count=', num2str(machineCount)];
parts{end + 1} = ['agv_count=', num2str(agvCount)];
if ~isempty(machinePreview)
    parts{end + 1} = ['machine_first=', machinePreview];
end
if ~isempty(agvPreview)
    parts{end + 1} = ['agv_first=', agvPreview];
end
summary = strjoin(parts, ', ');
end

function [count, preview] = summarize_job_residual_in_table( ...
    candidate, fieldName, jobId, resourceLabel)
count = 0;
preview = '';
if ~isfield(candidate, fieldName) || ~iscell(candidate.(fieldName))
    return
end

tableValue = candidate.(fieldName);
for outerIdx = 1:numel(tableValue)
    rows = tableValue{outerIdx};
    if isempty(rows) || ~isstruct(rows)
        continue
    end
    for rowIdx = 1:numel(rows)
        row = rows(rowIdx);
        if ~isfield(row, 'job') || row.job ~= jobId
            continue
        end
        count = count + 1;
        if isempty(preview)
            preview = summarize_residual_row(row, resourceLabel, outerIdx, ...
                rowIdx);
        end
    end
end
end

function text = summarize_residual_row(row, resourceLabel, outerIdx, rowIdx)
parts = {
    [resourceLabel, '=', num2str(outerIdx)]
    ['idx=', num2str(rowIdx)]
};
if isfield(row, 'opera') && ~isempty(row.opera)
    parts{end + 1} = ['op=', num2str(row.opera)];
end
if isfield(row, 'job') && ~isempty(row.job)
    parts{end + 1} = ['job=', num2str(row.job)];
end
if isfield(row, 'status') && ~isempty(row.status)
    parts{end + 1} = ['status=', short_text(row.status)];
end
if isfield(row, 'load_status') && ~isempty(row.load_status)
    parts{end + 1} = ['load_status=', short_text(row.load_status)];
end
if isfield(row, 'from_machine') && ~isempty(row.from_machine)
    parts{end + 1} = ['from=', num2str(row.from_machine)];
end
if isfield(row, 'to_machine') && ~isempty(row.to_machine)
    parts{end + 1} = ['to=', num2str(row.to_machine)];
end
text = strjoin(parts, ' ');
end

function text = short_text(value)
text = char(string(value));
text = strtrim(regexprep(text, '[\r\n]+', ' '));
if numel(text) > 40
    text = [text(1:37), '...'];
end
end

function text = format_exception(err)
text = '';
if (isobject(err) && isprop(err, 'identifier') && ...
        ~isempty(err.identifier)) || ...
        (isstruct(err) && isfield(err, 'identifier') && ...
        ~isempty(err.identifier))
    text = [char(string(err.identifier)), ': ', char(string(err.message))];
elseif (isobject(err) && isprop(err, 'message')) || ...
        (isstruct(err) && isfield(err, 'message'))
    text = char(string(err.message));
else
    text = 'unknown';
end
end

function value = read_numeric_field(obj, fieldNames, defaultValue)
value = defaultValue;
names = normalize_field_names(fieldNames);
for i = 1:numel(names)
    fieldName = names{i};
    rawValue = [];
    found = false;

    if isstruct(obj) && isfield(obj, fieldName)
        rawValue = obj.(fieldName);
        found = true;
    elseif istable(obj) && ismember(fieldName, obj.Properties.VariableNames)
        rawValue = obj.(fieldName);
        found = true;
    end

    if ~found
        continue
    end

    candidate = coerce_numeric_value(rawValue);
    if ~isempty(candidate)
        value = candidate;
        return
    end
end
end

function names = normalize_field_names(fieldNames)
if ischar(fieldNames) || isstring(fieldNames)
    names = {char(string(fieldNames))};
elseif iscell(fieldNames)
    names = cell(1, numel(fieldNames));
    for i = 1:numel(fieldNames)
        names{i} = char(string(fieldNames{i}));
    end
else
    names = {};
end
end

function value = coerce_numeric_value(rawValue)
value = [];

if isempty(rawValue)
    return
end

if iscell(rawValue)
    if isempty(rawValue)
        return
    end
    rawValue = rawValue{1};
    if isempty(rawValue)
        return
    end
end

if isnumeric(rawValue) || islogical(rawValue)
    candidate = rawValue(1);
elseif isstring(rawValue) || ischar(rawValue)
    candidate = str2double(string(rawValue));
else
    return
end

if isempty(candidate) || ~isscalar(candidate) || ~isfinite(candidate)
    return
end

value = candidate;
end

function machineData = build_sample_machine_data(machineNum)
machineData = struct();
machineData.distance_matrix = struct();
machineData.distance_matrix.machine_to_machine = zeros(machineNum, machineNum);
for i = 1:machineNum
    for j = 1:machineNum
        machineData.distance_matrix.machine_to_machine(i, j) = abs(i - j);
    end
end
machineData.distance_matrix.load_to_machine = 1:machineNum;
machineData.distance_matrix.machine_to_unload = machineNum:-1:1;
machineData.distance_matrix.load_to_unload = 1;
machineData.machineEnergy = struct();
machineData.machineEnergy.work = ones(1, machineNum) * 2;
machineData.machineEnergy.free = ones(1, machineNum);
end

function agvData = build_sample_agv_data()
agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5, 2.0];
agvData.AGVEnergy.free = [1.0, 1.2, 1.4];
agvData.AGVEnergy.load = [1.4, 1.6, 1.8];
end

function schedule = build_sample_schedule(machineNum)
schedule = struct();
schedule.machineTable = build_sample_machine_table(machineNum);
schedule.AGVTable = build_sample_agv_table();
end

function machineTable = build_sample_machine_table(machineNum)
machineTable = cell(1, machineNum);

for machineIdx = 1:machineNum
    machineTable{machineIdx} = make_machine_block(0, inf, 0, 0);
end

machineTable{1} = [
    make_machine_block(0, 4, 1, 1)
    make_machine_block(10, 14, 1, 2)
    make_machine_block(14, inf, 0, 0)
];

machineTable{2} = [
    make_machine_block(0, 3, 3, 1)
    make_machine_block(3, 8, 2, 1)
    make_machine_block(12, 15, 2, 2)
    make_machine_block(15, inf, 0, 0)
];

if machineNum >= 3
    machineTable{3} = [
        make_machine_block(14, 18, 3, 2)
        make_machine_block(18, inf, 0, 0)
    ];
end
end

function AGVTable = build_sample_agv_table()
AGVTable = cell(1, 2);

AGVTable{1} = [
    make_agv_block(0, 4, 1, 1, -1, 1, -2)
    make_agv_block(10, 12, 1, 2, 1, 1, -2)
    make_agv_block(12, 16, 2, 2, 2, -2, -2)
    make_agv_block(16, inf, 0, 0, -2, -2, 0)
];

AGVTable{2} = [
    make_agv_block(0, 3, 3, 1, -1, 2, -2)
    make_agv_block(4, 8, 2, 1, -1, 2, -2)
    make_agv_block(10, 13, 3, 2, 2, -2, -2)
    make_agv_block(13, inf, 0, 0, -2, -2, 0)
];
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end

function block = make_agv_block(startTime, endTime, jobId, operationId, ...
    fromMachine, toMachine, loadStatus)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.from_machine = fromMachine;
block.to_machine = toMachine;
block.status = [];
block.load_status = loadStatus;
block.charge = 0;
end
