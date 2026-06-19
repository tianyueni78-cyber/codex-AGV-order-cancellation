function config = independent_small_config(projectRoot)
%INDEPENDENT_SMALL_CONFIG Configuration for the independent small NSGA-II run.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = struct();

config.experiment.name = 'independent_small_nsga2';
config.experiment.description = 'Independent NSGA-II small smoke run using src implementation only.';
config.experiment.runType = 'independent_small';

config.dataset.name = 'Mk01';
config.dataset.source = 'data_sample';
config.dataset.note = 'Uses Mk01.fjs with the paired machine and AGV sample spreadsheets.';

config.paths.fjsp = fullfile(projectRoot, 'data_sample', 'Mk01.fjs');
config.paths.machineExcel = fullfile(projectRoot, 'data_sample', '机器数据.xlsx');
config.paths.agvExcel = fullfile(projectRoot, 'data_sample', 'AGV数据.xlsx');
config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', 'independent_small_nsga2');
config.paths.implementationDir = fullfile(projectRoot, 'src');

config.random.seed = 42;
config.random.seedList = 42;
config.random.currentSeed = config.random.seed;

config.algorithm.name = 'Independent NSGA-II';
config.algorithm.p_cross = 0.8;
config.algorithm.p_mutation = 0.2;
config.algorithm.pop = 10;
config.algorithm.max_gen = 2;

config.energy.AGVEG_MAX = 100;
config.energy.eChargeSpeed = 20;

config.output.saveSummary = true;
config.output.saveMat = true;
config.output.saveRunInfo = true;
config.output.saveLog = false;
end
