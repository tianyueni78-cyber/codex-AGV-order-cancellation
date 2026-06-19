function validate_obj_matrix(objMatrix)
%VALIDATE_OBJ_MATRIX Validate a numeric objective matrix.

if ~isnumeric(objMatrix) || ~ismatrix(objMatrix) || isempty(objMatrix)
    error('metrics:InvalidObjectiveMatrix', ...
        'Objective matrix must be a non-empty numeric matrix.');
end

if any(~isfinite(objMatrix(:)))
    error('metrics:InvalidObjectiveMatrix', ...
        'Objective matrix must contain only finite values.');
end
end
