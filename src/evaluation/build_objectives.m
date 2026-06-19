function result = build_objectives(makespan, machineEnergySum, agvEnergySum)
%BUILD_OBJECTIVES Build objective vector and total energy.
%   result = BUILD_OBJECTIVES(makespan, machineEnergySum, agvEnergySum)
%   returns the objective vector used by raw fitness.m.

if nargin < 3
    error('build_objectives:MissingInput', ...
        'makespan, machineEnergySum, and agvEnergySum are required.');
end
validate_scalar(makespan, 'makespan');
validate_scalar(machineEnergySum, 'machineEnergySum');
validate_scalar(agvEnergySum, 'agvEnergySum');

totalEnergy = machineEnergySum + agvEnergySum;

result = struct();
result.makespan = makespan;
result.machineEnergy = machineEnergySum;
result.agvEnergy = agvEnergySum;
result.totalEnergy = totalEnergy;
result.objectives = [makespan, totalEnergy];
result.FUNC = {result.objectives};
end

function validate_scalar(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error('build_objectives:InvalidInput', ...
        '%s must be a finite numeric scalar.', name);
end
end
