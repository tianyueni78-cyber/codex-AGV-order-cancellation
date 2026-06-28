% Scan order cancellation dataset coverage under raw_code/fjsp.

projectRoot = fileparts(fileparts(mfilename('fullpath')));

if ~exist('datasetRoot', 'var') || isempty(datasetRoot)
    datasetRoot = fullfile('raw_code', 'fjsp');
end
if ~exist('knownSmokeDatasets', 'var') || isempty(knownSmokeDatasets)
    knownSmokeDatasets = {
        'raw_code/fjsp/Brandimarte_Data/Mk01.fjs'
        'raw_code/fjsp/Barnes/mt10c1.fjs'
        'raw_code/fjsp/Barnes/setb4c9.fjs'
        'raw_code/fjsp/Dauzere_Data/01a.fjs'
        'raw_code/fjsp/Dauzere_Data/09a.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk02.fjs'
        'raw_code/fjsp/Brandimarte_Data/Mk03.fjs'
        'raw_code/fjsp/Barnes/mt10x.fjs'
        'raw_code/fjsp/Barnes/seti5x.fjs'
        'raw_code/fjsp/Dauzere_Data/02a.fjs'
        'raw_code/fjsp/Dauzere_Data/15a.fjs'
    };
end
if ~exist('maxListRows', 'var') || isempty(maxListRows)
    maxListRows = 30;
end

datasetRoot = resolve_root_path(projectRoot, datasetRoot);
if ~isfolder(datasetRoot)
    error('scan_order_cancellation_dataset_coverage:MissingRoot', ...
        'datasetRoot not found: %s', datasetRoot);
end

fjsFiles = collect_fjs_files(datasetRoot);
if isempty(fjsFiles)
    error('scan_order_cancellation_dataset_coverage:NoFjsFiles', ...
        'No .fjs files found under: %s', datasetRoot);
end

knownSmokeDatasets = normalize_text_list(knownSmokeDatasets);
knownSmokeFullPaths = cell(size(knownSmokeDatasets));
for i = 1:numel(knownSmokeDatasets)
    knownSmokeFullPaths{i} = resolve_root_path(projectRoot, knownSmokeDatasets{i});
end

filePaths = {fjsFiles.fullPath};
fileRelPaths = cellfun(@(p) relative_path(projectRoot, p), filePaths, ...
    'UniformOutput', false);
parentDirs = cell(size(filePaths));
for i = 1:numel(filePaths)
    parentDirs{i} = parent_directory_relative(projectRoot, filePaths{i});
end

knownSmokeFound = false(size(knownSmokeFullPaths));
for i = 1:numel(knownSmokeFullPaths)
    knownSmokeFound(i) = any(strcmpi(normalize_path(filePaths), ...
        normalize_path({knownSmokeFullPaths{i}})));
end

directoryNames = unique(parentDirs, 'stable');
directoryCounts = zeros(numel(directoryNames), 1);
for i = 1:numel(directoryNames)
    directoryCounts(i) = sum(strcmp(parentDirs, directoryNames{i}));
end

foundCount = sum(knownSmokeFound);
missingCount = numel(knownSmokeFound) - foundCount;
coverageRate = safe_ratio(foundCount, numel(knownSmokeFound));

fprintf('scanner: scan_order_cancellation_dataset_coverage\n');
fprintf('root_dir: %s\n', relative_path(projectRoot, datasetRoot));
fprintf('total_fjs_count: %d\n', numel(fjsFiles));
fprintf('directory_count: %d\n', numel(directoryNames));
fprintf('directory_distribution:\n');
for i = 1:numel(directoryNames)
    fprintf('%s: %d\n', directoryNames{i}, directoryCounts(i));
end
fprintf('known_smoke_count: %d\n', numel(knownSmokeDatasets));
fprintf('known_smoke_found_count: %d\n', foundCount);
fprintf('known_smoke_missing_count: %d\n', missingCount);
fprintf('coverage_rate: %.4f\n', coverageRate);

fprintf('known_smoke_datasets:\n');
print_limited_list(knownSmokeDatasets, knownSmokeFound, maxListRows);

fprintf('missing_smoke_datasets:\n');
if missingCount == 0
    fprintf('none\n');
else
    print_limited_list(knownSmokeDatasets(~knownSmokeFound), true(1, missingCount), maxListRows);
end

function files = collect_fjs_files(rootDir)
files = struct('fullPath', {}, 'name', {});
stack = {rootDir};
while ~isempty(stack)
    currentDir = stack{end};
    stack(end) = [];
    entries = dir(currentDir);
    for i = 1:numel(entries)
        entry = entries(i);
        if entry.isdir
            if strcmp(entry.name, '.') || strcmp(entry.name, '..')
                continue
            end
            stack{end + 1} = fullfile(currentDir, entry.name);
        elseif endsWith(lower(entry.name), '.fjs')
            files(end + 1).fullPath = fullfile(currentDir, entry.name); %#ok<AGROW>
            files(end).name = entry.name;
        end
    end
end
end

function pathText = resolve_root_path(projectRoot, value)
pathText = char(string(value));
if is_absolute_path(pathText)
    pathText = normalize_slashes(pathText);
else
    pathText = fullfile(projectRoot, pathText);
end
end

function tf = is_absolute_path(pathText)
pathText = char(string(pathText));
tf = (ispc && numel(pathText) >= 2 && pathText(2) == ':') || ...
    startsWith(pathText, '/') || startsWith(pathText, '\');
end

function text = relative_path(projectRoot, fullPath)
text = normalize_slashes(fullPath);
projectRoot = normalize_slashes(projectRoot);
if startsWith(lower(text), lower(projectRoot))
    text = extractAfter(text, strlength(projectRoot));
    if startsWith(text, '/')
        text = extractAfter(text, 1);
    end
else
    [~, name, ext] = fileparts(text);
    text = [name, ext];
end
if isempty(text)
    text = '.';
end
end

function text = parent_directory_relative(projectRoot, fullPath)
parentDir = fileparts(fullPath);
text = relative_path(projectRoot, parentDir);
end

function values = normalize_text_list(value)
if iscell(value)
    values = cellfun(@(x) char(string(x)), value, 'UniformOutput', false);
elseif isstring(value)
    values = cellstr(value(:));
elseif ischar(value)
    values = {value};
else
    error('scan_order_cancellation_dataset_coverage:InvalidList', ...
        'knownSmokeDatasets must be a cell array, char, or string.');
end
values = values(:);
for i = 1:numel(values)
    values{i} = char(string(values{i}));
end
end

function paths = normalize_path(paths)
if ischar(paths) || isstring(paths)
    paths = {char(string(paths))};
end
for i = 1:numel(paths)
    text = char(string(paths{i}));
    text = normalize_slashes(text);
    if ispc
        text = lower(text);
    end
    paths{i} = text;
end
end

function text = normalize_slashes(text)
text = char(string(text));
text = strrep(text, '\', '/');
end

function ratio = safe_ratio(numerator, denominator)
if denominator == 0
    ratio = 0;
else
    ratio = numerator / denominator;
end
end

function print_limited_list(items, mask, maxListRows)
if nargin < 2 || isempty(mask)
    mask = true(size(items));
end
selected = items(mask);
limit = min(maxListRows, numel(selected));
for i = 1:limit
    fprintf('%s\n', normalize_slashes(selected{i}));
end
if numel(selected) > limit
    fprintf('...\n');
end
end
