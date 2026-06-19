clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

fprintf('independent decoding raw compare acceptance\n');
fprintf('compare: raw sorting.m vs decode_chromosome_independent\n');
fprintf('tolerance: exact structural match with isequaln for schedule fields\n');

run(fullfile(projectRoot, 'tests', 'test_decoding_independent_compare_sorting.m'));

fprintf('test_independent_decoding_compare_raw passed\n');
