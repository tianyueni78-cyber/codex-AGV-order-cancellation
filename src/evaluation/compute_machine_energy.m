function machineEnergySum = compute_machine_energy(machineTable, machineEnergy)
%COMPUTE_MACHINE_ENERGY Compute machine work and idle energy.
%   machineEnergySum = COMPUTE_MACHINE_ENERGY(machineTable, machineEnergy)
%   matches the machine-energy accumulation in raw fitness.m.

if nargin < 2
    error('compute_machine_energy:MissingInput', ...
        'machineTable and machineEnergy are required.');
end
if ~iscell(machineTable)
    error('compute_machine_energy:InvalidMachineTable', ...
        'machineTable must be a cell array.');
end
if ~isstruct(machineEnergy) || ~isfield(machineEnergy, 'work') || ...
        ~isfield(machineEnergy, 'free')
    error('compute_machine_energy:MissingField', ...
        'machineEnergy.work and machineEnergy.free are required.');
end

machineNum = numel(machineTable);
if numel(machineEnergy.work) < machineNum || numel(machineEnergy.free) < machineNum
    error('compute_machine_energy:InvalidEnergyData', ...
        'machineEnergy vectors must cover every machine.');
end

machineWork = zeros(machineNum, 1);
machineSpare = zeros(machineNum, 1);

for machineIdx = 1:machineNum
    blocks = machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        require_block_fields(block, 'machineTable');
        if isequal(block.end, inf)
            continue
        end

        duration = block.end - block.start;
        if isequal(block.job, 0)
            machineSpare(machineIdx) = machineSpare(machineIdx) + duration;
        else
            machineWork(machineIdx) = machineWork(machineIdx) + duration;
        end
    end
end

workRates = machineEnergy.work(1:machineNum);
freeRates = machineEnergy.free(1:machineNum);
machineEnergySum = workRates(:)' * machineWork + freeRates(:)' * machineSpare;
end

function require_block_fields(block, structName)
requiredFields = {'start', 'end', 'job'};
for i = 1:numel(requiredFields)
    if ~isfield(block, requiredFields{i})
        error('compute_machine_energy:MissingField', ...
            '%s block field %s is required.', structName, requiredFields{i});
    end
end
end
