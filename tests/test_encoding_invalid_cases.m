clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'encoding'));

[problem, agvData, validChrom] = make_small_encoding_case();

expect_invalid(validChrom(1:end - 1), problem, agvData, ...
    'length must be at least');

chrom = validChrom;
chrom(1:3) = [1, 1, 1];
expect_invalid(chrom, problem, agvData, 'OS job 2 appears');

chrom = validChrom;
chrom(1:3) = [1, 2, 3];
expect_invalid(chrom, problem, agvData, 'OS job ids must be in');

chrom = validChrom;
chrom(1:3) = [1, 2, 1.5];
expect_invalid(chrom, problem, agvData, 'OS must contain integer');

chrom = validChrom;
chrom(4) = 3;
expect_invalid(chrom, problem, agvData, 'MS position 1');

problemWithEmptyCandidate = problem;
problemWithEmptyCandidate.candidateMachine{1, 2} = [];
expect_invalid(validChrom, problemWithEmptyCandidate, agvData, ...
    'candidateMachine{1,2} is empty');

chrom = validChrom;
chrom(7) = 0;
expect_invalid(chrom, problem, agvData, 'AS values must be in');

chrom = validChrom;
chrom(7) = agvData.AGVNum + 1;
expect_invalid(chrom, problem, agvData, 'AS values must be in');

chrom = validChrom;
chrom(10) = 0;
expect_invalid(chrom, problem, agvData, 'SS values must be in');

chrom = validChrom;
chrom(10) = numel(agvData.AGVSpeed) + 1;
expect_invalid(chrom, problem, agvData, 'SS values must be in');

invalidOSChrom = validChrom;
invalidOSChrom(1:3) = [1, 1, 1];
invalidMSChrom = validChrom;
invalidMSChrom(4) = 3;
population = [
    validChrom
    invalidOSChrom
    invalidMSChrom
];

populationReport = validate_population(population, problem, agvData);
assert(~populationReport.isValid, ...
    'Mixed population should not be fully valid.');
assert(populationReport.validCount == 1, ...
    'Mixed population validCount should be 1.');
assert(populationReport.invalidCount == 2, ...
    'Mixed population invalidCount should be 2.');
assert(isequal(populationReport.invalidIndexes, [2, 3]), ...
    'Mixed population invalidIndexes should be [2, 3].');
assert(populationReport.chromosomes(1).isValid, ...
    'Population row 1 should be valid.');
assert(~populationReport.chromosomes(2).isValid, ...
    'Population row 2 should be invalid.');
assert(~populationReport.chromosomes(3).isValid, ...
    'Population row 3 should be invalid.');

fprintf('test_encoding_invalid_cases passed\n');

function [problem, agvData, validChrom] = make_small_encoding_case()
problem = struct();
problem.jobNum = 2;
problem.operaNumVec = [2, 1];
problem.candidateMachine = cell(2, 2);
problem.candidateMachine{1, 1} = [1, 2];
problem.candidateMachine{1, 2} = [2];
problem.candidateMachine{2, 1} = [1, 3];

agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5];

OS = [1, 2, 1];
MS = [2, 1, 1];
AS = [1, 2, 1];
SS = [1, 2, 1, 2, 1, 2];
validChrom = [OS, MS, AS, SS];
end

function expect_invalid(chrom, problem, agvData, expectedMessage)
[isValid, report] = validate_chromosome(chrom, problem, agvData);
assert(~isValid, 'Expected chromosome to be invalid.');
assert_has_error(report, expectedMessage);
end

function assert_has_error(report, expectedMessage)
joinedErrors = strjoin(report.errors, newline);
assert(~isempty(strfind(joinedErrors, expectedMessage)), ...
    ['Expected error containing: ', expectedMessage, newline, ...
    'Actual errors:', newline, joinedErrors]);
end
