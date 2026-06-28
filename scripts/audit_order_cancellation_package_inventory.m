% Audit the order cancellation package inventory.

projectRoot = fileparts(fileparts(mfilename('fullpath')));

if ~exist('maxFileRows', 'var') || isempty(maxFileRows)
    maxFileRows = 20;
end
if ~exist('includeDocs', 'var') || isempty(includeDocs)
    includeDocs = true;
end

srcRoot = fullfile(projectRoot, 'src', 'cancellation');
scriptsRoot = fullfile(projectRoot, 'scripts');
docsRoot = fullfile(projectRoot, 'docs', 'repro');

fprintf('audit: audit_order_cancellation_package_inventory\n');

srcStats = scan_text_section(srcRoot, '*.m', @is_cancellation_src_file, ...
    maxFileRows, 'cancellation_src');
scriptStats = scan_text_section(scriptsRoot, '*.m', @is_cancellation_script_file, ...
    maxFileRows, 'cancellation_script');
if includeDocs
    docStats = scan_text_section(docsRoot, '*.md', @is_cancellation_doc_file, ...
        maxFileRows, 'cancellation_doc');
else
    docStats = empty_section_stats('cancellation_doc');
    fprintf('warning: docs scan skipped\n');
end

fprintf('cancellation_src_file_count: %d\n', srcStats.fileCount);
fprintf('cancellation_src_line_count: %d\n', srcStats.lineCount);
fprintf('cancellation_src_nonempty_line_count: %d\n', srcStats.nonEmptyLineCount);
fprintf('cancellation_script_file_count: %d\n', scriptStats.fileCount);
fprintf('cancellation_script_line_count: %d\n', scriptStats.lineCount);
fprintf('cancellation_script_nonempty_line_count: %d\n', scriptStats.nonEmptyLineCount);
fprintf('cancellation_doc_file_count: %d\n', docStats.fileCount);
fprintf('cancellation_doc_line_count: %d\n', docStats.lineCount);
fprintf('cancellation_doc_nonempty_line_count: %d\n', docStats.nonEmptyLineCount);
fprintf('package_total_file_count: %d\n', ...
    srcStats.fileCount + scriptStats.fileCount + docStats.fileCount);
fprintf('package_total_line_count: %d\n', ...
    srcStats.lineCount + scriptStats.lineCount + docStats.lineCount);

function stats = scan_text_section(rootDir, pattern, predicateFn, maxFileRows, label)
stats = empty_section_stats(label);
if ~isfolder(rootDir)
    fprintf('warning: missing %s\n', relative_path(rootDir));
    return
end

files = collect_files(rootDir, pattern, predicateFn);
if isempty(files)
    fprintf('warning: no files in %s\n', relative_path(rootDir));
    return
end

stats.fileCount = numel(files);
stats.lineCount = sum([files.lineCount]);
stats.nonEmptyLineCount = sum([files.nonEmptyLineCount]);
stats.moduleDistribution = summarize_module_distribution(files);
stats.files = sort_files_by_line_count(files);

print_section_summary(label, stats, maxFileRows);
end

function stats = empty_section_stats(label)
stats = struct();
stats.label = label;
stats.fileCount = 0;
stats.lineCount = 0;
stats.nonEmptyLineCount = 0;
stats.moduleDistribution = struct('module', {}, 'fileCount', {});
stats.files = struct('relPath', {}, 'lineCount', {}, 'nonEmptyLineCount', {}, 'module', {});
end

function files = collect_files(rootDir, pattern, predicateFn)
entries = dir(fullfile(rootDir, '**', pattern));
files = struct('relPath', {}, 'lineCount', {}, 'nonEmptyLineCount', {}, 'module', {});
for i = 1:numel(entries)
    entry = entries(i);
    if entry.isdir
        continue
    end

    relPath = relative_path(fullfile(entry.folder, entry.name));
    if ~predicateFn(relPath, entry.name)
        continue
    end

    [lineCount, nonEmptyLineCount] = read_text_file_stats(fullfile(entry.folder, entry.name));
    files(end + 1).relPath = relPath; %#ok<AGROW>
    files(end).lineCount = lineCount;
    files(end).nonEmptyLineCount = nonEmptyLineCount;
    files(end).module = classify_module(relPath, entry.name);
end
end

function [lineCount, nonEmptyLineCount] = read_text_file_stats(filePath)
try
    text = fileread(filePath);
catch
    lineCount = 0;
    nonEmptyLineCount = 0;
    return
end

if isempty(text)
    lineCount = 0;
    nonEmptyLineCount = 0;
    return
end

parts = regexp(text, '\r\n|\n|\r', 'split');
if isempty(parts)
    lineCount = 0;
else
    lineCount = numel(parts);
    if isempty(parts{end})
        lineCount = lineCount - 1;
    end
end

nonEmptyLineCount = sum(~cellfun(@isempty, strtrim(parts)));
if lineCount < 0
    lineCount = 0;
end
end

function files = sort_files_by_line_count(files)
if isempty(files)
    return
end

[~, order] = sort([files.lineCount], 'descend');
files = files(order);
end

function distribution = summarize_module_distribution(files)
if isempty(files)
    distribution = struct('module', {}, 'fileCount', {});
    return
end

modules = string({files.module});
uniqueModules = unique(modules, 'stable');
counts = zeros(numel(uniqueModules), 1);
for i = 1:numel(uniqueModules)
    counts(i) = sum(modules == uniqueModules(i));
end

[counts, order] = sort(counts, 'descend');
uniqueModules = uniqueModules(order);
distribution = struct('module', cell(numel(uniqueModules), 1), ...
    'fileCount', cell(numel(uniqueModules), 1));
for i = 1:numel(uniqueModules)
    distribution(i).module = char(uniqueModules(i));
    distribution(i).fileCount = counts(i);
end
end

function print_section_summary(label, stats, maxFileRows)
fprintf('%s_file_count: %d\n', label, stats.fileCount);
fprintf('%s_line_count: %d\n', label, stats.lineCount);
fprintf('%s_nonempty_line_count: %d\n', label, stats.nonEmptyLineCount);
fprintf('%s_module_distribution:\n', label);
print_module_distribution(stats.moduleDistribution, 10);
fprintf('%s_top_files:\n', label);
print_top_files(stats.files, maxFileRows);
end

function print_module_distribution(distribution, maxRows)
if isempty(distribution)
    fprintf('none\n');
    return
end

limit = min(maxRows, numel(distribution));
for i = 1:limit
    fprintf('  %s: %d\n', distribution(i).module, distribution(i).fileCount);
end
if numel(distribution) > limit
    fprintf('  ...\n');
end
end

function print_top_files(files, maxRows)
if isempty(files)
    fprintf('none\n');
    return
end

if iscell(files)
    files = [files{:}];
end

limit = min(maxRows, numel(files));
for i = 1:limit
    fprintf('  %s | lines=%d | nonempty=%d | module=%s\n', ...
        files(i).relPath, files(i).lineCount, files(i).nonEmptyLineCount, files(i).module);
end
if numel(files) > limit
    fprintf('  ...\n');
end
end

function tf = is_cancellation_src_file(~, name)
tf = endsWith(lower(name), '.m');
end

function tf = is_cancellation_script_file(~, name)
lowerName = lower(name);
tf = endsWith(lowerName, '.m') && (contains(lowerName, 'order_cancellation') || ...
    contains(lowerName, 'cancellation') || ...
    contains(lowerName, 'batch_random_order_cancellation'));
end

function tf = is_cancellation_doc_file(~, name)
lowerName = lower(name);
tf = endsWith(lowerName, '.md') && (contains(lowerName, 'order_cancellation') || ...
    contains(lowerName, 'cancellation'));
end

function moduleName = classify_module(relPath, name)
stem = name;
[~, stem] = fileparts(stem);
tokens = regexp(stem, '_', 'split');
if numel(tokens) >= 2 && strcmp(tokens{1}, 'order') && strcmp(tokens{2}, 'cancellation')
    moduleName = 'order_cancellation';
    return
end

if ~isempty(tokens) && ~isempty(tokens{1})
    moduleName = tokens{1};
else
    moduleName = stem;
end

if isempty(moduleName)
    moduleName = relative_leaf(relPath);
end
end

function text = relative_path(fullPath)
text = char(string(fullPath));
projectRoot = fileparts(fileparts(mfilename('fullpath')));
projectRoot = strrep(projectRoot, '\', '/');
text = strrep(text, '\', '/');
if startsWith(lower(text), lower(projectRoot))
    text = extractAfter(string(text), numel(projectRoot));
    text = char(text);
    if startsWith(text, '/')
        text = extractAfter(text, 1);
        text = char(text);
    end
end
end

function text = relative_leaf(relPath)
[~, text, ext] = fileparts(relPath);
text = [text, ext];
end
