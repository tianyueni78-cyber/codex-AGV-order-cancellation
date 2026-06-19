projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'metrics'));

A = [
    1, 5
    2, 3
    4, 2
];

B = [
    2, 6
    3, 4
    5, 3
];

referencePoint = [5, 6];
referenceFront = [
    1, 5
    2, 3
    4, 2
];

spacing = compute_spacing(A);
assert(isfinite(spacing) && spacing >= 0, 'Spacing should be non-negative and finite.');

cValue = compute_c_metric(A, B);
assert(isfinite(cValue) && cValue >= 0 && cValue <= 1, ...
    'C-metric should be in [0, 1].');

hv = compute_hv(A, referencePoint);
assert(isfinite(hv) && hv >= 0, 'HV should be non-negative and finite.');
assert(abs(hv - 11) < 1e-12, 'Unexpected exact 2-D HV value.');

igd = compute_igd(A, referenceFront);
assert(isfinite(igd) && igd >= 0, 'IGD should be non-negative and finite.');
assert(abs(igd) < 1e-12, 'IGD should be zero when the reference front matches.');

options = struct();
options.referencePoint = referencePoint;
options.referenceFront = referenceFront;
options.baselineObjMatrix = B;
summary = compute_metric_summary(A, options);

assert(isstruct(summary), 'Metric summary should be a struct.');
assert(summary.solutionCount == size(A, 1), 'Unexpected solution count.');
assert(summary.objectiveCount == size(A, 2), 'Unexpected objective count.');
assert(isfield(summary, 'hv') && isfield(summary, 'igd') && ...
    isfield(summary, 'spacing') && isfield(summary, 'cMetric'), ...
    'Metric summary is missing expected fields.');

fprintf('test_metrics_toy_cases passed: hv=%g, igd=%g, spacing=%g, cMetric=%g\n', ...
    summary.hv, summary.igd, summary.spacing, summary.cMetric);
