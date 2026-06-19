function summary = compute_metric_summary(objMatrix, options)
%COMPUTE_METRIC_SUMMARY Build a metrics summary for an objective matrix.

validate_obj_matrix(objMatrix);

if nargin < 2 || isempty(options)
    options = struct();
end

summary = struct();
summary.solutionCount = size(objMatrix, 1);
summary.objectiveCount = size(objMatrix, 2);
summary.spacing = compute_spacing(objMatrix);
summary.hv = NaN;
summary.igd = NaN;
summary.cMetric = NaN;
summary.warnings = {};

if isfield(options, 'referencePoint') && ~isempty(options.referencePoint)
    try
        summary.hv = compute_hv(objMatrix, options.referencePoint);
    catch err
        summary.warnings{end + 1} = ['hv: ' err.message];
    end
else
    summary.warnings{end + 1} = 'hv: missing referencePoint';
end

if isfield(options, 'referenceFront') && ~isempty(options.referenceFront)
    try
        summary.igd = compute_igd(objMatrix, options.referenceFront);
    catch err
        summary.warnings{end + 1} = ['igd: ' err.message];
    end
else
    summary.warnings{end + 1} = 'igd: missing referenceFront';
end

if isfield(options, 'baselineObjMatrix') && ~isempty(options.baselineObjMatrix)
    try
        summary.cMetric = compute_c_metric(objMatrix, options.baselineObjMatrix);
    catch err
        summary.warnings{end + 1} = ['cMetric: ' err.message];
    end
else
    summary.warnings{end + 1} = 'cMetric: missing baselineObjMatrix';
end
end
