function [child1OS, child2OS] = crossover_os_ipox(parent1OS, parent2OS, jobNum)
%CROSSOVER_OS_IPOX Apply IPOX crossover to two OS vectors.

if nargin < 3
    error('crossover_os_ipox:MissingInput', ...
        'parent1OS, parent2OS, and jobNum are required.');
end

parent1OS = parent1OS(:).';
parent2OS = parent2OS(:).';
if numel(parent1OS) ~= numel(parent2OS)
    error('crossover_os_ipox:LengthMismatch', ...
        'parent1OS and parent2OS must have the same length.');
end

selectedCount = randi(jobNum);
jobSet = sort(randperm(jobNum, selectedCount));

parent1Selected = ismember(parent1OS, jobSet);
parent2Selected = ismember(parent2OS, jobSet);

child1OS = parent1OS .* ~parent1Selected;
child1OS(child1OS == 0) = parent2OS(parent2Selected);

child2OS = parent2OS .* ~parent2Selected;
child2OS(child2OS == 0) = parent1OS(parent1Selected);
end
