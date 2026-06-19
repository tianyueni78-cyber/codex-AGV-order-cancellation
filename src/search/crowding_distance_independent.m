function crowding = crowding_distance_independent(objectives, fronts)
%CROWDING_DISTANCE_INDEPENDENT Compute crowding distance for each front.

if ~isnumeric(objectives) || isempty(objectives)
    error('crowding_distance_independent:InvalidObjectives', ...
        'objectives must be a non-empty numeric matrix.');
end

solutionCount = size(objectives, 1);
objectiveCount = size(objectives, 2);
crowding = zeros(solutionCount, 1);

for frontIndex = 1:numel(fronts)
    front = fronts{frontIndex};
    if isempty(front)
        continue
    end
    if numel(front) <= 2
        crowding(front) = inf;
        continue
    end

    frontObjectives = objectives(front, :);
    frontCrowding = zeros(numel(front), 1);
    for objectiveIndex = 1:objectiveCount
        [sortedValues, order] = sort(frontObjectives(:, objectiveIndex));
        frontCrowding(order(1)) = inf;
        frontCrowding(order(end)) = inf;

        valueRange = sortedValues(end) - sortedValues(1);
        if valueRange == 0
            continue
        end
        for i = 2:numel(front) - 1
            frontCrowding(order(i)) = frontCrowding(order(i)) + ...
                (sortedValues(i + 1) - sortedValues(i - 1)) / valueRange;
        end
    end
    crowding(front) = frontCrowding;
end
end
