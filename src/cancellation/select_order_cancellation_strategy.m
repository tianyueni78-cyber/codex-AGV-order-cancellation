function selection = select_order_cancellation_strategy( ...
    localRepairEvaluation, completeReschedulingEvaluation)
%SELECT_ORDER_CANCELLATION_STRATEGY Select the smaller-Y candidate.
%   This function compares two already-evaluated candidates. It does not
%   calculate metrics, rebuild schedules, or write outputs.

if nargin < 2
    error('select_order_cancellation_strategy:MissingInput', ...
        'localRepairEvaluation and completeReschedulingEvaluation are required.');
end

selection = empty_selection();

localStatus = candidate_status(localRepairEvaluation, 'local_repair');
completeStatus = candidate_status( ...
    completeReschedulingEvaluation, 'complete_rescheduling');

selection.comparedStrategies = {localStatus.name, completeStatus.name};
selection.candidates.localRepair = localStatus;
selection.candidates.completeRescheduling = completeStatus;

if localStatus.isFeasible && completeStatus.isFeasible
    selection = select_between_two_feasible( ...
        selection, localStatus, completeStatus);
elseif localStatus.isFeasible
    selection = select_one(selection, localStatus, ...
        'only_feasible_candidate');
elseif completeStatus.isFeasible
    selection = select_one(selection, completeStatus, ...
        'only_feasible_candidate');
else
    selection.isSelected = false;
    selection.reason = 'no_feasible_candidate';
    selection.report.errors{end + 1} = ...
        'Both candidate evaluations are infeasible.';
end

selection.report.isFeasible = selection.isSelected;
end

function selection = select_between_two_feasible( ...
    selection, localStatus, completeStatus)
if localStatus.Y < completeStatus.Y
    selection = select_one(selection, localStatus, 'smaller_Y');
elseif completeStatus.Y < localStatus.Y
    selection = select_one(selection, completeStatus, 'smaller_Y');
else
    selection = select_one(selection, localStatus, ...
        'tie_break_local_repair');
end
end

function selection = select_one(selection, status, reason)
selection.name = status.name;
selection.reason = reason;
selection.selectedY = status.Y;
selection.isSelected = true;
end

function status = candidate_status(evaluation, defaultName)
status = struct();
status.name = defaultName;
status.Y = [];
status.isFeasible = false;
status.rejectedReasons = {};

if ~isstruct(evaluation)
    status.rejectedReasons{end + 1} = 'invalid_evaluation';
    return
end

if isfield(evaluation, 'strategyName') && ~isempty(evaluation.strategyName)
    status.name = evaluation.strategyName;
end

if ~isfield(evaluation, 'metrics') || ...
        ~isfield(evaluation.metrics, 'isFeasible') || ...
        ~evaluation.metrics.isFeasible
    status.rejectedReasons{end + 1} = 'evaluation_infeasible';
    status.rejectedReasons = append_report_reasons( ...
        status.rejectedReasons, evaluation);
    return
end

if ~isfield(evaluation.metrics, 'Y') || ...
        ~isnumeric(evaluation.metrics.Y) || ...
        ~isscalar(evaluation.metrics.Y)
    status.rejectedReasons{end + 1} = 'missing_Y';
    return
end

status.Y = evaluation.metrics.Y;
status.isFeasible = true;
end

function reasons = append_report_reasons(reasons, evaluation)
if isfield(evaluation, 'report') && ...
        isfield(evaluation.report, 'rejectedReasons')
    for i = 1:numel(evaluation.report.rejectedReasons)
        reasons{end + 1} = evaluation.report.rejectedReasons{i};
    end
end
end

function selection = empty_selection()
selection = struct();
selection.name = '';
selection.reason = '';
selection.selectedY = [];
selection.comparedStrategies = {};
selection.isSelected = false;
selection.candidates = struct();
selection.report = struct();
selection.report.errors = {};
selection.report.warnings = {};
selection.report.isFeasible = false;
end
