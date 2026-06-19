function agvEnergySum = compute_agv_energy(agvEGRecord)
%COMPUTE_AGV_ENERGY Compute AGV energy from battery-record drops.
%   agvEnergySum = COMPUTE_AGV_ENERGY(agvEGRecord) matches raw fitness.m:
%   only positive drops between consecutive battery records are accumulated.

if nargin < 1
    error('compute_agv_energy:MissingInput', ...
        'agvEGRecord is required.');
end
if ~iscell(agvEGRecord)
    error('compute_agv_energy:InvalidInput', ...
        'agvEGRecord must be a cell array.');
end

agvNum = numel(agvEGRecord);
perAgvEnergy = zeros(1, agvNum);

for agvIdx = 1:agvNum
    records = agvEGRecord{agvIdx};
    if isempty(records)
        continue
    end
    if ~isnumeric(records) || size(records, 2) < 2
        error('compute_agv_energy:InvalidInput', ...
            'Each agvEGRecord entry must be a numeric matrix with at least two columns.');
    end

    for recordIdx = 2:size(records, 1)
        drop = records(recordIdx - 1, 2) - records(recordIdx, 2);
        if drop < 0
            continue
        end
        perAgvEnergy(agvIdx) = perAgvEnergy(agvIdx) + drop;
    end
end

agvEnergySum = sum(perAgvEnergy);
end
