function baselineState = build_static_baseline_schedule(problem, machineData, agvData, config)
%BUILD_STATIC_BASELINE_SCHEDULE Build a static baseline by running independent NSGA-II.

if nargin < 4
    error('build_static_baseline_schedule:MissingInput', ...
        'problem, machineData, agvData, and config are required.');
end

if isfield(config, 'random') && isfield(config.random, 'seed')
    rng(config.random.seed);
end

runOptions = struct();
runOptions.label = 'static_solver';
runOptions.seed = config.random.seed;

[NSGA2_Result, ~, runInfo] = run_independent_nsga2( ...
    config, problem, machineData, agvData, runOptions);

[selection, selectedIndex] = select_static_baseline_solution( ...
    NSGA2_Result.obj_matrix);

selectedChrom = NSGA2_Result.chrom(selectedIndex, :);
selectedObjectives = NSGA2_Result.obj_matrix(selectedIndex, :);

[schedule, decodeReport, evalResult] = resolve_selected_solution( ...
    NSGA2_Result, selectedIndex, selectedChrom, problem, machineData, ...
    agvData, config);

runInfo.baselineMode = 'static_solver';
runInfo.baselineSeed = config.random.seed;
runInfo.baselinePop = config.algorithm.pop;
runInfo.baselineMaxGen = config.algorithm.max_gen;
runInfo.selectionMethod = selection.method;
runInfo.selectedIndex = selection.selectedIndex;

baselineState = struct();
baselineState.schedule = schedule;
baselineState.baselineSchedule = schedule;
baselineState.chrom = selectedChrom;
baselineState.objectives = selectedObjectives;
baselineState.decodeReport = decodeReport;
baselineState.evalResult = evalResult;
baselineState.selection = selection;
baselineState.nsga2Result = NSGA2_Result;
baselineState.runInfo = runInfo;
baselineState.source = 'independent_nsga2';
end

function [selection, selectedIndex] = select_static_baseline_solution(objMatrix)
if isempty(objMatrix)
    error('build_static_baseline_schedule:EmptyObjectiveMatrix', ...
        'NSGA2_Result.obj_matrix is empty.');
end
if size(objMatrix, 2) < 2
    error('build_static_baseline_schedule:InvalidObjectiveMatrix', ...
        'NSGA2_Result.obj_matrix must contain makespan and total energy.');
end

makespan = objMatrix(:, 1);
totalEnergy = objMatrix(:, 2);
normMakespan = normalize_min_max(makespan);
normEnergy = normalize_min_max(totalEnergy);
score = normMakespan + normEnergy;
rankTable = [score, makespan, totalEnergy, (1:size(objMatrix, 1))'];
[~, order] = sortrows(rankTable, [1, 2, 3, 4]);
selectedIndex = order(1);

selection = struct();
selection.method = 'min_normalized_sum';
selection.selectedIndex = selectedIndex;
selection.candidateCount = size(objMatrix, 1);
selection.makespan = makespan;
selection.totalEnergy = totalEnergy;
selection.normalizedMakespan = normMakespan;
selection.normalizedEnergy = normEnergy;
selection.score = score;
selection.tieBreak = 'makespan -> totalEnergy -> index';
selection.order = order;
end

function [schedule, decodeReport, evalResult] = resolve_selected_solution( ...
    NSGA2_Result, selectedIndex, selectedChrom, problem, machineData, ...
    agvData, config)
if isfield(NSGA2_Result, 'details') && numel(NSGA2_Result.details) >= selectedIndex && ...
        ~isempty(NSGA2_Result.details{selectedIndex})
    detail = NSGA2_Result.details{selectedIndex};
    if isfield(detail, 'decodedResult')
        schedule = detail.decodedResult;
    else
        schedule = [];
    end
    if isfield(detail, 'decodeReport')
        decodeReport = detail.decodeReport;
    else
        decodeReport = struct();
    end
    if isfield(detail, 'evalResult')
        evalResult = detail.evalResult;
    else
        evalResult = [];
    end
else
    evalConfig = build_static_evaluation_config(config, problem, ...
        machineData, agvData);
    [schedule, decodeReport] = decode_chromosome_independent( ...
        selectedChrom, problem, machineData, agvData, evalConfig);
    evalResult = evaluate_decoded_schedule( ...
        schedule, problem, machineData, agvData, evalConfig);
end

if isempty(schedule)
    evalConfig = build_static_evaluation_config(config, problem, ...
        machineData, agvData);
    [schedule, decodeReport] = decode_chromosome_independent( ...
        selectedChrom, problem, machineData, agvData, evalConfig);
    evalResult = evaluate_decoded_schedule( ...
        schedule, problem, machineData, agvData, evalConfig);
end

if isempty(evalResult)
    evalConfig = build_static_evaluation_config(config, problem, ...
        machineData, agvData);
    evalResult = evaluate_decoded_schedule( ...
        schedule, problem, machineData, agvData, evalConfig);
end
end

function evalConfig = build_static_evaluation_config(config, problem, ...
    machineData, agvData)
evalConfig = struct();
evalConfig.AGVEG_MAX = config.energy.AGVEG_MAX;
evalConfig.eChargeSpeed = config.energy.eChargeSpeed;
evalConfig.AGVEG_MIN = compute_agv_energy_min( ...
    machineData.distance_matrix, agvData, agvData.AGVEnergy);
evalConfig.machineTable = create_initial_machine_table(problem.machineNum);
evalConfig.AGVTable = create_initial_agv_table(agvData.AGVNum);
end

function AGVEG_MIN = compute_agv_energy_min(distanceMatrix, agvData, AGVEnergy)
distanceMax = max([max(distanceMatrix.machine_to_machine(:)), ...
    max(distanceMatrix.load_to_machine), ...
    max(distanceMatrix.machine_to_unload), ...
    distanceMatrix.load_to_unload]);
AGVEG_MIN = distanceMax / agvData.AGVSpeed(end) * ...
    (AGVEnergy.free(end) + AGVEnergy.load(end)) + 1e-6;
end

function machineTable = create_initial_machine_table(machineNum)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = struct('start', 0, 'end', inf, ...
        'job', 0, 'opera', 0);
end
end

function AGVTable = create_initial_agv_table(AGVNum)
AGVTable = cell(1, AGVNum);
for agvIdx = 1:AGVNum
    AGVTable{agvIdx} = repmat(struct('start', 0, 'end', 0, ...
        'job', 0, 'opera', 0, 'from_machine', -1, ...
        'to_machine', -1, 'status', 0), 1, 2);
    AGVTable{agvIdx}(2).end = inf;
end
end

function normalized = normalize_min_max(values)
minValue = min(values);
maxValue = max(values);
span = maxValue - minValue;
if span <= 0
    normalized = zeros(size(values));
else
    normalized = (values - minValue) ./ span;
end
end
