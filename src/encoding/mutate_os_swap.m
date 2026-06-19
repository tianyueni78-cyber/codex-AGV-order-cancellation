function mutatedOS = mutate_os_swap(OS)
%MUTATE_OS_SWAP Swap two positions with different job ids in an OS vector.

if nargin < 1
    error('mutate_os_swap:MissingInput', 'OS is required.');
end

mutatedOS = OS(:).';
if numel(unique(mutatedOS)) < 2
    return
end

pos1 = randi(numel(mutatedOS));
differentPositions = find(mutatedOS ~= mutatedOS(pos1));
pos2 = differentPositions(randi(numel(differentPositions)));

cache = mutatedOS(pos1);
mutatedOS(pos1) = mutatedOS(pos2);
mutatedOS(pos2) = cache;
end
