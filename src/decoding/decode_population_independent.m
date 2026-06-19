function [schedules, report] = decode_population_independent(population, problem, machineData, agvData, config)
%DECODE_POPULATION_INDEPENDENT Decode a population without raw sorting.m.

if nargin < 5
    error('decode_population_independent:MissingInput', ...
        'population, problem, machineData, agvData, and config are required.');
end

if ~ismatrix(population) || isempty(population)
    error('decode_population_independent:InvalidPopulation', ...
        'population must be a non-empty matrix.');
end

populationSize = size(population, 1);
schedules = cell(populationSize, 1);

report = struct();
report.populationSize = populationSize;
report.chromosomeLength = size(population, 2);
report.successCount = 0;
report.failureCount = 0;
report.failedIndexes = [];
report.isValid = true;
report.chromosomes = repmat(struct( ...
    'index', [], ...
    'isValid', [], ...
    'decodingStatus', '', ...
    'errors', {{}}, ...
    'warnings', {{}}), populationSize, 1);

for i = 1:populationSize
    try
        [schedule, chromReport] = decode_chromosome_independent( ...
            population(i, :), problem, machineData, agvData, config);
    catch err
        schedule = [];
        chromReport = struct();
        chromReport.isValid = false;
        chromReport.decodingStatus = 'decode-chromosome-independent-error';
        chromReport.errors = {err.message};
        chromReport.warnings = {};
    end

    schedules{i} = schedule;
    report.chromosomes(i).index = i;
    report.chromosomes(i).isValid = chromReport.isValid;
    report.chromosomes(i).decodingStatus = chromReport.decodingStatus;
    report.chromosomes(i).errors = chromReport.errors;
    report.chromosomes(i).warnings = chromReport.warnings;

    if chromReport.isValid
        report.successCount = report.successCount + 1;
    else
        report.failureCount = report.failureCount + 1;
        report.failedIndexes(end + 1) = i;
        report.isValid = false;
    end
end
end
