if ~exist('resultCsv', 'var') || isempty(resultCsv)
    error('summarize_random_order_cancellation_results:MissingResultCsv', ...
        ['Set resultCsv before running this script, for example:\n', ...
        'resultCsv = ''outputs/batch_random_order_cancellation/', ...
        '20260627_144555/batch_random_order_cancellation.csv'';']);
end

if ~ischar(resultCsv) && ~isstring(resultCsv)
    error('summarize_random_order_cancellation_results:InvalidResultCsv', ...
        'resultCsv must be a char or string scalar.');
end

scriptRoot = fileparts(fileparts(mfilename('fullpath')));
resultCsv = char(string(resultCsv));
candidatePaths = {resultCsv};
if ~is_absolute_path(resultCsv)
    candidatePaths{end + 1} = fullfile(scriptRoot, resultCsv);
    candidatePaths{end + 1} = fullfile(pwd, resultCsv);
end

resultCsv = '';
for i = 1:numel(candidatePaths)
    candidatePath = candidatePaths{i};
    if isfile(candidatePath)
        resultCsv = candidatePath;
        break
    end
end

if isempty(resultCsv)
    error('summarize_random_order_cancellation_results:FileNotFound', ...
        'Result CSV not found: %s', char(string(candidatePaths{1})));
end

resultDir = fileparts(resultCsv);
outputByStrategyPolicy = fullfile(resultDir, 'summary_by_strategy_policy.csv');
outputByDatasetStrategyPolicy = fullfile(resultDir, ...
    'summary_by_dataset_strategy_policy.csv');
outputBySelectedStrategy = fullfile(resultDir, 'summary_selected_strategy.csv');
outputByErrorMessage = fullfile(resultDir, 'summary_error_messages.csv');
outputNotes = fullfile(resultDir, 'summary_notes.txt');

[results, notes] = read_result_table(resultCsv);

summaryByStrategyPolicy = summarize_by_group(results, {'strategy_policy'});
summaryByDatasetStrategyPolicy = summarize_by_group(results, ...
    {'dataset', 'strategy_policy'});
summarySelectedStrategy = summarize_selected_strategy(results);
summaryErrorMessages = summarize_error_messages(results);

writetable(summaryByStrategyPolicy, outputByStrategyPolicy);
writetable(summaryByDatasetStrategyPolicy, outputByDatasetStrategyPolicy);
writetable(summarySelectedStrategy, outputBySelectedStrategy);
writetable(summaryErrorMessages, outputByErrorMessage);
write_text(outputNotes, build_notes(resultCsv, resultDir, notes, results));

fprintf('summary_by_strategy_policy_csv: %s\n', outputByStrategyPolicy);
fprintf('summary_by_dataset_strategy_policy_csv: %s\n', ...
    outputByDatasetStrategyPolicy);
fprintf('summary_selected_strategy_csv: %s\n', outputBySelectedStrategy);
fprintf('summary_error_messages_csv: %s\n', outputByErrorMessage);
fprintf('summary_notes_txt: %s\n', outputNotes);

function [results, notes] = read_result_table(resultCsv)
opts = detectImportOptions(resultCsv, 'Delimiter', ',');
results = readtable(resultCsv, opts);
notes = {};

requiredColumns = {'dataset', 'strategy_policy', 'selected_strategy', ...
    'error_message', 'run_through', 'feasible'};
for i = 1:numel(requiredColumns)
    columnName = requiredColumns{i};
    if ~ismember(columnName, results.Properties.VariableNames)
        notes{end + 1} = sprintf('Missing column: %s', columnName);
    end
end

metricColumns = {'Cmax_delta', 'SD', 'TD', 'Y'};
for i = 1:numel(metricColumns)
    columnName = metricColumns{i};
    if ~ismember(columnName, results.Properties.VariableNames)
        notes{end + 1} = sprintf('Metric column missing: %s', columnName);
    end
end
end

function summary = summarize_by_group(results, groupColumns)
if isempty(results)
    summary = table();
    return
end

groupValues = build_group_values(results, groupColumns);
groupNames = unique(groupValues, 'stable');
rows = repmat(empty_summary_row(groupColumns), 1, numel(groupNames));

for i = 1:numel(groupNames)
    mask = strcmp(groupValues, groupNames{i});
    rows(i) = build_summary_row(results(mask, :), groupColumns, groupNames{i});
end

summary = struct2table(rows);
end

function summary = summarize_selected_strategy(results)
if ~ismember('selected_strategy', results.Properties.VariableNames)
    summary = table();
    return
end

labels = normalize_text_column(results.selected_strategy);
summary = summarize_count_table(labels, 'selected_strategy');
end

function summary = summarize_error_messages(results)
if ~ismember('error_message', results.Properties.VariableNames)
    summary = table();
    return
end

labels = normalize_text_column(results.error_message);
summary = summarize_count_table(labels, 'error_message');
end

function summary = summarize_count_table(labels, fieldName)
if isempty(labels)
    summary = table();
    return
end

labels = normalize_empty_labels(labels);
groupNames = unique(labels, 'stable');
counts = zeros(numel(groupNames), 1);
rates = zeros(numel(groupNames), 1);
totalCount = numel(labels);

for i = 1:numel(groupNames)
    counts(i) = sum(strcmp(labels, groupNames{i}));
    rates(i) = safe_ratio(counts(i), totalCount);
end

summary = table(groupNames(:), counts, rates, ...
    'VariableNames', {fieldName, 'count', 'rate'});
end

function row = build_summary_row(results, groupColumns, groupValue)
row = empty_summary_row(groupColumns);
if numel(groupColumns) == 1
    row.(groupColumns{1}) = groupValue;
else
    parts = strsplit(groupValue, '||');
    for i = 1:numel(groupColumns)
        row.(groupColumns{i}) = parts{i};
    end
end

row.row_count = height(results);
row.run_through_count = count_true(results, 'run_through');
row.run_through_rate = safe_ratio(row.run_through_count, row.row_count);
row.fail_count = row.row_count - row.run_through_count;
row.fail_rate = safe_ratio(row.fail_count, row.row_count);
row.feasible_count = count_true(results, 'feasible');
row.feasible_rate = safe_ratio(row.feasible_count, row.row_count);

metricColumns = {'Cmax_delta', 'SD', 'TD', 'Y'};
for i = 1:numel(metricColumns)
    metricName = metricColumns{i};
    [countValue, meanValue, stdValue, minValue, maxValue] = ...
        summarize_metric(results, metricName);
    row.([metricName, '_count']) = countValue;
    row.([metricName, '_mean']) = meanValue;
    row.([metricName, '_std']) = stdValue;
    row.([metricName, '_min']) = minValue;
    row.([metricName, '_max']) = maxValue;
end
end

function [countValue, meanValue, stdValue, minValue, maxValue] = ...
    summarize_metric(results, metricName)
if ~ismember(metricName, results.Properties.VariableNames)
    countValue = 0;
    meanValue = NaN;
    stdValue = NaN;
    minValue = NaN;
    maxValue = NaN;
    return
end

values = results.(metricName);
if iscell(values) || isstring(values)
    values = str2double(string(values));
end
if islogical(values)
    values = double(values);
end

values = values(:);
validMask = isfinite(values);
values = values(validMask);

countValue = numel(values);
if isempty(values)
    meanValue = NaN;
    stdValue = NaN;
    minValue = NaN;
    maxValue = NaN;
    return
end

meanValue = mean(values);
if numel(values) > 1
    stdValue = std(values);
else
    stdValue = 0;
end
minValue = min(values);
maxValue = max(values);
end

function count = count_true(results, fieldName)
if ~ismember(fieldName, results.Properties.VariableNames)
    count = 0;
    return
end
value = results.(fieldName);
if iscell(value)
    count = sum(strcmpi(normalize_text_column(value), 'true')) + ...
        sum(strcmpi(normalize_text_column(value), '1'));
elseif islogical(value)
    count = sum(value);
elseif isnumeric(value)
    count = sum(value ~= 0);
else
    count = 0;
end
end

function values = build_group_values(results, groupColumns)
values = cell(height(results), 1);
for i = 1:height(results)
    parts = cell(1, numel(groupColumns));
    for j = 1:numel(groupColumns)
        columnName = groupColumns{j};
        parts{j} = value_to_text(results.(columnName)(i));
    end
    values{i} = strjoin(parts, '||');
end
end

function row = empty_summary_row(groupColumns)
row = struct();
for i = 1:numel(groupColumns)
    row.(groupColumns{i}) = '';
end
row.row_count = 0;
row.run_through_count = 0;
row.run_through_rate = 0;
row.fail_count = 0;
row.fail_rate = 0;
row.feasible_count = 0;
row.feasible_rate = 0;
metricColumns = {'Cmax_delta', 'SD', 'TD', 'Y'};
for i = 1:numel(metricColumns)
    metricName = metricColumns{i};
    row.([metricName, '_count']) = 0;
    row.([metricName, '_mean']) = NaN;
    row.([metricName, '_std']) = NaN;
    row.([metricName, '_min']) = NaN;
    row.([metricName, '_max']) = NaN;
end
end

function text = value_to_text(value)
if iscell(value)
    if isempty(value)
        text = '';
    else
        text = char(string(value{1}));
    end
elseif isstring(value)
    if isempty(value)
        text = '';
    else
        text = char(value(1));
    end
elseif ischar(value)
    text = value;
elseif isnumeric(value)
    if isempty(value)
        text = '';
    else
        text = num2str(value(1));
    end
elseif islogical(value)
    text = char(string(double(value(1))));
else
    text = char(string(value));
end
end

function labels = normalize_text_column(value)
if iscell(value)
    labels = cell(size(value));
    for i = 1:numel(value)
        labels{i} = char(string(value{i}));
    end
elseif isstring(value)
    labels = cellstr(value);
elseif ischar(value)
    labels = cellstr(value);
elseif isnumeric(value)
    labels = cell(size(value));
    for i = 1:numel(value)
        labels{i} = num2str(value(i));
    end
else
    labels = cell(size(value));
    for i = 1:numel(value)
        labels{i} = char(string(value(i)));
    end
end
labels = strtrim(labels);
end

function labels = normalize_empty_labels(labels)
for i = 1:numel(labels)
    if isempty(labels{i}) || all(isspace(labels{i}))
        labels{i} = '<empty>';
    end
end
end

function text = build_notes(resultCsv, resultDir, notes, results)
lines = {};
lines{end + 1} = 'Random order cancellation summary';
lines{end + 1} = '';
lines{end + 1} = sprintf('Source CSV: %s', resultCsv);
lines{end + 1} = sprintf('Output directory: %s', resultDir);
lines{end + 1} = sprintf('Input row count: %d', height(results));
lines{end + 1} = '';
lines{end + 1} = 'Outputs:';
lines{end + 1} = 'summary_by_strategy_policy.csv';
lines{end + 1} = 'summary_by_dataset_strategy_policy.csv';
lines{end + 1} = 'summary_selected_strategy.csv';
lines{end + 1} = 'summary_error_messages.csv';
lines{end + 1} = '';

if isempty(notes)
    lines{end + 1} = 'Missing columns: none';
else
    lines{end + 1} = 'Missing columns:';
    for i = 1:numel(notes)
        lines{end + 1} = notes{i};
    end
end

text = strjoin(lines, newline);
end

function write_text(filePath, text)
fid = fopen(filePath, 'w');
if fid < 0
    error('summarize_random_order_cancellation_results:FileOpenFailed', ...
        'Cannot open file for writing: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
clear cleanup
end

function value = safe_ratio(numerator, denominator)
if denominator <= 0
    value = 0;
else
    value = numerator / denominator;
end
end

function tf = is_absolute_path(pathValue)
pathValue = char(string(pathValue));
tf = ~isempty(regexp(pathValue, '^[A-Za-z]:[\\/]', 'once')) || ...
    startsWith(pathValue, '\\') || startsWith(pathValue, '/');
end
