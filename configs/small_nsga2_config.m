function config = small_nsga2_config(projectRoot)
%SMALL_NSGA2_CONFIG Configuration for the small NSGA-II runnable example.
%   config = SMALL_NSGA2_CONFIG(projectRoot) centralizes data paths,
%   algorithm parameters, and output locations for scripts/run_small_nsga2.m.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = struct();

config.paths.fjsp = fullfile(projectRoot, 'data_sample', 'Mk01.fjs');
config.paths.machineExcel = fullfile(projectRoot, 'data_sample', '机器数据.xlsx');
config.paths.agvExcel = fullfile(projectRoot, 'data_sample', 'AGV数据.xlsx');
config.paths.algorithmDir = fullfile(projectRoot, 'raw_code', 'NSGA-II');
config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', 'small_nsga2');

config.random.seed = 42;

config.algorithm.p_cross = 0.8;
config.algorithm.p_mutation = 0.2;
config.algorithm.pop = 10;
config.algorithm.max_gen = 2;

config.energy.AGVEG_MAX = 100;
config.energy.eChargeSpeed = 20;
end
