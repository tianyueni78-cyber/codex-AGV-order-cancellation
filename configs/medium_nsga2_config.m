function config = medium_nsga2_config(projectRoot)
%MEDIUM_NSGA2_CONFIG Configuration for a slightly larger NSGA-II run.
%   This keeps small_nsga2_config.m as the fast baseline and only overrides
%   the parameters that define the medium smoke run.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = small_nsga2_config(projectRoot);

config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', 'medium_nsga2');

config.algorithm.pop = 20;
config.algorithm.max_gen = 5;
end
