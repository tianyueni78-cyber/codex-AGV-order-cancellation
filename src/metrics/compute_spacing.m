function spacing = compute_spacing(objMatrix)
%COMPUTE_SPACING Compute spacing for a minimization objective matrix.

validate_obj_matrix(objMatrix);

if size(objMatrix, 1) < 2
    spacing = 0;
    return;
end

distance = zeros(size(objMatrix, 1));
for i = 1:size(objMatrix, 1)
    for j = 1:size(objMatrix, 1)
        distance(i, j) = sum(abs(objMatrix(i, :) - objMatrix(j, :)));
    end
end

distance(logical(eye(size(distance, 1)))) = inf;
spacing = std(min(distance, [], 2));
end
