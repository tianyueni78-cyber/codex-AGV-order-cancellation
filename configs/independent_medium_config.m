function config = independent_medium_config(projectRoot)
%INDEPENDENT_MEDIUM_CONFIG Configuration for the independent medium run.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = independent_small_config(projectRoot);

config.experiment.name = 'independent_medium_nsga2';
config.experiment.description = 'Independent NSGA-II medium validation run using src implementation only.';
config.experiment.runType = 'independent_medium';

config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', 'independent_medium_nsga2');

config.algorithm.pop = 20;
config.algorithm.max_gen = 5;
end
