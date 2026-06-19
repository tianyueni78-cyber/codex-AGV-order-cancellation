function cValue = compute_c_metric(objMatrixA, objMatrixB)
%COMPUTE_C_METRIC Compute the fraction of B dominated by A.

validate_obj_matrix(objMatrixA);
validate_obj_matrix(objMatrixB);

if size(objMatrixA, 2) ~= size(objMatrixB, 2)
    error('compute_c_metric:ObjectiveMismatch', ...
        'Objective matrices must have the same number of columns.');
end

dominatedCount = 0;
for i = 1:size(objMatrixB, 1)
    for j = 1:size(objMatrixA, 1)
        if dominates_minimization(objMatrixA(j, :), objMatrixB(i, :))
            dominatedCount = dominatedCount + 1;
            break;
        end
    end
end

cValue = dominatedCount / size(objMatrixB, 1);
end
