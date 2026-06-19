function config = baseline_comparison_config(projectRoot)
%BASELINE_COMPARISON_CONFIG Configuration for the small baseline comparison.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

smallConfig = small_nsga2_config(projectRoot);

config = smallConfig;
config.experiment.name = 'baseline_comparison_small';
config.experiment.description = 'Small comparison between raw NSGA-II baseline and independent NSGA-II variant.';
config.experiment.runType = 'baseline_comparison_small';

config.dataset.name = 'Mk01';
config.dataset.source = 'data_sample';
config.dataset.note = 'Uses the same Mk01 sample data for baseline and variant.';

config.comparison.baselineName = 'raw_nsga2';
config.comparison.variantName = 'independent_nsga2';
config.comparison.seed = smallConfig.random.seed;
config.comparison.requireSamePop = true;
config.comparison.requireSameMaxGen = true;

config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', ...
    'baseline_comparison_small');
config.paths.implementationDir = fullfile(projectRoot, 'src');

config.output.saveSummary = true;
config.output.saveMat = true;
config.output.saveRunInfo = true;
end
