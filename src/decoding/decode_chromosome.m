function [schedule, report] = decode_chromosome(chrom, problem, machineData, agvData, config)
%DECODE_CHROMOSOME Decode one chromosome into raw-compatible schedule tables.
%   [schedule, report] = DECODE_CHROMOSOME(chrom, problem, machineData,
%   agvData, config) validates and splits one chromosome, then delegates the
%   schedule construction to the raw sorting.m implementation. This first
%   decoding wrapper keeps raw_code unchanged and requires callers to provide
%   raw-compatible initial machineTable and AGVTable in config.

if nargin < 5
    error('decode_chromosome:MissingInput', ...
        'chrom, problem, machineData, agvData, and config are required.');
end

schedule = empty_schedule();
report = empty_report();

requiredProblemFields = {'jobNum', 'jobInfo', 'operaNumVec', 'candidateMachine'};
requiredMachineFields = {'distance_matrix'};
requiredAgvFields = {'AGVNum', 'AGVSpeed', 'AGVEnergy'};
requiredConfigFields = {'AGVEG_MAX', 'AGVEG_MIN', 'eChargeSpeed', ...
    'machineTable', 'AGVTable'};

report = require_fields(problem, requiredProblemFields, 'problem', report);
report = require_fields(machineData, requiredMachineFields, 'machineData', report);
report = require_fields(agvData, requiredAgvFields, 'agvData', report);
report = require_fields(config, requiredConfigFields, 'config', report);

if ~isempty(report.errors)
    report.isValid = false;
    report.decodingStatus = 'missing-required-fields';
    return
end

[isEncodingValid, encodingReport] = validate_chromosome(chrom, problem, agvData);
report.encodingReport = encodingReport;
if ~isEncodingValid
    report.errors{end + 1} = 'chrom did not pass encoding validation.';
    report.isValid = false;
    report.decodingStatus = 'invalid-encoding';
    return
end

parts = split_chromosome(chrom, problem);
coreChrom = chrom(1:parts.dim);

if exist('sorting', 'file') ~= 2
    report.errors{end + 1} = ...
        'sorting.m is not on the MATLAB path; add the raw NSGA-II path before decoding.';
    report.isValid = false;
    report.decodingStatus = 'missing-sorting-function';
    return
end

try
    [machineTable, AGVTable, jobCompleteUnLoad, agvEGRecord, agvChargeNum] = ...
        sorting(coreChrom, problem.jobNum, problem.jobInfo, problem.operaNumVec, ...
        agvData.AGVNum, agvData.AGVSpeed, problem.candidateMachine, ...
        machineData.distance_matrix, agvData.AGVEnergy, config.AGVEG_MAX, ...
        config.AGVEG_MIN, config.eChargeSpeed, config.machineTable, config.AGVTable);
catch err
    report.errors{end + 1} = err.message;
    report.isValid = false;
    report.decodingStatus = 'sorting-failed';
    return
end

schedule.machineTable = machineTable;
schedule.AGVTable = AGVTable;
schedule.jobCompleteUnLoad = jobCompleteUnLoad;
schedule.agvEGRecord = agvEGRecord;
schedule.agvChargeNum = agvChargeNum;
schedule.parts = parts;
schedule.operaNum = parts.operaNum;
schedule.dim = parts.dim;

report.isValid = true;
report.decodingStatus = 'decoded';
end

function schedule = empty_schedule()
schedule = struct();
schedule.machineTable = [];
schedule.AGVTable = [];
schedule.jobCompleteUnLoad = [];
schedule.agvEGRecord = [];
schedule.agvChargeNum = [];
schedule.parts = [];
schedule.operaNum = [];
schedule.dim = [];
end

function report = empty_report()
report = struct();
report.isValid = false;
report.errors = {};
report.warnings = {};
report.encodingReport = [];
report.decodingStatus = 'not-started';
end

function report = require_fields(s, fields, structName, report)
for i = 1:numel(fields)
    if ~isfield(s, fields{i})
        report.errors{end + 1} = sprintf( ...
            '%s.%s is required.', structName, fields{i});
    end
end
end
