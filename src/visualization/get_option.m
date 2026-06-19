function value = get_option(options, fieldName, defaultValue)
%GET_OPTION Return an option field or a default value.

if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
