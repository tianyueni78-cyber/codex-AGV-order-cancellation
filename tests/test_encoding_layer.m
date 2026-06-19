clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'data'));

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

assert(size(population, 1) == popSize, ...
    'Initial population row count does not match popSize.');
assert(size(population, 2) == expectedDim, ...
    'Initial chromosome length does not match 5 * operaNum.');
assert(populationReport.isValid, ...
    'Generated population did not pass encoding validation.');
assert(populationReport.validCount == popSize, ...
    'Generated population validCount does not match popSize.');
assert(populationReport.invalidCount == 0, ...
    'Generated population contains invalid chromosomes.');
assert(isempty(populationReport.invalidIndexes), ...
    'Generated population has invalid chromosome indexes.');

fullReport = validate_population(population, problem, agvData);
assert(fullReport.isValid, ...
    'Full population validation did not pass.');
assert(fullReport.validCount == popSize, ...
    'Full population validCount does not match popSize.');
assert(fullReport.invalidCount == 0, ...
    'Full population contains invalid chromosomes.');

for i = 1:popSize
    parts = split_chromosome(population(i, :), problem);
    assert(numel(parts.OS) == operaNum, 'OS length mismatch.');
    assert(numel(parts.MS) == operaNum, 'MS length mismatch.');
    assert(numel(parts.AS) == operaNum, 'AS length mismatch.');
    assert(numel(parts.SS) == 2 * operaNum, 'SS length mismatch.');

    assert(fullReport.chromosomes(i).isValid, ...
        strjoin(fullReport.chromosomes(i).errors, newline));
end

UP = build_rs_upper_bounds(problem, agvData);
assert(numel(UP) == 4 * operaNum, ...
    'RS upper bound length does not match 4 * operaNum.');

options = struct();
options.pCross = 1.0;
options.pMutation = 1.0;
[offspring, offspringReport] = generate_offspring( ...
    population, problem, agvData, options);

assert(~isempty(offspring), 'Offspring population is empty.');
assert(size(offspring, 2) == expectedDim, ...
    'Offspring chromosome length does not match 5 * operaNum.');
assert(offspringReport.isValid, ...
    'Offspring population validation did not pass.');
assert(offspringReport.validCount == size(offspring, 1), ...
    'Offspring validCount does not match offspring row count.');
assert(offspringReport.invalidCount == 0, ...
    'Offspring population contains invalid chromosomes.');

fprintf('test_encoding_layer passed: popSize=%d, chromosomeLength=%d\n', ...
    popSize, expectedDim);
