function parts = split_chromosome(chrom, problem)
%SPLIT_CHROMOSOME Split an FJSP-AGV chromosome into encoding segments.
%   parts = SPLIT_CHROMOSOME(chrom, problem) returns OS, MS, AS, and SS
%   segments from the first 5 * sum(problem.operaNumVec) values of chrom.
%   Extra trailing columns, such as objectives or search metadata appended
%   by NSGA2.m, are preserved in parts.extraColumns.

if nargin < 2
    error('split_chromosome:MissingInput', ...
        'chrom and problem are required.');
end

require_fields(problem, {'operaNumVec'}, 'problem');

if ~isvector(chrom)
    error('split_chromosome:InvalidChromosome', ...
        'chrom must be a single chromosome vector.');
end

chrom = chrom(:).';
operaNum = sum(problem.operaNumVec);
dim = 5 * operaNum;

if numel(chrom) < dim
    error('split_chromosome:InvalidLength', ...
        'chrom length must be at least 5 * sum(problem.operaNumVec).');
end

parts = struct();
parts.operaNum = operaNum;
parts.dim = dim;
parts.OS = chrom(1:operaNum);
parts.MS = chrom(operaNum + 1:2 * operaNum);
parts.AS = chrom(2 * operaNum + 1:3 * operaNum);
parts.SS = chrom(3 * operaNum + 1:5 * operaNum);
parts.extraColumns = chrom(dim + 1:end);
end

function require_fields(s, fields, structName)
for i = 1:numel(fields)
    if ~isfield(s, fields{i})
        error('split_chromosome:MissingField', ...
            '%s.%s is required.', structName, fields{i});
    end
end
end
