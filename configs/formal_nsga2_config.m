function config = formal_nsga2_config(projectRoot)
%FORMAL_NSGA2_CONFIG Configuration for the formal NSGA-II experiment entry.
%   This file defines the future formal run configuration only. It does not
%   run NSGA-II by itself; scripts/run_formal_nsga2.m will consume it later.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = medium_nsga2_config(projectRoot);

config.experiment.name = 'formal_nsga2_Mk01';
config.experiment.description = 'Initial formal NSGA-II configuration for the Mk01 sample data.';
config.experiment.runType = 'formal';

config.dataset.name = 'Mk01';
config.dataset.source = 'data_sample';
config.dataset.note = 'Uses Mk01.fjs with the paired machine and AGV sample spreadsheets.';

config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', 'formal_nsga2');

config.random.seedList = 42;
config.random.currentSeed = config.random.seed;

config.algorithm.name = 'NSGA-II';
config.algorithm.pop = 30;
config.algorithm.max_gen = 10;

config.output.saveSummary = true;
config.output.saveMat = true;
config.output.saveRunInfo = true;
config.output.saveLog = false;
end
