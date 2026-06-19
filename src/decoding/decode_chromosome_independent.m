function [schedule, report] = decode_chromosome_independent(chrom, problem, machineData, agvData, config)
%DECODE_CHROMOSOME_INDEPENDENT Decode one chromosome without raw sorting.m.

if nargin < 5
    error('decode_chromosome_independent:MissingInput', ...
        'chrom, problem, machineData, agvData, and config are required.');
end

schedule = empty_schedule();
report = empty_report();

requiredProblemFields = {'jobNum', 'jobInfo', 'operaNumVec', ...
    'candidateMachine'};
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

try
    parts = split_chromosome(chrom, problem);
    coreChrom = chrom(1:parts.dim);
    [machineTable, AGVTable, jobCompleteUnLoad, agvEGRecord, ...
        agvChargeNum, scheduleContext] = build_schedule( ...
        coreChrom, parts, problem, machineData, agvData, config);
catch err
    report.errors{end + 1} = err.message;
    report.isValid = false;
    report.decodingStatus = 'independent-decoding-failed';
    return
end

schedule.machineTable = machineTable;
schedule.AGVTable = AGVTable;
schedule.jobCompleteUnLoad = jobCompleteUnLoad;
schedule.agvEGRecord = agvEGRecord;
schedule.agvChargeNum = agvChargeNum;
schedule.scheduleContext = scheduleContext;
schedule.parts = parts;
schedule.operaNum = parts.operaNum;
schedule.dim = parts.dim;

report.isValid = true;
report.decodingStatus = 'decoded-independent';
end

function [machineTable, AGVTable, jobCompleteUnLoad, agvEGRecord, ...
    agvChargeNum, scheduleContext] = build_schedule( ...
    chrom, parts, problem, machineData, agvData, config)

OS = parts.OS;
MS = parts.MS;
AS = parts.AS;
SS = parts.SS;

machineTable = config.machineTable;
AGVTable = config.AGVTable;
distanceMatrix = machineData.distance_matrix;
AGVEnergy = agvData.AGVEnergy;

operaRec = zeros(1, problem.jobNum);
curJobTime = zeros(1, problem.jobNum);
jobPosition = -1 * ones(1, problem.jobNum);
jobCompleteUnLoad = zeros(1, problem.jobNum);
agvRealTimeEG = ones(1, agvData.AGVNum) * config.AGVEG_MAX;
agvEGRecord = cell(1, agvData.AGVNum);
for agvIdx = 1:agvData.AGVNum
    agvEGRecord{agvIdx} = [0, config.AGVEG_MAX];
end
agvChargeNum = zeros(1, agvData.AGVNum);

for idx = 1:parts.operaNum
    curJob = OS(idx);
    operaRec(curJob) = operaRec(curJob) + 1;
    jobOpera = operaRec(curJob);
    rsIndex = sum(problem.operaNumVec(1:curJob - 1)) + jobOpera;

    machine = problem.candidateMachine{curJob, jobOpera}(MS(rsIndex));
    agv = AS(rsIndex);

    ssIndex = 2 * rsIndex;
    freeIndex = ssIndex - 1;
    loadIndex = ssIndex;
    freeSpeed = agvData.AGVSpeed(SS(freeIndex));
    loadSpeed = agvData.AGVSpeed(SS(loadIndex));
    freeEGConsume = AGVEnergy.free(SS(freeIndex));
    loadEGConsume = AGVEnergy.load(SS(loadIndex));

    [AGVTable, agvRealTimeEG, agvEGRecord, agvChargeNum] = ...
        charge_low_energy_agvs(AGVTable, agvRealTimeEG, agvEGRecord, ...
        agvChargeNum, agvData, distanceMatrix, config);

    agvComplete = curJobTime(curJob);

    agvSpareStartTime = AGVTable{agv}(end).start;
    agvSpareStartMachine = AGVTable{agv}(end).from_machine;
    agvSpareDestMachine = jobPosition(curJob);

    if agvSpareDestMachine ~= machine
        spareTransferTime = compute_spare_transfer_time( ...
            agvSpareStartMachine, agvSpareDestMachine, ...
            distanceMatrix, freeSpeed);
        if spareTransferTime > 1e-6
            insertion.start = agvSpareStartTime;
            insertion.end = insertion.start + spareTransferTime;
            AGVTable{agv} = insert_agv_block(AGVTable{agv}, ...
                length(AGVTable{agv}), insertion, curJob, jobOpera, ...
                -1, agvSpareDestMachine, 0);
            agvRealTimeEG(agv) = agvRealTimeEG(agv) - ...
                spareTransferTime * freeEGConsume;
            agvEGRecord{agv} = [agvEGRecord{agv}; ...
                [insertion.end, agvRealTimeEG(agv)]];
        end
    end

    agvLoadStartTime = max(curJobTime(curJob), AGVTable{agv}(end).start);
    agvLoadStartMachine = AGVTable{agv}(end).from_machine;
    agvLoadDestMachine = machine;

    if agvSpareDestMachine ~= machine
        loadTransferTime = compute_load_transfer_time( ...
            agvLoadStartMachine, agvLoadDestMachine, ...
            distanceMatrix, loadSpeed);
        if loadTransferTime > 1e-6
            insertion.start = agvLoadStartTime;
            insertion.end = insertion.start + loadTransferTime;
            AGVTable{agv} = insert_agv_block(AGVTable{agv}, ...
                length(AGVTable{agv}), insertion, curJob, jobOpera, ...
                -2, agvLoadDestMachine, 0);
            agvComplete = insertion.end;
            agvRealTimeEG(agv) = agvRealTimeEG(agv) - ...
                loadTransferTime * loadEGConsume;
            agvEGRecord{agv} = [agvEGRecord{agv}; ...
                [insertion.end, agvRealTimeEG(agv)]];
        end
    end

    [machineTable, curJobTime, jobPosition] = insert_operation_block( ...
        machineTable, curJobTime, jobPosition, problem, ...
        curJob, jobOpera, machine, agvComplete);

    if jobOpera == problem.operaNumVec(curJob)
        [AGVTable, agvRealTimeEG, agvEGRecord, jobCompleteUnLoad] = ...
            unload_completed_job(AGVTable, agvRealTimeEG, agvEGRecord, ...
            jobCompleteUnLoad, curJobTime, curJob, machine, ...
            agvData, AGVEnergy, distanceMatrix);
    end
end

scheduleContext = struct();
scheduleContext.operaRec = operaRec;
scheduleContext.curJobTime = curJobTime;
scheduleContext.jobPosition = jobPosition;
scheduleContext.agvRealTimeEG = agvRealTimeEG;
scheduleContext.chrom = chrom;
end

function [AGVTable, agvRealTimeEG, agvEGRecord, agvChargeNum] = ...
    charge_low_energy_agvs(AGVTable, agvRealTimeEG, agvEGRecord, ...
    agvChargeNum, agvData, distanceMatrix, config)

for agvIdx = 1:agvData.AGVNum
    if agvRealTimeEG(agvIdx) <= config.AGVEG_MIN
        startMachine = AGVTable{agvIdx}(end - 1).to_machine;
        chargeMachine = -2;

        if startMachine ~= -2
            startTime = AGVTable{agvIdx}(end - 1).end;
            transferTime = distanceMatrix.machine_to_unload(startMachine) / ...
                agvData.AGVSpeed(3);
            insertion.start = startTime;
            insertion.end = insertion.start + transferTime;
            AGVTable{agvIdx} = insert_agv_block(AGVTable{agvIdx}, ...
                length(AGVTable{agvIdx}), insertion, 0, 0, -1, ...
                chargeMachine, 2);
            agvRealTimeEG(agvIdx) = agvRealTimeEG(agvIdx) - ...
                transferTime * agvData.AGVEnergy.free(3);
            agvEGRecord{agvIdx} = [agvEGRecord{agvIdx}; ...
                [insertion.end, agvRealTimeEG(agvIdx)]];
        end

        chargeTime = (config.AGVEG_MAX - agvRealTimeEG(agvIdx)) / ...
            config.eChargeSpeed;
        startTime = AGVTable{agvIdx}(end - 1).end;
        insertion.start = startTime;
        insertion.end = insertion.start + chargeTime;
        AGVTable{agvIdx} = insert_agv_block(AGVTable{agvIdx}, ...
            length(AGVTable{agvIdx}), insertion, 0, 0, 0, ...
            chargeMachine, 1);
        agvRealTimeEG(agvIdx) = config.AGVEG_MAX;
        agvEGRecord{agvIdx} = [agvEGRecord{agvIdx}; ...
            [insertion.end, agvRealTimeEG(agvIdx)]];
        agvChargeNum(agvIdx) = agvChargeNum(agvIdx) + 1;
    end
end
end

function [machineTable, curJobTime, jobPosition] = insert_operation_block( ...
    machineTable, curJobTime, jobPosition, problem, curJob, jobOpera, ...
    machine, agvComplete)

for blockIdx = 1:length(machineTable{machine})
    if isequal(machineTable{machine}(blockIdx).job, 0)
        startTime = max(machineTable{machine}(blockIdx).start, agvComplete);
        endTime = startTime + problem.jobInfo{curJob}(jobOpera, machine);
        if endTime <= machineTable{machine}(blockIdx).end
            insertion.start = startTime;
            insertion.end = endTime;
            machineTable{machine} = insert_machine_block( ...
                machineTable{machine}, blockIdx, insertion, curJob, jobOpera);
            curJobTime(curJob) = endTime;
            jobPosition(curJob) = machine;
            break;
        end
    end
end
end

function [AGVTable, agvRealTimeEG, agvEGRecord, jobCompleteUnLoad] = ...
    unload_completed_job(AGVTable, agvRealTimeEG, agvEGRecord, ...
    jobCompleteUnLoad, curJobTime, curJob, machine, agvData, ...
    AGVEnergy, distanceMatrix)

arrivalTime = zeros(1, agvData.AGVNum);
for agvIdx = 1:agvData.AGVNum
    earliestStartTime = AGVTable{agvIdx}(end).start;
    earliestStartMachine = AGVTable{agvIdx}(end).from_machine;
    transferTime = compute_spare_transfer_time(earliestStartMachine, ...
        machine, distanceMatrix, agvData.AGVSpeed(3));
    arrivalTime(agvIdx) = earliestStartTime + transferTime;
end

leaveTime = max([ones(1, agvData.AGVNum) * curJobTime(curJob); ...
    arrivalTime], [], 1);
agvCandidates = find(leaveTime == min(leaveTime));
if length(agvCandidates) > 1
    candidateArrivalTime = arrivalTime(agvCandidates);
    lastArrivalIndex = find(candidateArrivalTime == max(candidateArrivalTime));
    returnAgv = agvCandidates(lastArrivalIndex(1));
else
    returnAgv = agvCandidates;
end

if AGVTable{returnAgv}(end).from_machine ~= machine
    insertion.start = AGVTable{returnAgv}(end).start;
    insertion.end = arrivalTime(returnAgv);
    AGVTable{returnAgv} = insert_agv_block(AGVTable{returnAgv}, ...
        length(AGVTable{returnAgv}), insertion, curJob, -1, -1, machine, 0);
    agvRealTimeEG(returnAgv) = agvRealTimeEG(returnAgv) - ...
        (insertion.end - insertion.start) * AGVEnergy.free(3);
    agvEGRecord{returnAgv} = [agvEGRecord{returnAgv}; ...
        [insertion.end, agvRealTimeEG(returnAgv)]];
end

loadStartTime = max(arrivalTime(returnAgv), curJobTime(curJob));
transferTime = distanceMatrix.machine_to_unload(machine) / agvData.AGVSpeed(3);
insertion.start = loadStartTime;
insertion.end = insertion.start + transferTime;
AGVTable{returnAgv} = insert_agv_block(AGVTable{returnAgv}, ...
    length(AGVTable{returnAgv}), insertion, curJob, -1, -2, -2, 0);
agvRealTimeEG(returnAgv) = agvRealTimeEG(returnAgv) - ...
    (insertion.end - insertion.start) * AGVEnergy.load(3);
agvEGRecord{returnAgv} = [agvEGRecord{returnAgv}; ...
    [insertion.end, agvRealTimeEG(returnAgv)]];
jobCompleteUnLoad(curJob) = insertion.end;
end

function machineTable = insert_machine_block(machineTable, position, insertion, job, opera)
parts = decompose_machine_block(insertion, machineTable(position), job, opera);
machineTable = replace_block(machineTable, position, parts);
end

function AGVTable = insert_agv_block(AGVTable, position, insertion, job, opera, ...
    loadStatus, destMachine, chargeFlag)
AGVTable = normalize_single_agv_table(AGVTable);
parts = decompose_agv_block(insertion, AGVTable(position), job, opera, ...
    loadStatus, destMachine, chargeFlag);
if isfield(AGVTable, 'status') && ~isempty(parts)
    parts(1).status = AGVTable(position).status;
end
AGVTable = replace_block(AGVTable, position, parts);
end

function tableData = replace_block(tableData, position, parts)
tableData = [tableData(1:position - 1), parts, tableData(position + 1:end)];
end

function parts = decompose_machine_block(insertion, block, job, opera)
parts = struct('start', {}, 'end', {}, 'job', {}, 'opera', {});
if same_time(insertion.start, block.start) && same_time(insertion.end, block.end)
    parts(1) = machine_block(insertion.start, insertion.end, job, opera);
elseif same_time(insertion.start, block.start) && before_time(insertion.end, block.end)
    parts(1) = machine_block(insertion.start, insertion.end, job, opera);
    parts(2) = machine_block(insertion.end, block.end, 0, 0);
elseif after_time(insertion.start, block.start) && same_time(insertion.end, block.end)
    parts(1) = machine_block(block.start, insertion.start, 0, 0);
    parts(2) = machine_block(insertion.start, block.end, job, opera);
elseif after_time(insertion.start, block.start) && before_time(insertion.end, block.end)
    parts(1) = machine_block(block.start, insertion.start, 0, 0);
    parts(2) = machine_block(insertion.start, insertion.end, job, opera);
    parts(3) = machine_block(insertion.end, block.end, 0, 0);
else
    error('decode_chromosome_independent:MachineInsertFailed', ...
        'Could not decompose machine block.');
end
end

function parts = decompose_agv_block(insertion, block, job, opera, loadStatus, ...
    destMachine, chargeFlag)
parts = struct('start', {}, 'end', {}, 'job', {}, 'opera', {}, ...
    'from_machine', {}, 'to_machine', {}, 'status', {}, ...
    'load_status', {}, 'charge', {});
if same_time(insertion.start, block.start) && before_time(insertion.end, block.end)
    parts(1) = agv_block(insertion.start, insertion.end, job, opera, ...
        loadStatus, block.from_machine, destMachine, chargeFlag);
    parts(2) = agv_block(insertion.end, block.end, 0, 0, 0, ...
        destMachine, 0, 0);
elseif after_time(insertion.start, block.start) && before_time(insertion.end, block.end)
    parts(1) = agv_block(block.start, insertion.start, 0, 0, 0, ...
        block.from_machine, block.from_machine, 0);
    parts(2) = agv_block(insertion.start, insertion.end, job, opera, ...
        loadStatus, block.from_machine, destMachine, chargeFlag);
    parts(3) = agv_block(insertion.end, block.end, 0, 0, 0, ...
        destMachine, 0, 0);
else
    error('decode_chromosome_independent:AGVInsertFailed', ...
        'Could not decompose AGV block.');
end
end

function block = machine_block(startTime, endTime, job, opera)
block = struct('start', startTime, 'end', endTime, ...
    'job', job, 'opera', opera);
end

function block = agv_block(startTime, endTime, job, opera, loadStatus, ...
    fromMachine, toMachine, chargeFlag)
block = struct('start', startTime, 'end', endTime, 'job', job, ...
    'opera', opera, 'from_machine', fromMachine, ...
    'to_machine', toMachine, 'status', [], ...
    'load_status', loadStatus, 'charge', chargeFlag);
end

function AGVTable = normalize_single_agv_table(AGVTable)
if ~isfield(AGVTable, 'status')
    [AGVTable.status] = deal([]);
end
if ~isfield(AGVTable, 'load_status')
    [AGVTable.load_status] = deal([]);
end
if ~isfield(AGVTable, 'charge')
    [AGVTable.charge] = deal([]);
end
end

function transferTime = compute_spare_transfer_time(startMachine, destMachine, ...
    distanceMatrix, freeSpeed)
if startMachine == destMachine
    transferTime = 0;
elseif startMachine == -1
    transferTime = distanceMatrix.load_to_machine(destMachine) / freeSpeed;
elseif startMachine ~= -2 && destMachine == -1
    transferTime = distanceMatrix.load_to_machine(startMachine) / freeSpeed;
elseif startMachine == -2
    if destMachine == -1
        transferTime = distanceMatrix.load_to_unload / freeSpeed;
    else
        transferTime = distanceMatrix.machine_to_unload(destMachine) / freeSpeed;
    end
else
    transferTime = distanceMatrix.machine_to_machine(startMachine, destMachine) / freeSpeed;
end
end

function transferTime = compute_load_transfer_time(startMachine, destMachine, ...
    distanceMatrix, loadSpeed)
if startMachine == destMachine
    transferTime = 0;
elseif startMachine == -1
    transferTime = distanceMatrix.load_to_machine(destMachine) / loadSpeed;
else
    transferTime = distanceMatrix.machine_to_machine(startMachine, destMachine) / loadSpeed;
end
end

function tf = same_time(a, b)
tf = isequal(int64(1e6 * a), int64(1e6 * b));
end

function tf = before_time(a, b)
tf = int64(1e6 * a) < int64(1e6 * b);
end

function tf = after_time(a, b)
tf = int64(1e6 * a) > int64(1e6 * b);
end

function schedule = empty_schedule()
schedule = struct();
schedule.machineTable = [];
schedule.AGVTable = [];
schedule.jobCompleteUnLoad = [];
schedule.agvEGRecord = [];
schedule.agvChargeNum = [];
schedule.scheduleContext = [];
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
