function validate_visual_matrix(value, name)
%VALIDATE_VISUAL_MATRIX Validate numeric plotting input.

if ~isnumeric(value) || ~ismatrix(value) || isempty(value)
    error('visualization:InvalidMatrix', '%s must be a non-empty numeric matrix.', name);
end

if any(~isfinite(value(:)))
    error('visualization:InvalidMatrix', '%s must contain only finite values.', name);
end
end
