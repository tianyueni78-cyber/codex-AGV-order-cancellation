function [child1RS, child2RS] = crossover_rs_mpx(parent1RS, parent2RS)
%CROSSOVER_RS_MPX Apply MPX crossover to two RS vectors.

if nargin < 2
    error('crossover_rs_mpx:MissingInput', ...
        'parent1RS and parent2RS are required.');
end

parent1RS = parent1RS(:).';
parent2RS = parent2RS(:).';
rsLen = numel(parent1RS);
if rsLen ~= numel(parent2RS)
    error('crossover_rs_mpx:LengthMismatch', ...
        'parent1RS and parent2RS must have the same length.');
end

selectedCount = randi(rsLen);
selectedPositions = sort(randperm(rsLen, selectedCount));

child1RS = parent2RS;
child2RS = parent1RS;
child1RS(selectedPositions) = parent1RS(selectedPositions);
child2RS(selectedPositions) = parent2RS(selectedPositions);
end
