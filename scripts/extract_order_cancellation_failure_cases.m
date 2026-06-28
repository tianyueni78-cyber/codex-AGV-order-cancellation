% Extract failure cases and failure distributions from a batch CSV.

projectRoot = fileparts(fileparts(mfilename('fullpath')));

if ~exist('csvPath', 'var') || isempty(csvPath)
    csvPath = latest_batch_csv_path(projectRoot);
else
    csvPath = resolve_csv_path(projectRoot, csvPath);
end
if ~exist('maxFailureRows', 'var') || isempty(maxFailureRows)
    maxFailureRows = 20;
end
if ~exist('maxGroupRows', 'var') || isempty(maxGroupRows)
    maxGroupRows = 10;
end
if ~exist('writeFailureCsv', 'var') || isempty(writeFailureCsv)
    writeFailureCsv = false;
end
if ~exist('outputPath', 'var')
    outputPath = '';
end

requiredColumns = {'dataset', 'seed', 'cancel_time', ...
    'strategy_policy', 'feasible', 'error_message'};

if ~isfile(csvPath)
    error('extract_order_cancellation_failure_cases:FileNotFound', ...
        'CSV not found: %s', csvPath);
end

opts = detectImportOptions(csvPath, 'Delimiter', ',');
results = readtable(csvPath, opts);

missingColumns = setdiff(requiredColumns, results.Properties.VariableNames);
if ~isempty(missingColumns)
    error('extract_order_cancellation_failure_cases:MissingColumns', ...
        'Missing required columns: %s', strjoin(missingColumns, ', '));
end

rowCount = height(results);
feasibleMask = to_logical_mask(results.feasible);
failureMask = ~feasibleMask;
failureCount = sum(failureMask);
failureRate = safe_ratio(failureCount, rowCount);

fprintf('extractor: extract_order_cancellation_failure_cases\n');
fprintf('csv_path: %s\n', csvPath);
fprintf('row_count: %d\n', rowCount);
fprintf('failure_count: %d\n', failureCount);
fprintf('failure_rate: %.4f\n', failureRate);

failureRows = results(failureMask, :);

print_distribution('failure_by_strategy', normalize_text_column(failureRows.strategy_policy), maxGroupRows);
print_distribution('failure_by_dataset', file_leaf_column(failureRows.dataset), maxGroupRows);
print_distribution('failure_by_error_message', normalize_text_column(failureRows.error_message), maxGroupRows);
if ismember('complete_rescheduling_error', results.Properties.VariableNames)
    print_distribution('failure_by_complete_rescheduling_error', ...
        normalize_text_column(failureRows.complete_rescheduling_error), maxGroupRows);
end

if failureCount == 0
    fprintf('failure_cases: none\n');
    return
end

fprintf('failure_cases:\n');
print_failure_rows(failureRows, maxFailureRows);

if writeFailureCsv
    failureCsvPath = resolve_output_path(projectRoot, outputPath);
    failureDir = fileparts(failureCsvPath);
    if ~exist(failureDir, 'dir')
        mkdir(failureDir);
    end

    failureTable = table();
    failureTable.dataset = file_leaf_column(failureRows.dataset);
    failureTable.seed = failureRows.seed;
    failureTable.cancel_time = failureRows.cancel_time;
    failureTable.strategy_policy = failureRows.strategy_policy;
    failureTable.feasible = failureRows.feasible;
    failureTable.error_message = failureRows.error_message;
    writetable(failureTable, failureCsvPath);
    fprintf('failure_csv: %s\n', failureCsvPath);
end

function csvPath = latest_batch_csv_path(projectRoot)
pattern = fullfile(projectRoot, 'outputs', 'batch_random_order_cancellation', ...
    '*', 'batch_random_order_cancellation.csv');
files = dir(pattern);
if isempty(files)
    error('extract_order_cancellation_failure_cases:NoCsvFound', ...
        'No batch_random_order_cancellation.csv found.');
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

function outputCsv = resolve_output_path(projectRoot, outputPath)
if ~exist('outputPath', 'var') || isempty(outputPath)
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    outputCsv = fullfile(projectRoot, 'outputs', 'order_cancellation_failure_cases', ...
        timestamp, 'failure_cases.csv');
    return
end

outputPath = char(string(outputPath));
if endsWith(lower(outputPath), '.csv')
    outputCsv = outputPath;
else
    outputCsv = fullfile(outputPath, 'failure_cases.csv');
end

if ~is_absolute_path(outputCsv)
    outputCsv = fullfile(projectRoot, outputCsv);
end
end

function tf = is_absolute_path(pathValue)
pathValue = char(string(pathValue));
tf = (ispc && numel(pathValue) >= 2 && pathValue(2) == ':') || ...
    startsWith(pathValue, '/') || startsWith(pathValue, '\');
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
values(ismissing(values)) = "false";
tf = values == "true" | values == "1" | values == "yes";
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

function values = file_leaf_column(column)
values = normalize_text_column(column);
for i = 1:numel(values)
    values(i) = leaf_name(values(i));
end
end

function print_distribution(label, values, maxGroupRows)
if isempty(values)
    fprintf('%s: none\n', label);
    return
end

groups = unique(values, 'stable');
counts = zeros(numel(groups), 1);
for i = 1:numel(groups)
    counts(i) = sum(values == groups(i));
end

[counts, order] = sort(counts, 'descend');
groups = groups(order);
limit = min(maxGroupRows, numel(groups));
fprintf('%s:\n', label);
for i = 1:limit
    fprintf('  %s: %d\n', char(groups(i)), counts(i));
end
if numel(groups) > limit
    fprintf('  ...\n');
end
end

function print_failure_rows(failureRows, maxFailureRows)
limit = min(maxFailureRows, height(failureRows));
for i = 1:limit
    fprintf('  %d) dataset=%s, seed=%s, cancel_time=%s, strategy_policy=%s, feasible=%s, error_message=%s\n', ...
        i, leaf_name(failureRows.dataset(i)), scalar_to_text(failureRows.seed(i)), ...
        scalar_to_text(failureRows.cancel_time(i)), scalar_to_text(failureRows.strategy_policy(i)), ...
        scalar_to_text(failureRows.feasible(i)), scalar_to_text(failureRows.error_message(i)));
end
if height(failureRows) > limit
    fprintf('  ...\n');
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

function ratio = safe_ratio(numerator, denominator)
if denominator == 0
    ratio = 0;
else
    ratio = numerator / denominator;
end
end
