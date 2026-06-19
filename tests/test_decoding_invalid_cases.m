clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));

[problem, machineData, agvData, config, validChrom] = make_small_decoding_case();

chrom = validChrom;
chrom(1:3) = [1, 1, 1];
expect_invalid_decoding(chrom, problem, machineData, agvData, config, ...
    'invalid-encoding', 'chrom did not pass encoding validation');

chrom = validChrom;
chrom(1:3) = [1, 2, 3];
expect_invalid_decoding(chrom, problem, machineData, agvData, config, ...
    'invalid-encoding', 'chrom did not pass encoding validation');

chrom = validChrom;
chrom(4) = 3;
expect_invalid_decoding(chrom, problem, machineData, agvData, config, ...
    'invalid-encoding', 'chrom did not pass encoding validation');

chrom = validChrom;
chrom(7) = agvData.AGVNum + 1;
expect_invalid_decoding(chrom, problem, machineData, agvData, config, ...
    'invalid-encoding', 'chrom did not pass encoding validation');

chrom = validChrom;
chrom(10) = numel(agvData.AGVSpeed) + 1;
expect_invalid_decoding(chrom, problem, machineData, agvData, config, ...
    'invalid-encoding', 'chrom did not pass encoding validation');

missingMachineData = rmfield(machineData, 'distance_matrix');
expect_invalid_decoding(validChrom, problem, missingMachineData, agvData, config, ...
    'missing-required-fields', 'machineData.distance_matrix is required');

missingConfig = rmfield(config, 'machineTable');
expect_invalid_decoding(validChrom, problem, machineData, agvData, missingConfig, ...
    'missing-required-fields', 'config.machineTable is required');

try
    decode_population([], problem, machineData, agvData, config);
    error('test_decoding_invalid_cases:ExpectedError', ...
        'decode_population should reject an empty population.');
catch err
    assert(~isempty(strfind(err.identifier, ...
        'decode_population:InvalidPopulation')), ...
        'Empty population should raise decode_population:InvalidPopulation.');
end

invalidOSChrom = validChrom;
invalidOSChrom(1:3) = [1, 1, 1];
invalidMSChrom = validChrom;
invalidMSChrom(4) = 3;
population = [
    invalidOSChrom
    invalidMSChrom
];

[schedules, populationReport] = decode_population( ...
    population, problem, machineData, agvData, config);
assert(~populationReport.isValid, ...
    'Invalid population should not decode as valid.');
assert(populationReport.successCount == 0, ...
    'Invalid population successCount should be 0.');
assert(populationReport.failureCount == 2, ...
    'Invalid population failureCount should be 2.');
assert(isequal(populationReport.failedIndexes, [1, 2]), ...
    'Invalid population failedIndexes should be [1, 2].');
assert(numel(schedules) == 2, ...
    'Invalid population schedules cell count mismatch.');
assert(~populationReport.chromosomes(1).isValid, ...
    'Population row 1 should be invalid.');
assert(~populationReport.chromosomes(2).isValid, ...
    'Population row 2 should be invalid.');
assert(strcmp(populationReport.chromosomes(1).decodingStatus, 'invalid-encoding'), ...
    'Population row 1 status should be invalid-encoding.');
assert(strcmp(populationReport.chromosomes(2).decodingStatus, 'invalid-encoding'), ...
    'Population row 2 status should be invalid-encoding.');

fprintf('test_decoding_invalid_cases passed\n');

function [problem, machineData, agvData, config, validChrom] = make_small_decoding_case()
problem = struct();
problem.jobNum = 2;
problem.machineNum = 3;
problem.operaNumVec = [2, 1];
problem.candidateMachine = cell(2, 2);
problem.candidateMachine{1, 1} = [1, 2];
problem.candidateMachine{1, 2} = [2];
problem.candidateMachine{2, 1} = [1, 3];
problem.jobInfo = cell(1, 2);
problem.jobInfo{1} = [
    5, 6, inf
    inf, 4, inf
];
problem.jobInfo{2} = [
    3, inf, 7
];

machineData = struct();
machineData.distance_matrix = struct();
machineData.distance_matrix.machine_to_machine = [
    0, 2, 3
    2, 0, 4
    3, 4, 0
];
machineData.distance_matrix.load_to_machine = [1, 2, 3];
machineData.distance_matrix.machine_to_unload = [1, 2, 3];
machineData.distance_matrix.load_to_unload = 1;

agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5];
agvData.AGVEnergy = struct();
agvData.AGVEnergy.free = [1.0, 1.2];
agvData.AGVEnergy.load = [1.4, 1.6];

config = struct();
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;
config.machineTable = create_initial_machine_table(problem.machineNum);
config.AGVTable = create_initial_agv_table(agvData.AGVNum);

OS = [1, 2, 1];
MS = [2, 1, 1];
AS = [1, 2, 1];
SS = [1, 2, 1, 2, 1, 2];
validChrom = [OS, MS, AS, SS];
end

function expect_invalid_decoding(chrom, problem, machineData, agvData, config, ...
    expectedStatus, expectedMessage)
[~, report] = decode_chromosome(chrom, problem, machineData, agvData, config);
assert(~report.isValid, 'Expected decoding to be invalid.');
assert(strcmp(report.decodingStatus, expectedStatus), ...
    ['Expected decodingStatus ', expectedStatus, ...
    ', got ', report.decodingStatus, '.']);
assert_has_error(report, expectedMessage);
end

function assert_has_error(report, expectedMessage)
joinedErrors = strjoin(report.errors, newline);
assert(~isempty(strfind(joinedErrors, expectedMessage)), ...
    ['Expected error containing: ', expectedMessage, newline, ...
    'Actual errors:', newline, joinedErrors]);
end

function machineTable = create_initial_machine_table(machineNum)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = struct( ...
        'start', 0, ...
        'end', inf, ...
        'job', 0, ...
        'opera', 0);
end
end

function AGVTable = create_initial_agv_table(AGVNum)
AGVTable = cell(1, AGVNum);
for agvIdx = 1:AGVNum
    AGVTable{agvIdx} = repmat(struct( ...
        'start', 0, ...
        'end', 0, ...
        'job', 0, ...
        'opera', 0, ...
        'from_machine', -1, ...
        'to_machine', -1, ...
        'status', 0), 1, 2);
    AGVTable{agvIdx}(2).end = inf;
end
end
