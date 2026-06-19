function save_figure_safely(fig, outputPath, options)
%SAVE_FIGURE_SAFELY Save a figure only to an explicitly provided path.

if nargin < 3 || isempty(options)
    options = struct();
end

if isempty(fig) || ~ishghandle(fig, 'figure')
    error('save_figure_safely:InvalidFigure', ...
        'fig must be a valid figure handle.');
end

if nargin < 2 || ~ischar(outputPath) || isempty(outputPath)
    error('save_figure_safely:InvalidOutputPath', ...
        'outputPath must be a non-empty character vector.');
end

if is_absolute_repo_sensitive_path(outputPath)
    error('save_figure_safely:UnsafeOutputPath', ...
        'Do not save figures into raw_code or the project root implicitly.');
end

outputDir = fileparts(outputPath);
if ~isempty(outputDir) && exist(outputDir, 'dir') ~= 7
    mkdir(outputDir);
end

format = get_option(options, 'format', '');
if isempty(format)
    [~, ~, ext] = fileparts(outputPath);
    format = strrep(lower(ext), '.', '');
end

if isempty(format)
    error('save_figure_safely:MissingFormat', ...
        'Figure format cannot be inferred from outputPath.');
end

switch lower(format)
    case 'fig'
        savefig(fig, outputPath);
    case {'png', 'jpg', 'jpeg', 'pdf'}
        saveas(fig, outputPath, format);
    otherwise
        error('save_figure_safely:UnsupportedFormat', ...
            'Unsupported figure format: %s.', format);
end
end

function unsafe = is_absolute_repo_sensitive_path(outputPath)
normalized = strrep(outputPath, '/', filesep);
parts = strsplit(normalized, filesep);
unsafe = any(strcmp(parts, 'raw_code'));
end
