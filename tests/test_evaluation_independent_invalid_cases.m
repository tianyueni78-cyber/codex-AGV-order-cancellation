clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'evaluation'));

[decodedResult, problem, machineData, agvData, config] = make_valid_case();

missingDecoded = rmfield(decodedResult, 'machineTable');
expect_error(@() evaluate_decoded_schedule(missingDecoded, problem, machineData, agvData, config), ...
    'evaluate_decoded_schedule:MissingField');

badDecoded = decodedResult;
badDecoded.jobCompleteUnLoad = [1, 2];
expect_error(@() evaluate_decoded_schedule(badDecoded, problem, machineData, agvData, config), ...
    'evaluate_decoded_schedule:InvalidDecodedResult');

missingMachineData = rmfield(machineData, 'machineEnergy');
expect_error(@() evaluate_decoded_schedule(decodedResult, problem, missingMachineData, agvData, config), ...
    'evaluate_decoded_schedule:MissingField');

badAgv = decodedResult;
badAgv.agvEGRecord = badAgv.agvEGRecord(1);
expect_error(@() evaluate_decoded_schedule(badAgv, problem, machineData, agvData, config), ...
    'evaluate_decoded_schedule:InvalidDecodedResult');

fprintf('test_evaluation_independent_invalid_cases passed\n');

function [decodedResult, problem, machineData, agvData, config] = make_valid_case()
decodedResult.jobCompleteUnLoad = [5, 7, 6];
decodedResult.machineTable = {struct('start', 0, 'end', 5, 'job', 1, 'opera', 1)};
decodedResult.AGVTable = {[], []};
decodedResult.agvEGRecord = {[0, 100; 1, 95], [0, 100]};
decodedResult.agvChargeNum = [0, 0];
problem.jobNum = 3;
machineData.machineEnergy.work = 1;
machineData.machineEnergy.free = 0;
agvData.AGVNum = 2;
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;
end

function expect_error(fn, expectedIdentifier)
try
    fn();
    error('test_evaluation_independent_invalid_cases:ExpectedError', ...
        'Expected error was not raised.');
catch err
    assert(strcmp(err.identifier, expectedIdentifier), ...
        'Expected %s, got %s.', expectedIdentifier, err.identifier);
end
end
