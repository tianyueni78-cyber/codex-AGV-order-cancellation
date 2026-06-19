function report = validate_population(population, problem, agvData)
%VALIDATE_POPULATION Validate every chromosome in a population.
%   report = VALIDATE_POPULATION(population, problem, agvData) calls
%   validate_chromosome for each row of population and summarizes valid and
%   invalid chromosome counts.
%
%   This function only checks encoding validity. It does not decode
%   schedules, call fitness, run NSGA-II, or write outputs.

if nargin < 3
    error('validate_population:MissingInput', ...
        'population, problem, and agvData are required.');
end

if ~ismatrix(population) || isempty(population)
    error('validate_population:InvalidPopulation', ...
        'population must be a non-empty matrix.');
end

report = struct();
report.populationSize = size(population, 1);
report.chromosomeLength = size(population, 2);
report.validCount = 0;
report.invalidCount = 0;
report.invalidIndexes = [];
report.isValid = true;
report.chromosomes = repmat(struct( ...
    'index', [], ...
    'isValid', [], ...
    'errors', {{}}, ...
    'warnings', {{}}), report.populationSize, 1);

for i = 1:report.populationSize
    [isValid, chromReport] = validate_chromosome( ...
        population(i, :), problem, agvData);

    report.chromosomes(i).index = i;
    report.chromosomes(i).isValid = isValid;
    report.chromosomes(i).errors = chromReport.errors;
    report.chromosomes(i).warnings = chromReport.warnings;

    if isValid
        report.validCount = report.validCount + 1;
    else
        report.invalidCount = report.invalidCount + 1;
        report.invalidIndexes(end + 1) = i;
        report.isValid = false;
    end
end
end
