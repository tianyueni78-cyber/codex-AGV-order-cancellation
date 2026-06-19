projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'metrics'));

rawIgdPath = fullfile(projectRoot, 'raw_code', 'IGD');
rawSpacingPath = fullfile(projectRoot, 'raw_code', 'Spacing');
rawCMetricPath = fullfile(projectRoot, 'raw_code', 'C-metric');

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

referenceFront = [
    1, 5
    2, 3
    4, 2
    3, 2.5
];

currentPath = path;
cleanup = onCleanup(@() path(currentPath));

newSpacing = compute_spacing(A);
if exist('pdist2', 'file') == 2
    addpath(rawSpacingPath);
    rawSpacing = Spacing(A);
    rmpath(rawSpacingPath);
    assert(abs(newSpacing - rawSpacing) < 1e-12, 'Spacing does not match raw function.');
    spacingCompareNote = 'Spacing matches raw';
else
    spacingCompareNote = 'Spacing raw compare skipped because pdist2 is unavailable';
end

addpath(rawIgdPath);
rawIgd = IGD_compution(referenceFront, A);
rmpath(rawIgdPath);
newIgd = compute_igd(A, referenceFront);
assert(abs(newIgd - rawIgd) < 1e-12, 'IGD does not match raw function.');

addpath(rawCMetricPath);
rawCMetric = c_compute_A_B(A, B);
rmpath(rawCMetricPath);
newCMetric = compute_c_metric(A, B);
assert(abs(newCMetric - rawCMetric) < 1e-12, 'C-metric does not match raw function.');

referencePoint = [5, 6];
newHv = compute_hv(A, referencePoint);
assert(isfinite(newHv) && newHv >= 0, 'HV should be non-negative and finite.');

fprintf(['test_metrics_compare_raw passed: %s; IGD/C-metric match raw; ', ...
    'HV uses deterministic exact 2-D calculation\n'], spacingCompareNote);
