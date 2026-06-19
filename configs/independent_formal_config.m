function config = independent_formal_config(projectRoot)
%INDEPENDENT_FORMAL_CONFIG Configuration for the independent formal entry.
%   This defines formal parameters and output rules. The formal script uses
%   a preflight guard and does not run the full experiment by default.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = independent_medium_config(projectRoot);

config.experiment.name = 'independent_formal_nsga2';
config.experiment.description = 'Independent NSGA-II formal experiment configuration.';
config.experiment.runType = 'independent_formal';

config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', 'independent_formal_nsga2');

config.random.seedList = [42, 43, 44, 45, 46];
config.random.currentSeed = config.random.seedList(1);

config.algorithm.pop = 30;
config.algorithm.max_gen = 10;
end
