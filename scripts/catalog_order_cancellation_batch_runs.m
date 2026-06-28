% Catalog batch run directories under outputs/batch_random_order_cancellation.

projectRoot = fileparts(fileparts(mfilename('fullpath')));

if ~exist('runsRoot', 'var') || isempty(runsRoot)
    runsRoot = fullfile('outputs', 'batch_random_order_cancellation');
end
if ~exist('maxRuns', 'var') || isempty(maxRuns)
    maxRuns = 20;
end
if ~exist('maxStrategyRows', 'var') || isempty(maxStrategyRows)
    maxStrategyRows = 10;
end

runsRoot = resolve_path(projectRoot, runsRoot);
if ~isfolder(runsRoot)
    error('catalog_order_cancellation_batch_runs:MissingRoot', ...
        'runsRoot not found: %s', runsRoot);
end

runDirs = list_run_dirs(runsRoot);
if isempty(runDirs)
    error('catalog_order_cancellation_batch_runs:NoRunDirs', ...
        'No batch run directories found under: %s', runsRoot);
end

csvPresent = false(size(runDirs));
for i = 1:numel(runDirs)
    csvPresent(i) = isfile(fullfile(runDirs(i).fullPath, 'batch_random_order_cancellation.csv'));
end

csvRunCount = sum(csvPresent);
missingCsvCount = numel(runDirs) - csvRunCount;

fprintf('catalog: catalog_order_cancellation_batch_runs\n');
fprintf('runs_root: %s\n', relative_path(projectRoot, runsRoot));
fprintf('run_dir_count: %d\n', numel(runDirs));
fprintf('csv_run_count: %d\n', csvRunCount);
fprintf('missing_csv_count: %d\n', missingCsvCount);
fprintf('listed_run_count: %d\n', min(maxRuns, numel(runDirs)));

listedDirs = runDirs(1:min(maxRuns, numel(runDirs)));
for i = 1:numel(listedDirs)
    runDir = listedDirs(i);
    csvPath = fullfile(runDir.fullPath, 'batch_random_order_cancellation.csv');
    fprintf('run_dir: %s\n', runDir.name);
    if ~isfile(csvPath)
        fprintf('  status: missing_csv\n');
        fprintf('  reason: missing batch_random_order_cancellation.csv\n');
        continue
    end

    [isValid, reason, results] = load_batch_csv(csvPath);
    if ~isValid
        fprintf('  status: invalid_csv\n');
        fprintf('  reason: %s\n', reason);
        continue
    end

    rowCount = height(results);
    feasibleMask = to_logical_mask(results.feasible);
    feasibleCount = sum(feasibleMask);
    feasibleRate = safe_ratio(feasibleCount, rowCount);
    strategyValues = normalize_text_column(results.strategy_policy);

    fprintf('  row_count: %d\n', rowCount);
    print_distribution('  strategy_policy', strategyValues, maxStrategyRows);
    fprintf('  feasible_count: %d\n', feasibleCount);
    fprintf('  feasible_rate: %.4f\n', feasibleRate);
    fprintf('  dataset_count: %d\n', numel(unique(normalize_text_column(results.dataset), 'stable')));
    fprintf('  cancel_time_count: %d\n', numel(unique(results.cancel_time)));
    fprintf('  seed_count: %d\n', numel(unique(results.seed)));
end

function runDirs = list_run_dirs(runsRoot)
entries = dir(runsRoot);
runDirs = struct('name', {}, 'fullPath', {}, 'datenum', {});
for i = 1:numel(entries)
    entry = entries(i);
    if ~entry.isdir || strcmp(entry.name, '.') || strcmp(entry.name, '..')
        continue
    end
    runDirs(end + 1).name = entry.name; %#ok<AGROW>
    runDirs(end).fullPath = fullfile(runsRoot, entry.name);
    runDirs(end).datenum = entry.datenum;
end

if isempty(runDirs)
    return
end

[~, order] = sort([runDirs.datenum], 'descend');
runDirs = runDirs(order);
end

function [isValid, reason, results] = load_batch_csv(csvPath)
isValid = false;
reason = '';
results = table();

requiredColumns = {'dataset', 'seed', 'cancel_time', ...
    'strategy_policy', 'feasible'};

try
    opts = detectImportOptions(csvPath, 'Delimiter', ',');
    results = readtable(csvPath, opts);
catch err
    reason = short_error_message(err);
    return
end

missingColumns = setdiff(requiredColumns, results.Properties.VariableNames);
if ~isempty(missingColumns)
    reason = ['missing required columns: ', strjoin(missingColumns, ', ')];
    return
end

isValid = true;
end

function text = short_error_message(err)
if isprop(err, 'message') && ~isempty(err.message)
    text = char(string(err.message));
else
    text = 'unable to read csv';
end

text = regexprep(text, '[\r\n]+', ' ');
if numel(text) > 120
    text = [text(1:117), '...'];
end
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

function print_distribution(label, values, maxRows)
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
limit = min(maxRows, numel(groups));
fprintf('%s:\n', label);
for i = 1:limit
    fprintf('  %s: %d\n', char(groups(i)), counts(i));
end
if numel(groups) > limit
    fprintf('  ...\n');
end
end

function ratio = safe_ratio(numerator, denominator)
if denominator == 0
    ratio = 0;
else
    ratio = numerator / denominator;
end
end

function pathText = resolve_path(projectRoot, value)
pathText = char(string(value));
if is_absolute_path(pathText)
    return
end
pathText = fullfile(projectRoot, pathText);
end

function tf = is_absolute_path(pathText)
pathText = char(string(pathText));
tf = (ispc && numel(pathText) >= 2 && pathText(2) == ':') || ...
    startsWith(pathText, '/') || startsWith(pathText, '\');
end

function text = relative_path(projectRoot, fullPath)
text = string(fullPath);
projectRoot = string(projectRoot);
text = strrep(text, '\', '/');
projectRoot = strrep(projectRoot, '\', '/');
if startsWith(lower(text), lower(projectRoot))
    text = extractAfter(text, strlength(projectRoot));
    if startsWith(text, '/')
        text = extractAfter(text, 1);
    end
end
text = char(text);
if isempty(text)
    text = '.';
end
end
