function selectedIndexes = tournament_selection_independent(population, selectionCount)
%TOURNAMENT_SELECTION_INDEPENDENT Binary tournament by rank and crowding.

if nargin < 2
    error('tournament_selection_independent:MissingInput', ...
        'population and selectionCount are required.');
end
if selectionCount <= 0
    error('tournament_selection_independent:InvalidSelectionCount', ...
        'selectionCount must be positive.');
end

populationSize = size(population, 1);
rankColumn = size(population, 2) - 1;
crowdingColumn = size(population, 2);
selectedIndexes = zeros(selectionCount, 1);

for i = 1:selectionCount
    a = randi(populationSize);
    b = randi(populationSize);
    selectedIndexes(i) = better_individual( ...
        population, a, b, rankColumn, crowdingColumn);
end
end

function winner = better_individual(population, a, b, rankColumn, crowdingColumn)
if population(a, rankColumn) < population(b, rankColumn)
    winner = a;
elseif population(a, rankColumn) > population(b, rankColumn)
    winner = b;
elseif population(a, crowdingColumn) >= population(b, crowdingColumn)
    winner = a;
else
    winner = b;
end
end
