clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

fprintf('independent search raw compare acceptance\n');
fprintf('compare: independent small search vs raw/refactored-variation small smoke\n');
fprintf('tolerance: obj_matrix non-empty, objective column count equal, curve generation count equal\n');
fprintf('note: Pareto points are not required to match exactly because selection tie-breaks can differ.\n');

run(fullfile(projectRoot, 'tests', 'test_search_independent_compare_raw.m'));

fprintf('test_independent_search_compare_raw passed\n');
