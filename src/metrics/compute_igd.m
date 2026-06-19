function igd = compute_igd(objMatrix, referenceFront)
%COMPUTE_IGD Compute inverted generational distance.

validate_obj_matrix(objMatrix);
validate_obj_matrix(referenceFront);

if size(objMatrix, 2) ~= size(referenceFront, 2)
    error('compute_igd:ObjectiveMismatch', ...
        'Objective matrix and reference front must have the same number of columns.');
end

distanceSum = 0;
for i = 1:size(referenceFront, 1)
    nearest = inf;
    for j = 1:size(objMatrix, 1)
        distance = norm(referenceFront(i, :) - objMatrix(j, :));
        if distance < nearest
            nearest = distance;
        end
    end
    distanceSum = distanceSum + nearest;
end

igd = distanceSum / size(referenceFront, 1);
end
