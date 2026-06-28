% Verify a random order cancellation batch CSV without running MATLAB jobs.

projectRoot = fileparts(fileparts(mfilename('fullpath')));

if ~exist('csvPath', 'var') || isempty(csvPath)
    csvPath = latest_batch_csv_path(projectRoot);
else
    csvPath = resolve_csv_path(projectRoot, csvPath);
end

if ~exist('expectedRowCount', 'var')
    expectedRowCount = [];
end
if ~exist('expectedStrategies', 'var')
    expectedStrategies = {};
end
if ~exist('maxFailureRows', 'var') || isempty(maxFailureRows)
    maxFailureRows = 10;
end

requiredColumns = {'dataset', 'seed', 'cancel_time', ...
    'strategy_policy', 'feasible', 'error_message'};
optionalColumns = {'complete_rescheduling_error', ...
    'complete_rescheduling_validation_probe', ...
    'complete_rescheduling_rejected_reason', ...
    'complete_rescheduling_error_count', ...
    'complete_rescheduling_rejected_count', ...
    'local_repair_status', 'local_repair_error'};

if ~isfile(csvPath)
    error('verify_order_cancellation_batch_csv:FileNotFound', ...
        'CSV not found: %s', csvPath);
end

opts = detectImportOptions(csvPath, 'Delimiter', ',');
results = readtable(csvPath, opts);

missingColumns = setdiff(requiredColumns, results.Properties.VariableNames);
if ~isempty(missingColumns)
    error('verify_order_cancellation_batch_csv:MissingColumns', ...
        'Missing required columns: %s', strjoin(missingColumns, ', '));
end

rowCount = height(results);
fprintf('verifier: verify_order_cancellation_batch_csv\n');
fprintf('csv_path: %s\n', csvPath);
fprintf('row_count: %d\n', rowCount);

if ~isempty(expectedRowCount)
    if ~isscalar(expectedRowCount) || ~isnumeric(expectedRowCount)
        error('verify_order_cancellation_batch_csv:InvalidExpectedRowCount', ...
            'expectedRowCount must be numeric scalar.');
    end
    if rowCount ~= expectedRowCount
        error('verify_order_cancellation_batch_csv:RowCountMismatch', ...
            'row_count mismatch: expected %d, got %d.', ...
            expectedRowCount, rowCount);
    end
    fprintf('expected_row_count: ok (%d)\n', expectedRowCount);
end

strategyValues = normalize_text_column(results.strategy_policy);
strategyNames = unique(strategyValues, 'stable');
if ~isempty(expectedStrategies)
    expectedStrategies = normalize_expected_strategies(expectedStrategies);
    unexpectedStrategies = setdiff(strategyNames, expectedStrategies, 'stable');
    if ~isempty(unexpectedStrategies)
        error('verify_order_cancellation_batch_csv:UnexpectedStrategies', ...
            'Unexpected strategies: %s', strjoin(unexpectedStrategies, ', '));
    end
end

print_distribution('strategy_policy', strategyValues, 10);

feasibleMask = to_logical_mask(results.feasible);
feasibleCount = sum(feasibleMask);
feasibleRate = safe_ratio(feasibleCount, rowCount);
fprintf('feasible_count: %d\n', feasibleCount);
fprintf('feasible_rate: %.4f\n', feasibleRate);

errorValues = normalize_text_column(results.error_message);
print_distribution('error_message', errorValues, 10);

for i = 1:numel(optionalColumns)
    columnName = optionalColumns{i};
    if ismember(columnName, results.Properties.VariableNames)
        print_distribution(columnName, normalize_text_column(results.(columnName)), 10);
    end
end

print_failure_samples(results, feasibleMask, maxFailureRows);

function csvPath = latest_batch_csv_path(projectRoot)
pattern = fullfile(projectRoot, 'outputs', 'batch_random_order_cancellation', ...
    '*', 'batch_random_order_cancellation.csv');
files = dir(pattern);
if isempty(files)
    error('verify_order_cancellation_batch_csv:NoCsvFound', ...
        'No batch_random_order_cancellation.csv found under outputs/batch_random_order_cancellation.');
end

[~, idx] = max([files.datenum]);
csvPath = fullfile(files(idx).folder, files(idx).name);
end

function csvPath = resolve_csv_path(projectRoot, value)
csvPath = char(string(value));
if is_absolute_path(csvPath)
    return
end

candidatePaths = {csvPath, fullfile(projectRoot, csvPath), fullfile(pwd, csvPath)};
for i = 1:numel(candidatePaths)
    if isfile(candidatePaths{i})
        csvPath = candidatePaths{i};
        return
    end
end
end

function tf = is_absolute_path(pathValue)
pathValue = char(string(pathValue));
tf = (ispc && numel(pathValue) >= 2 && pathValue(2) == ':') || ...
    startsWith(pathValue, filesep) || startsWith(pathValue, '/');
end

function values = normalize_text_column(column)
if iscell(column)
    values = string(column);
elseif isstring(column)
    values = column;
elseif iscategorical(column)
    values = string(column);
else
    values = string(column);
end

values = strtrim(values);
values(ismissing(values)) = "<empty>";
values(values == "") = "<empty>";
end

function strategies = normalize_expected_strategies(value)
if ischar(value) || isstring(value)
    strategies = string(value);
elseif iscell(value)
    strategies = string(value);
else
    error('verify_order_cancellation_batch_csv:InvalidExpectedStrategies', ...
        'expectedStrategies must be a cell array, char, or string.');
end

strategies = strtrim(strategies);
strategies = strategies(~ismissing(strategies) & strategies ~= "");
end

function tf = to_logical_mask(column)
if islogical(column)
    tf = column(:);
    return
end

if isnumeric(column)
    tf = column(:) ~= 0;
    return
end

values = lower(strtrim(string(column)));
tf = values == "true" | values == "1" | values == "yes";
end

function ratio = safe_ratio(numerator, denominator)
if denominator == 0
    ratio = 0;
else
    ratio = numerator / denominator;
end
end

function print_distribution(label, values, maxClasses)
if isempty(values)
    fprintf('%s_distribution: <empty>\n', label);
    return
end

groups = unique(values, 'stable');
counts = zeros(numel(groups), 1);
for i = 1:numel(groups)
    counts(i) = sum(values == groups(i));
end

[counts, order] = sort(counts, 'descend');
groups = groups(order);
limit = min(maxClasses, numel(groups));
fprintf('%s_distribution:\n', label);
for i = 1:limit
    fprintf('  %s: %d\n', char(groups(i)), counts(i));
end
if numel(groups) > limit
    fprintf('  ...\n');
end
end

function print_failure_samples(results, feasibleMask, maxFailureRows)
failureRows = find(~feasibleMask);
if isempty(failureRows)
    fprintf('failure_samples: none\n');
    return
end

limit = min(maxFailureRows, numel(failureRows));
fprintf('failure_samples: %d\n', limit);
for i = 1:limit
    row = results(failureRows(i), :);
    datasetName = leaf_name(row.dataset);
    fprintf('  %d) dataset=%s, seed=%s, cancel_time=%s, strategy=%s, feasible=%s, error_message=%s\n', ...
        i, datasetName, scalar_to_text(row.seed), scalar_to_text(row.cancel_time), ...
        scalar_to_text(row.strategy_policy), scalar_to_text(row.feasible), ...
        scalar_to_text(row.error_message));
end
end

function text = leaf_name(value)
text = char(string(value));
if isempty(text)
    text = '<empty>';
    return
end

[~, name, ext] = fileparts(text);
if isempty(name) && isempty(ext)
    return
end
text = [name, ext];
end

function text = scalar_to_text(value)
if iscell(value) && ~isempty(value)
    value = value{1};
end

if isstring(value)
    if isempty(value)
        text = '<empty>';
    else
        text = char(value(1));
    end
elseif ischar(value)
    if isempty(value)
        text = '<empty>';
    else
        text = value;
    end
elseif isnumeric(value) || islogical(value)
    if isscalar(value)
        text = char(string(value));
    else
        text = char(string(value(1)));
    end
else
    text = char(string(value));
end

text = strtrim(text);
if isempty(text)
    text = '<empty>';
end
end
