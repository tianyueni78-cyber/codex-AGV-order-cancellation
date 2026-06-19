function selected = environmental_selection_independent(population, popSize, objNum)
%ENVIRONMENTAL_SELECTION_INDEPENDENT Select next generation by rank/crowding.

if nargin < 3
    error('environmental_selection_independent:MissingInput', ...
        'population, popSize, and objNum are required.');
end

rankColumn = size(population, 2) - 1;
crowdingColumn = size(population, 2);
[~, order] = sortrows([population(:, rankColumn), -population(:, crowdingColumn)]);
selected = population(order(1:popSize), :);

coreAndObj = selected(:, 1:end - 2);
selected = assign_rank_and_crowding_for_selection(coreAndObj, objNum);
end

function population = assign_rank_and_crowding_for_selection(population, objNum)
objectiveColumns = size(population, 2) - objNum + 1:size(population, 2);
objectives = population(:, objectiveColumns);
[rank, fronts] = non_dominated_sort_independent(objectives);
crowding = crowding_distance_independent(objectives, fronts);
population = [population, rank(:), crowding(:)];
end
