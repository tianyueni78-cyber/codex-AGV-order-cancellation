function [metrics, report] = evaluate_candidate_energy( ...
    baselineSchedule, candidateSchedule, machineData, agvData)
%EVALUATE_CANDIDATE_ENERGY Calculate energy and energy_delta.
%   Machine energy reuses compute_machine_energy. AGV energy reuses
%   compute_agv_energy when agvEGRecord exists; otherwise the first version
%   uses a simplified AGVTable-duration estimate.

if nargin < 4
    error('evaluate_candidate_energy:MissingInput', ...
        ['baselineSchedule, candidateSchedule, machineData, ', ...
        'and agvData are required.']);
end

metrics = empty_metrics();
report = empty_report();

[baselineEnergy, baselineReport] = evaluate_schedule_energy( ...
    baselineSchedule, machineData, agvData, 'baselineSchedule');
[candidateEnergy, candidateReport] = evaluate_schedule_energy( ...
    candidateSchedule, machineData, agvData, 'candidateSchedule');

report.baseline = baselineReport;
report.candidate = candidateReport;
report.errors = [report.errors, baselineReport.errors, ...
    candidateReport.errors];

if isempty(report.errors)
    metrics.baseline_energy = baselineEnergy.totalEnergy;
    metrics.energy = candidateEnergy.totalEnergy;
    metrics.energy_delta = metrics.energy - metrics.baseline_energy;
    metrics.baseline_machine_energy = baselineEnergy.machineEnergy;
    metrics.machine_energy = candidateEnergy.machineEnergy;
    metrics.baseline_agv_energy = baselineEnergy.agvEnergy;
    metrics.agv_energy = candidateEnergy.agvEnergy;
    metrics.baseline_agv_energy_source = baselineEnergy.agvEnergySource;
    metrics.agv_energy_source = candidateEnergy.agvEnergySource;
    metrics.isFeasible = true;
end

report.isFeasible = isempty(report.errors);
end

function [energy, report] = evaluate_schedule_energy( ...
    schedule, machineData, agvData, scheduleName)
energy = empty_energy();
report = empty_schedule_report();

if ~isstruct(schedule)
    report.errors{end + 1} = sprintf('%s must be a struct.', scheduleName);
    return
end
if ~isfield(schedule, 'machineTable')
    report.errors{end + 1} = sprintf( ...
        '%s.machineTable is required.', scheduleName);
    return
end
if ~isfield(schedule, 'AGVTable') && ...
        (~isfield(schedule, 'agvEGRecord') || isempty(schedule.agvEGRecord))
    report.errors{end + 1} = sprintf( ...
        '%s requires AGVTable or agvEGRecord.', scheduleName);
    return
end
if ~isstruct(machineData) || ~isfield(machineData, 'machineEnergy')
    report.errors{end + 1} = 'machineData.machineEnergy is required.';
    return
end

try
    energy.machineEnergy = compute_machine_energy( ...
        schedule.machineTable, machineData.machineEnergy);
catch err
    report.errors{end + 1} = sprintf( ...
        '%s machine energy failed: %s', scheduleName, err.message);
    return
end

[energy.agvEnergy, energy.agvEnergySource, agvReport] = ...
    evaluate_agv_energy(schedule, agvData, scheduleName);
report.errors = [report.errors, agvReport.errors];
report.warnings = [report.warnings, agvReport.warnings];
report.agvEnergySource = energy.agvEnergySource;

if isempty(report.errors)
    energy.totalEnergy = energy.machineEnergy + energy.agvEnergy;
end

report.machineEnergy = energy.machineEnergy;
report.agvEnergy = energy.agvEnergy;
report.totalEnergy = energy.totalEnergy;
report.isFeasible = isempty(report.errors);
end

function [agvEnergy, source, report] = evaluate_agv_energy( ...
    schedule, agvData, scheduleName)
agvEnergy = [];
source = '';
report = empty_agv_report();

if isfield(schedule, 'agvEGRecord') && ~isempty(schedule.agvEGRecord)
    try
        agvEnergy = compute_agv_energy(schedule.agvEGRecord);
        source = 'agvEGRecord';
    catch err
        report.errors{end + 1} = sprintf( ...
            '%s AGV energy failed: %s', scheduleName, err.message);
    end
    return
end

if ~isfield(schedule, 'AGVTable')
    report.errors{end + 1} = sprintf( ...
        '%s.AGVTable is required for simplified AGV energy.', ...
        scheduleName);
    return
end
if ~isstruct(agvData) || ~isfield(agvData, 'AGVEnergy')
    report.errors{end + 1} = 'agvData.AGVEnergy is required.';
    return
end

try
    agvEnergy = compute_simplified_agv_table_energy( ...
        schedule.AGVTable, agvData.AGVEnergy, scheduleName);
    source = 'AGVTable_simplified';
    report.warnings{end + 1} = ...
        ['AGV energy used simplified AGVTable-duration estimate ', ...
        'because agvEGRecord was not available.'];
catch err
    report.errors{end + 1} = sprintf( ...
        '%s simplified AGV energy failed: %s', scheduleName, err.message);
end
end

function agvEnergy = compute_simplified_agv_table_energy( ...
    AGVTable, AGVEnergy, scheduleName)
if ~iscell(AGVTable)
    error('AGVTable must be a cell array.');
end
if ~isstruct(AGVEnergy) || ~isfield(AGVEnergy, 'free') || ...
        ~isfield(AGVEnergy, 'load')
    error('agvData.AGVEnergy.free and agvData.AGVEnergy.load are required.');
end

freeRate = first_rate(AGVEnergy.free, 'agvData.AGVEnergy.free');
loadRate = first_rate(AGVEnergy.load, 'agvData.AGVEnergy.load');
agvEnergy = 0;

for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        require_agv_block_fields(block, scheduleName, agvIdx, blockIdx);
        if isequal(block.end, inf)
            continue
        end

        startTime = require_scalar_time(block.start, ...
            scheduleName, agvIdx, blockIdx, 'start');
        endTime = require_scalar_time(block.end, ...
            scheduleName, agvIdx, blockIdx, 'end');
        if endTime < startTime
            error('%s.AGVTable{%d} block %d has end < start.', ...
                scheduleName, agvIdx, blockIdx);
        end

        duration = endTime - startTime;
        if block.job > 0
            agvEnergy = agvEnergy + duration * loadRate;
        else
            agvEnergy = agvEnergy + duration * freeRate;
        end
    end
end
end

function value = first_rate(values, fieldName)
if ~isnumeric(values) || isempty(values)
    error('%s must be a non-empty numeric array.', fieldName);
end
value = values(1);
end

function require_agv_block_fields(block, scheduleName, agvIdx, blockIdx)
requiredFields = {'start', 'end', 'job'};
for i = 1:numel(requiredFields)
    if ~isfield(block, requiredFields{i})
        error('%s.AGVTable{%d} block %d field %s is required.', ...
            scheduleName, agvIdx, blockIdx, requiredFields{i});
    end
end
end

function value = require_scalar_time(value, scheduleName, agvIdx, ...
    blockIdx, fieldName)
if isempty(value) || ~isnumeric(value) || ~isscalar(value)
    error('%s.AGVTable{%d} block %d field %s must be a numeric scalar.', ...
        scheduleName, agvIdx, blockIdx, fieldName);
end
end

function metrics = empty_metrics()
metrics = struct();
metrics.baseline_energy = [];
metrics.energy = [];
metrics.energy_delta = [];
metrics.baseline_machine_energy = [];
metrics.machine_energy = [];
metrics.baseline_agv_energy = [];
metrics.agv_energy = [];
metrics.baseline_agv_energy_source = '';
metrics.agv_energy_source = '';
metrics.isFeasible = false;
end

function energy = empty_energy()
energy = struct();
energy.machineEnergy = [];
energy.agvEnergy = [];
energy.totalEnergy = [];
energy.agvEnergySource = '';
end

function report = empty_report()
report = struct();
report.errors = {};
report.warnings = {};
report.baseline = struct();
report.candidate = struct();
report.isFeasible = false;
end

function report = empty_schedule_report()
report = struct();
report.errors = {};
report.warnings = {};
report.machineEnergy = [];
report.agvEnergy = [];
report.totalEnergy = [];
report.agvEnergySource = '';
report.isFeasible = false;
end

function report = empty_agv_report()
report = struct();
report.errors = {};
report.warnings = {};
end
