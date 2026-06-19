clear
clc

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));

rng(42);

problem = read_fjsp(fullfile(projectRoot, 'data_sample', 'Mk01.fjs'));
agvFiles = dir(fullfile(projectRoot, 'data_sample', 'AGV*.xlsx'));
assert(~isempty(agvFiles), 'No AGV sample workbook found.');
agvData = read_agv_data(fullfile(agvFiles(1).folder, agvFiles(1).name));

popSize = 4;
operaNum = sum(problem.operaNumVec);
expectedDim = 5 * operaNum;

[population, populationReport] = generate_initial_population( ...
    popSize, problem, agvData);
assert(populationReport.isValid, ...
    'Initial population failed encoding validation.');
assert(size(population, 2) == expectedDim, ...
    'Initial chromosome length does not match 5 * operaNum.');

options = struct();
options.pCross = 1.0;
options.pMutation = 1.0;
[offspring, offspringReport] = generate_offspring( ...
    population, problem, agvData, options);
assert(offspringReport.isValid, ...
    'Offspring population failed encoding validation.');
assert(size(offspring, 2) == expectedDim, ...
    'Offspring chromosome length does not match 5 * operaNum.');

fprintf('run_encoding_smoke passed: popSize=%d, offspringSize=%d, chromosomeLength=%d\n', ...
    popSize, size(offspring, 1), expectedDim);
