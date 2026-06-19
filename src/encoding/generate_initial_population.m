function [population, report] = generate_initial_population(popSize, problem, agvData)
%GENERATE_INITIAL_POPULATION Build an initial chromosome population.
%   [population, report] = GENERATE_INITIAL_POPULATION(popSize, problem, agvData)
%   generates core OS, MS, AS, and SS encoding chromosomes and validates
%   each generated chromosome with the encoding-layer checker.
%
%   This function only generates and validates core encoding chromosomes. It
%   does not run NSGA-II, decode schedules, call fitness, or write outputs.

if nargin < 3
    error('generate_initial_population:MissingInput', ...
        'popSize, problem, and agvData are required.');
end

validateattributes(popSize, {'numeric'}, ...
    {'scalar', 'integer', 'positive'}, mfilename, 'popSize');
require_fields(problem, {'jobNum', 'operaNumVec', 'candidateMachine'}, ...
    'problem');
require_fields(agvData, {'AGVNum', 'AGVSpeed'}, 'agvData');

speedNum = numel(agvData.AGVSpeed);
if speedNum < 1
    error('generate_initial_population:InvalidSpeedData', ...
        'agvData.AGVSpeed must contain at least one speed option.');
end

population = generate_population(popSize, problem, agvData.AGVNum, speedNum);

report = validate_population(population, problem, agvData);
end

function population = generate_population(popSize, problem, AGVNum, speedNum)
operaNum = sum(problem.operaNumVec);
dim = 5 * operaNum;
operationPool = build_operation_pool(problem.jobNum, problem.operaNumVec);
population = zeros(popSize, dim);

for i = 1:popSize
    OS = operationPool(randperm(operaNum));
    MS = generate_machine_selection(problem);
    AS = randi([1, AGVNum], 1, operaNum);
    SS = randi([1, speedNum], 1, 2 * operaNum);
    population(i, :) = [OS, MS, AS, SS];
end
end

function operationPool = build_operation_pool(jobNum, operaNumVec)
operationPool = zeros(1, sum(operaNumVec));
pos = 1;
for jobIdx = 1:jobNum
    count = operaNumVec(jobIdx);
    operationPool(pos:pos + count - 1) = jobIdx;
    pos = pos + count;
end
end

function MS = generate_machine_selection(problem)
operaNum = sum(problem.operaNumVec);
MS = zeros(1, operaNum);
pos = 1;

for jobIdx = 1:problem.jobNum
    for operaIdx = 1:problem.operaNumVec(jobIdx)
        candidates = problem.candidateMachine{jobIdx, operaIdx};
        candidateCount = numel(candidates);
        if candidateCount < 1
            error('generate_initial_population:EmptyCandidateMachine', ...
                'candidateMachine{%d,%d} is empty.', jobIdx, operaIdx);
        end

        MS(pos) = randi(candidateCount);
        pos = pos + 1;
    end
end
end

function require_fields(s, fields, structName)
for i = 1:numel(fields)
    if ~isfield(s, fields{i})
        error('generate_initial_population:MissingField', ...
            '%s.%s is required.', structName, fields{i});
    end
end
end
