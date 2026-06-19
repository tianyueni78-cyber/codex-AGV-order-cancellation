function result = evaluate_chromosome(chrom, problem, machineData, agvData, config)
%EVALUATE_CHROMOSOME Evaluate one chromosome with the original fitness chain.
%   result = EVALUATE_CHROMOSOME(chrom, problem, machineData, agvData, config)
%   maps refactored data structures to the original fitness.m inputs. The
%   selected raw algorithm directory must already be on the MATLAB path.

if nargin < 5
    error('evaluate_chromosome:MissingInput', ...
        'chrom, problem, machineData, agvData, and config are required.');
end

if exist('fitness', 'file') ~= 2
    error('evaluate_chromosome:FitnessNotOnPath', ...
        ['fitness.m was not found on the MATLAB path. ', ...
        'Add the intended raw algorithm directory before calling this function.']);
end

require_fields(problem, {'jobNum', 'jobInfo', 'operaNumVec', ...
    'machineNum', 'candidateMachine'}, 'problem');
require_fields(machineData, {'distance_matrix', 'machineEnergy'}, 'machineData');
require_fields(agvData, {'AGVNum', 'AGVSpeed', 'AGVEnergy'}, 'agvData');
require_fields(config, {'AGVEG_MAX', 'AGVEG_MIN', 'eChargeSpeed'}, 'config');
validate_chromosome_input(chrom, problem);

[FUNC, machineTable, AGVTable, makespan, EG_M_SUM, EG_A_SUM, ...
    agvEGRecord, agvChargeNum] = fitness(chrom, ...
    problem.jobNum, ...
    problem.jobInfo, ...
    problem.operaNumVec, ...
    problem.machineNum, ...
    agvData.AGVNum, ...
    agvData.AGVSpeed, ...
    problem.candidateMachine, ...
    machineData.distance_matrix, ...
    machineData.machineEnergy, ...
    agvData.AGVEnergy, ...
    config.AGVEG_MAX, ...
    config.AGVEG_MIN, ...
    config.eChargeSpeed);

result = struct();
result.FUNC = FUNC;
result.objectives = FUNC{1};
result.makespan = makespan;
result.machineEnergy = EG_M_SUM;
result.agvEnergy = EG_A_SUM;
result.totalEnergy = EG_M_SUM + EG_A_SUM;
result.machineTable = machineTable;
result.AGVTable = AGVTable;
result.agvEGRecord = agvEGRecord;
result.agvChargeNum = agvChargeNum;
end

function validate_chromosome_input(chrom, problem)
if ~isnumeric(chrom) || isempty(chrom) || ~isrow(chrom)
    error('evaluate_chromosome:InvalidChromosome', ...
        'chrom must be a non-empty numeric row vector.');
end

expectedLength = 5 * sum(problem.operaNumVec);
if numel(chrom) ~= expectedLength
    error('evaluate_chromosome:InvalidChromosome', ...
        'chrom length must be 5 * sum(problem.operaNumVec).');
end
end

function require_fields(s, fields, structName)
for i = 1:numel(fields)
    if ~isfield(s, fields{i})
        error('evaluate_chromosome:MissingField', ...
            '%s.%s is required.', structName, fields{i});
    end
end
end
