function mutatedRS = mutate_rs_resample(RS, UP)
%MUTATE_RS_RESAMPLE Resample several RS positions within their bounds.

if nargin < 2
    error('mutate_rs_resample:MissingInput', 'RS and UP are required.');
end

mutatedRS = RS(:).';
UP = UP(:).';
rsLen = numel(mutatedRS);
if rsLen ~= numel(UP)
    error('mutate_rs_resample:LengthMismatch', ...
        'RS and UP must have the same length.');
end
if any(UP < 1) || any(UP ~= fix(UP))
    error('mutate_rs_resample:InvalidUpperBounds', ...
        'UP must contain positive integer upper bounds.');
end

maxMutationCount = max(1, round(0.05 * rsLen));
mutationCount = randi(maxMutationCount);
selectedPositions = randperm(rsLen, mutationCount);

for i = 1:numel(selectedPositions)
    pos = selectedPositions(i);
    mutatedRS(pos) = randi(UP(pos));
end
end
