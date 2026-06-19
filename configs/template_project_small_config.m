function config = template_project_small_config(projectRoot)
%TEMPLATE_PROJECT_SMALL_CONFIG Template small config for a migrated project.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = struct();

config.project.projectName = 'template_low_carbon_fjsp';
config.project.description = ...
    'Template rehearsal for migrating the framework to a low-carbon scheduling project.';

config.experiment.name = 'template_project_small';
config.experiment.description = ...
    'Small smoke configuration template for a migrated project.';
config.experiment.runType = 'template_small';

config.dataset.name = 'template_dataset';
config.dataset.source = 'replace_with_new_dataset_source';
config.dataset.note = 'Replace these paths with the new project dataset before running.';

config.paths.fjsp = fullfile(projectRoot, 'data_sample', 'template.fjs');
config.paths.machineExcel = fullfile(projectRoot, 'data_sample', ...
    'template_machine.xlsx');
config.paths.agvExcel = fullfile(projectRoot, 'data_sample', ...
    'template_agv.xlsx');
config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', ...
    'template_project_small');
config.paths.implementationDir = fullfile(projectRoot, 'src');

config.random.seed = 42;
config.random.seedList = 42;
config.random.currentSeed = config.random.seed;

config.algorithm.name = 'Independent NSGA-II template';
config.algorithm.p_cross = 0.8;
config.algorithm.p_mutation = 0.2;
config.algorithm.pop = 10;
config.algorithm.max_gen = 2;

config.objectives.names = {'makespan', 'carbonEmission'};
config.objectives.enabled = {'makespan', 'carbonEmission'};
config.objectives.carbonFactor = 0.785;

config.improvements.adaptiveMutation.enabled = false;
config.improvements.adaptiveMutation.minRate = 0.05;
config.improvements.adaptiveMutation.maxRate = 0.3;

config.output.saveSummary = true;
config.output.saveMat = true;
config.output.saveRunInfo = true;
config.output.saveLog = false;
end
