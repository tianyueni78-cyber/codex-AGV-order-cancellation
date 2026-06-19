function [offspring, report] = generate_offspring(parentPopulation, problem, agvData, options)
%GENERATE_OFFSPRING Generate offspring chromosomes through crossover/mutation.
%   [offspring, report] = GENERATE_OFFSPRING(parentPopulation, problem,
%   agvData, options) applies the encoding-layer variation logic to core
%   chromosomes. It does not decode schedules, call fitness, run NSGA-II, or
%   write outputs.

if nargin < 3
    error('generate_offspring:MissingInput', ...
        'parentPopulation, problem, and agvData are required.');
end
if nargin < 4
    options = struct();
end

pCross = read_probability(options, {'pCross', 'p_cross'}, 0.8);
pMutation = read_probability(options, {'pMutation', 'p_mutation'}, 0.2);

operaNum = sum(problem.operaNumVec);
dim = 5 * operaNum;
if ~ismatrix(parentPopulation) || isempty(parentPopulation)
    error('generate_offspring:InvalidParentPopulation', ...
        'parentPopulation must be a non-empty matrix.');
end
if size(parentPopulation, 2) < dim
    error('generate_offspring:InvalidParentLength', ...
        'parentPopulation must contain at least 5 * sum(operaNumVec) columns.');
end

parents = parentPopulation(:, 1:dim);
parentCount = size(parents, 1);
UP = build_rs_upper_bounds(problem, agvData);
offspring = [];

for i = 1:parentCount
    parent1Index = randi(parentCount);
    child = parents(parent1Index, :);

    if rand < pCross && parentCount > 1
        parent2Index = select_second_parent(parents, parent1Index);
        if parent2Index ~= parent1Index
            child = crossover_parents( ...
                parents(parent1Index, :), ...
                parents(parent2Index, :), ...
                problem.jobNum, operaNum, dim);
        end
    end

    for childIdx = 1:size(child, 1)
        if rand < pMutation
            child(childIdx, :) = mutate_child(child(childIdx, :), operaNum, UP);
        end
    end

    offspring = [offspring; child]; %#ok<AGROW>
end

report = validate_population(offspring, problem, agvData);
end

function child = crossover_parents(parent1, parent2, jobNum, operaNum, dim)
parent1OS = parent1(1:operaNum);
parent1RS = parent1(operaNum + 1:dim);
parent2OS = parent2(1:operaNum);
parent2RS = parent2(operaNum + 1:dim);

[child1OS, child2OS] = crossover_os_ipox(parent1OS, parent2OS, jobNum);
[child1RS, child2RS] = crossover_rs_mpx(parent1RS, parent2RS);
child = [
    child1OS, child2RS
    child2OS, child1RS
];
end

function child = mutate_child(child, operaNum, UP)
OS = child(1:operaNum);
RS = child(operaNum + 1:end);

child = [mutate_os_swap(OS), mutate_rs_resample(RS, UP)];
end

function parent2Index = select_second_parent(parents, parent1Index)
parentCount = size(parents, 1);
parent1Rows = repmat(parents(parent1Index, :), parentCount, 1);
candidateIndexes = find(~all(parents == parent1Rows, 2));

if isempty(candidateIndexes)
    parent2Index = parent1Index;
else
    parent2Index = candidateIndexes(randi(numel(candidateIndexes)));
end
end

function value = read_probability(options, names, defaultValue)
value = defaultValue;
for i = 1:numel(names)
    if isfield(options, names{i})
        value = options.(names{i});
        break
    end
end

validateattributes(value, {'numeric'}, ...
    {'scalar', '>=', 0, '<=', 1}, mfilename, names{1});
end
