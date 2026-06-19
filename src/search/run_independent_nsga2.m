function [NSGA2_Result, initialPopulation, runInfo] = run_independent_nsga2(config, problem, machineData, agvData, options)
%RUN_INDEPENDENT_NSGA2 Run NSGA-II without raw search/evaluation/decoding.

if nargin < 4
    error('run_independent_nsga2:MissingInput', ...
        'config, problem, machineData, and agvData are required.');
end
if nargin < 5
    options = struct();
end

tStart = tic;
pCross = config.algorithm.p_cross;
pMutation = config.algorithm.p_mutation;
pop = config.algorithm.pop;
maxGen = config.algorithm.max_gen;
objNum = 2;

evalConfig = build_evaluation_config(config, problem, machineData, agvData);

[initialPopulation, encodingReport] = generate_initial_population(pop, problem, agvData);
if ~encodingReport.isValid
    error('run_independent_nsga2:InvalidInitialPopulation', ...
        'generate_initial_population returned an invalid population.');
end

[population, populationDetails] = evaluate_core_population( ...
    initialPopulation, problem, machineData, agvData, evalConfig);
population = assign_rank_and_crowding(population, objNum);

popHistory = cell(1, maxGen);
curveMin = zeros(objNum, maxGen);
curveAvg = zeros(objNum, maxGen);

for gen = 1:maxGen
    parentIndexes = tournament_selection_independent(population, pop);
    parents = population(parentIndexes, 1:size(initialPopulation, 2));

    variationOptions = struct();
    variationOptions.pCross = pCross;
    variationOptions.pMutation = pMutation;
    [offspringCore, offspringReport] = generate_offspring( ...
        parents, problem, agvData, variationOptions);
    if ~offspringReport.isValid
        error('run_independent_nsga2:InvalidOffspring', ...
            'generate_offspring returned an invalid offspring population.');
    end

    [offspring, ~] = evaluate_core_population( ...
        offspringCore, problem, machineData, agvData, evalConfig);
    combined = [population(:, 1:size(initialPopulation, 2) + objNum); ...
        offspring(:, 1:size(initialPopulation, 2) + objNum)];
    combined = assign_rank_and_crowding(combined, objNum);
    population = environmental_selection_independent(combined, pop, objNum);

    popHistory{gen} = population;
    objectives = population(:, end - objNum - 1:end - 2);
    curveMin(:, gen) = min(objectives, [], 1)';
    curveAvg(:, gen) = mean(objectives, 1)';
end

rankColumn = size(population, 2) - 1;
objectiveColumns = size(population, 2) - objNum - 1:size(population, 2) - 2;
front = population(population(:, rankColumn) == 1, :);
if isempty(front)
    front = population;
end

objMatrix = front(:, objectiveColumns);
[objMatrix, uniqueIndexes] = unique(objMatrix, 'rows');
front = front(uniqueIndexes, :);
coreDim = size(initialPopulation, 2);
frontChrom = front(:, 1:coreDim);

NSGA2_Result = struct();
NSGA2_Result.RunTime = toc(tStart);
NSGA2_Result.chrom = frontChrom;
NSGA2_Result.obj_matrix = objMatrix;
NSGA2_Result.curve.min = curveMin;
NSGA2_Result.curve.avg = curveAvg;
NSGA2_Result.pop_history = popHistory;
NSGA2_Result.details = build_final_details(frontChrom, problem, machineData, agvData, evalConfig);

runInfo = struct();
runInfo.p_cross = pCross;
runInfo.p_mutation = pMutation;
runInfo.pop = pop;
runInfo.max_gen = maxGen;
runInfo.obj_num = objNum;
runInfo.encodingReport = encodingReport;
runInfo.isIndependent = true;
runInfo.usedRawSearch = false;
runInfo.usedRawDecoding = false;
runInfo.usedRawEvaluation = false;
if isfield(options, 'label')
    runInfo.label = options.label;
end
runInfo.initialPopulationDetails = populationDetails;
end

function [population, details] = evaluate_core_population(corePopulation, problem, machineData, agvData, evalConfig)
corePopulation = corePopulation(:, 1:5 * sum(problem.operaNumVec));
objectiveValues = zeros(size(corePopulation, 1), 2);
details = cell(size(corePopulation, 1), 1);

for i = 1:size(corePopulation, 1)
    [decodedResult, decodeReport] = decode_chromosome_independent( ...
        corePopulation(i, :), problem, machineData, agvData, evalConfig);
    if ~decodeReport.isValid
        error('run_independent_nsga2:DecodeFailed', ...
            strjoin(decodeReport.errors, newline));
    end

    evalResult = evaluate_decoded_schedule( ...
        decodedResult, problem, machineData, agvData, evalConfig);
    objectiveValues(i, :) = evalResult.objectives;
    details{i} = struct('decodedResult', decodedResult, ...
        'decodeReport', decodeReport, 'evalResult', evalResult);
end

population = [corePopulation, objectiveValues];
end

function population = assign_rank_and_crowding(population, objNum)
objectiveColumns = size(population, 2) - objNum + 1:size(population, 2);
objectives = population(:, objectiveColumns);
[rank, fronts] = non_dominated_sort_independent(objectives);
crowding = crowding_distance_independent(objectives, fronts);
population = [population, rank(:), crowding(:)];
end

function evalConfig = build_evaluation_config(config, problem, machineData, agvData)
evalConfig = struct();
evalConfig.AGVEG_MAX = config.energy.AGVEG_MAX;
evalConfig.eChargeSpeed = config.energy.eChargeSpeed;
evalConfig.AGVEG_MIN = compute_agv_energy_min( ...
    machineData.distance_matrix, agvData, agvData.AGVEnergy);
evalConfig.machineTable = create_initial_machine_table(problem.machineNum);
evalConfig.AGVTable = create_initial_agv_table(agvData.AGVNum);
end

function details = build_final_details(frontChrom, problem, machineData, agvData, evalConfig)
details = cell(size(frontChrom, 1), 1);
for i = 1:size(frontChrom, 1)
    [decodedResult, decodeReport] = decode_chromosome_independent( ...
        frontChrom(i, :), problem, machineData, agvData, evalConfig);
    evalResult = evaluate_decoded_schedule( ...
        decodedResult, problem, machineData, agvData, evalConfig);
    details{i} = struct('decodedResult', decodedResult, ...
        'decodeReport', decodeReport, 'evalResult', evalResult);
end
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
