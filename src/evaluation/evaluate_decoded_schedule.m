function result = evaluate_decoded_schedule(decodedResult, problem, machineData, agvData, config)
%EVALUATE_DECODED_SCHEDULE Evaluate an already decoded schedule.
%   This independent evaluator does not call raw fitness.m. It consumes the
%   schedule tables produced by decoding and builds objectives through the
%   evaluation helper functions.

if nargin < 5
    error('evaluate_decoded_schedule:MissingInput', ...
        'decodedResult, problem, machineData, agvData, and config are required.');
end

require_fields(decodedResult, {'machineTable', 'AGVTable', ...
    'jobCompleteUnLoad', 'agvEGRecord', 'agvChargeNum'}, 'decodedResult');
require_fields(problem, {'jobNum'}, 'problem');
require_fields(machineData, {'machineEnergy'}, 'machineData');
require_fields(agvData, {'AGVNum'}, 'agvData');
require_fields(config, {'AGVEG_MAX', 'AGVEG_MIN', 'eChargeSpeed'}, 'config');

if numel(decodedResult.jobCompleteUnLoad) ~= problem.jobNum
    error('evaluate_decoded_schedule:InvalidDecodedResult', ...
        'decodedResult.jobCompleteUnLoad length must match problem.jobNum.');
end
if numel(decodedResult.AGVTable) ~= agvData.AGVNum || ...
        numel(decodedResult.agvEGRecord) ~= agvData.AGVNum || ...
        numel(decodedResult.agvChargeNum) ~= agvData.AGVNum
    error('evaluate_decoded_schedule:InvalidDecodedResult', ...
        'Decoded AGV fields must match agvData.AGVNum.');
end

makespan = compute_makespan_from_schedule(decodedResult);
machineEnergySum = compute_machine_energy( ...
    decodedResult.machineTable, machineData.machineEnergy);
agvEnergySum = compute_agv_energy(decodedResult.agvEGRecord);
objectiveResult = build_objectives(makespan, machineEnergySum, agvEnergySum);

result = objectiveResult;
result.detail = struct();
result.detail.machineTable = decodedResult.machineTable;
result.detail.AGVTable = decodedResult.AGVTable;
result.detail.jobCompleteUnLoad = decodedResult.jobCompleteUnLoad;
result.detail.agvEGRecord = decodedResult.agvEGRecord;
result.detail.agvChargeNum = decodedResult.agvChargeNum;
if isfield(decodedResult, 'scheduleContext')
    result.detail.scheduleContext = decodedResult.scheduleContext;
else
    result.detail.scheduleContext = [];
end
end

function require_fields(s, fields, structName)
if ~isstruct(s)
    error('evaluate_decoded_schedule:InvalidInput', ...
        '%s must be a struct.', structName);
end

for i = 1:numel(fields)
    if ~isfield(s, fields{i})
        error('evaluate_decoded_schedule:MissingField', ...
            '%s.%s is required.', structName, fields{i});
    end
end
end
