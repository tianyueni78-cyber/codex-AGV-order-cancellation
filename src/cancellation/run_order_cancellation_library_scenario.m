function result = run_order_cancellation_library_scenario( ...
    problem, machineData, agvData, baselineSchedule, scenario, config)
%RUN_ORDER_CANCELLATION_LIBRARY_SCENARIO Run one stage-G library scenario.
%   result = RUN_ORDER_CANCELLATION_LIBRARY_SCENARIO(problem, machineData,
%   agvData, baselineSchedule, scenario, config) adapts a stage-G scenario
%   library row to the existing stage B-E single-scenario pipeline. This
%   function does not write outputs or run a formal NSGA-II search.

if nargin < 5
    error('run_order_cancellation_library_scenario:MissingInput', ...
        ['problem, machineData, agvData, baselineSchedule, and ', ...
        'scenario are required.']);
end
if nargin < 6 || isempty(config)
    config = struct();
end

require_library_scenario(scenario);

flatScenario = make_flat_scenario(scenario);
baseResult = run_order_cancellation_scenario( ...
    problem, machineData, agvData, baselineSchedule, ...
    flatScenario, scenario.seed, config);

result = add_library_fields(baseResult, scenario);
end

function require_library_scenario(scenario)
if ~isstruct(scenario)
    error('run_order_cancellation_library_scenario:InvalidScenario', ...
        'scenario must be a struct.');
end

requiredFields = {'scenario_id', 'dataset', 'seed', 'time_window', ...
    'job_category', 'cancel', 'cancel_time_ratio'};
for i = 1:numel(requiredFields)
    if ~isfield(scenario, requiredFields{i})
        error('run_order_cancellation_library_scenario:InvalidScenario', ...
            'scenario.%s is required.', requiredFields{i});
    end
end

if ~isstruct(scenario.cancel)
    error('run_order_cancellation_library_scenario:InvalidScenario', ...
        'scenario.cancel must be a struct.');
end

requiredCancelFields = {'job_id', 'cancel_time', 'policy'};
for i = 1:numel(requiredCancelFields)
    if ~isfield(scenario.cancel, requiredCancelFields{i})
        error('run_order_cancellation_library_scenario:InvalidScenario', ...
            'scenario.cancel.%s is required.', requiredCancelFields{i});
    end
end

if isempty(scenario.scenario_id)
    error('run_order_cancellation_library_scenario:InvalidScenario', ...
        'scenario.scenario_id must not be empty.');
end
if ~isnumeric(scenario.seed) || ~isscalar(scenario.seed) || ...
        ~isfinite(scenario.seed)
    error('run_order_cancellation_library_scenario:InvalidScenario', ...
        'scenario.seed must be a finite scalar.');
end
end

function flatScenario = make_flat_scenario(scenario)
flatScenario = struct();
flatScenario.name = scenario.scenario_id;
flatScenario.cancel_job_id = scenario.cancel.job_id;
flatScenario.cancel_time = scenario.cancel.cancel_time;
flatScenario.cancel_policy = scenario.cancel.policy;
flatScenario.cancel_time_ratio = scenario.cancel_time_ratio;
flatScenario.dataset = scenario.dataset;
flatScenario.time_window = scenario.time_window;
flatScenario.job_category = scenario.job_category;
end

function result = add_library_fields(baseResult, scenario)
result = baseResult;
result.scenario_id = scenario.scenario_id;
result.dataset = scenario.dataset;
result.time_window = scenario.time_window;
result.job_category = scenario.job_category;
result.cancel_time_ratio = scenario.cancel_time_ratio;
result.library_seed = scenario.seed;

if isfield(scenario, 'notes')
    result.scenario_notes = scenario.notes;
else
    result.scenario_notes = {};
end
end
