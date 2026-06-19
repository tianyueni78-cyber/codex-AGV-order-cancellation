function front = remove_dominated_points(objMatrix)
%REMOVE_DOMINATED_POINTS Keep non-dominated rows for minimization.

keep = true(size(objMatrix, 1), 1);
for i = 1:size(objMatrix, 1)
    for j = 1:size(objMatrix, 1)
        if i ~= j && dominates_minimization(objMatrix(j, :), objMatrix(i, :))
            keep(i) = false;
            break;
        end
    end
end

front = unique(objMatrix(keep, :), 'rows');
end
