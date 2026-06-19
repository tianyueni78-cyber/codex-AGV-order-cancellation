function config = independent_multiseed_config(projectRoot)
%INDEPENDENT_MULTISEED_CONFIG Small multi-seed independent NSGA-II config.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = independent_small_config(projectRoot);

config.experiment.name = 'independent_multiseed_small';
config.experiment.description = 'Small multi-seed summary for the independent NSGA-II implementation.';
config.experiment.runType = 'independent_multiseed_small';

config.random.seedList = [42, 43, 44, 45, 46];
config.random.currentSeed = config.random.seedList(1);

config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', ...
    'independent_multiseed');

config.output.saveAggregateSummary = true;
config.output.saveAggregateMat = true;
end
