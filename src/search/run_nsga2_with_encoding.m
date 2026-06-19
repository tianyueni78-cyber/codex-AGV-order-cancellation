function [NSGA2_Result, chrom, runInfo] = run_nsga2_with_encoding(config, problem, machineData, agvData, options)
%RUN_NSGA2_WITH_ENCODING Run NSGA-II with the refactored encoding layer.
%   This wrapper prepares initial chromosomes with src/encoding instead of
%   raw init.m. By default it still calls raw NSGA2.m for the search loop.
%   Set options.useRefactoredVariation = true to use the new encoding-layer
%   offspring generator inside a copied search loop.

if nargin < 4
    error('run_nsga2_with_encoding:MissingInput', ...
        'config, problem, machineData, and agvData are required.');
end
if nargin < 5
    options = struct();
end

useRefactoredVariation = read_option(options, ...
    'useRefactoredVariation', false);

p_cross = config.algorithm.p_cross;
p_mutation = config.algorithm.p_mutation;
pop = config.algorithm.pop;
max_gen = config.algorithm.max_gen;

distance_matrix = machineData.distance_matrix;
machineEnergy = machineData.machineEnergy;
AGVEnergy = agvData.AGVEnergy;
AGVEG_MAX = config.energy.AGVEG_MAX;
eChargeSpeed = config.energy.eChargeSpeed;
AGVEG_MIN = compute_agv_energy_min(distance_matrix, agvData, AGVEnergy);

[chrom, encodingReport] = generate_initial_population(pop, problem, agvData);
if ~encodingReport.isValid
    error('run_nsga2_with_encoding:InvalidInitialPopulation', ...
        'Refactored encoding generated an invalid initial population.');
end

oldPath = path;
cleanup = onCleanup(@() path(oldPath));
addpath(config.paths.algorithmDir, '-begin');

if useRefactoredVariation
    NSGA2_Result = nsga2_with_encoding_variation( ...
        p_cross, p_mutation, pop, chrom, max_gen, ...
        problem, machineData, agvData, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
else
    NSGA2_Result = NSGA2(p_cross, p_mutation, pop, chrom, max_gen, ...
        problem.jobNum, ...
        problem.jobInfo, ...
        problem.operaNumVec, ...
        problem.machineNum, ...
        agvData.AGVNum, ...
        agvData.AGVSpeed, ...
        problem.candidateMachine, ...
        distance_matrix, ...
        machineEnergy, ...
        AGVEnergy, ...
        AGVEG_MAX, ...
        AGVEG_MIN, ...
        eChargeSpeed);
end

runInfo = struct();
runInfo.p_cross = p_cross;
runInfo.p_mutation = p_mutation;
runInfo.pop = pop;
runInfo.max_gen = max_gen;
runInfo.AGVEG_MAX = AGVEG_MAX;
runInfo.AGVEG_MIN = AGVEG_MIN;
runInfo.eChargeSpeed = eChargeSpeed;
runInfo.encodingReport = encodingReport;
runInfo.useRefactoredVariation = useRefactoredVariation;
end

function AGVEG_MIN = compute_agv_energy_min(distance_matrix, agvData, AGVEnergy)
distance_MAX = max([max(distance_matrix.machine_to_machine(:)), ...
    max(distance_matrix.load_to_machine), ...
    max(distance_matrix.machine_to_unload), ...
    distance_matrix.load_to_unload]);
AGVEG_MIN = distance_MAX / agvData.AGVSpeed(end) * ...
    (AGVEnergy.free(end) + AGVEnergy.load(end)) + 1e-6;
end

function value = read_option(options, name, defaultValue)
value = defaultValue;
if isfield(options, name)
    value = options.(name);
end
end
