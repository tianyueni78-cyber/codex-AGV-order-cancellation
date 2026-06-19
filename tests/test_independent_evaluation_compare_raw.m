clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

fprintf('independent evaluation raw compare acceptance\n');
fprintf('compare: evaluate_chromosome(raw fitness wrapper) vs independent decode + evaluate\n');
fprintf('tolerance: 1e-9 for makespan, machineEnergy, agvEnergy, totalEnergy, objectives\n');

run(fullfile(projectRoot, 'tests', 'test_evaluation_independent_compare_raw.m'));

fprintf('test_independent_evaluation_compare_raw passed\n');
