function [rank, fronts] = non_dominated_sort_independent(objectives)
%NON_DOMINATED_SORT_INDEPENDENT Fast non-dominated sort for minimization.

validate_objectives(objectives);

solutionCount = size(objectives, 1);
dominatesSet = cell(solutionCount, 1);
dominatedCount = zeros(solutionCount, 1);
fronts = {};
fronts{1} = [];

for p = 1:solutionCount
    for q = 1:solutionCount
        if p == q
            continue
        end
        if dominates(objectives(p, :), objectives(q, :))
            dominatesSet{p}(end + 1) = q;
        elseif dominates(objectives(q, :), objectives(p, :))
            dominatedCount(p) = dominatedCount(p) + 1;
        end
    end
    if dominatedCount(p) == 0
        fronts{1}(end + 1) = p;
    end
end

rank = zeros(solutionCount, 1);
frontIndex = 1;
while frontIndex <= numel(fronts) && ~isempty(fronts{frontIndex})
    nextFront = [];
    for p = fronts{frontIndex}
        rank(p) = frontIndex;
        for q = dominatesSet{p}
            dominatedCount(q) = dominatedCount(q) - 1;
            if dominatedCount(q) == 0
                nextFront(end + 1) = q; %#ok<AGROW>
            end
        end
    end
    frontIndex = frontIndex + 1;
    if ~isempty(nextFront)
        fronts{frontIndex} = nextFront; %#ok<AGROW>
    end
end
end

function tf = dominates(a, b)
tf = all(a <= b) && any(a < b);
end

function validate_objectives(objectives)
if ~isnumeric(objectives) || ~ismatrix(objectives) || isempty(objectives)
    error('non_dominated_sort_independent:InvalidObjectives', ...
        'objectives must be a non-empty numeric matrix.');
end
if any(~isfinite(objectives(:)))
    error('non_dominated_sort_independent:InvalidObjectives', ...
        'objectives must contain only finite values.');
end
end
