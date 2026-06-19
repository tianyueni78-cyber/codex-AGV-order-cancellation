function hv = compute_hv(objMatrix, referencePoint)
%COMPUTE_HV Compute exact 2-D hypervolume for minimization objectives.

validate_obj_matrix(objMatrix);

if nargin < 2 || isempty(referencePoint)
    referencePoint = max(objMatrix, [], 1);
end

if ~isnumeric(referencePoint) || numel(referencePoint) ~= size(objMatrix, 2)
    error('compute_hv:InvalidReferencePoint', ...
        'referencePoint must contain one value per objective.');
end

referencePoint = reshape(referencePoint, 1, []);
if any(referencePoint < max(objMatrix, [], 1))
    error('compute_hv:InvalidReferencePoint', ...
        'referencePoint must be no better than all objective values.');
end

if size(objMatrix, 2) ~= 2
    error('compute_hv:OnlyTwoObjectives', ...
        'compute_hv currently supports exact 2-D hypervolume only.');
end

front = remove_dominated_points(objMatrix);
front = sortrows(front, 1);

hv = 0;
previousY = referencePoint(2);
for i = 1:size(front, 1)
    width = referencePoint(1) - front(i, 1);
    height = previousY - front(i, 2);
    if width > 0 && height > 0
        hv = hv + width * height;
    end
    previousY = min(previousY, front(i, 2));
end
end
