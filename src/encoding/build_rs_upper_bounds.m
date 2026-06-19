function UP = build_rs_upper_bounds(problem, agvData)
%BUILD_RS_UPPER_BOUNDS Build upper bounds for RS = [MS, AS, SS].
%   UP = BUILD_RS_UPPER_BOUNDS(problem, agvData) returns a row vector whose
%   length is 4 * sum(problem.operaNumVec).

if nargin < 2
    error('build_rs_upper_bounds:MissingInput', ...
        'problem and agvData are required.');
end

require_fields(problem, {'jobNum', 'operaNumVec', 'candidateMachine'}, ...
    'problem');
require_fields(agvData, {'AGVNum', 'AGVSpeed'}, 'agvData');

operaNum = sum(problem.operaNumVec);
MSUpper = zeros(1, operaNum);
pos = 1;

for jobIdx = 1:problem.jobNum
    for operaIdx = 1:problem.operaNumVec(jobIdx)
        candidates = problem.candidateMachine{jobIdx, operaIdx};
        candidateCount = numel(candidates);
        if candidateCount < 1
            error('build_rs_upper_bounds:EmptyCandidateMachine', ...
                'candidateMachine{%d,%d} is empty.', jobIdx, operaIdx);
        end

        MSUpper(pos) = candidateCount;
        pos = pos + 1;
    end
end

ASUpper = agvData.AGVNum * ones(1, operaNum);
SSUpper = numel(agvData.AGVSpeed) * ones(1, 2 * operaNum);
UP = [MSUpper, ASUpper, SSUpper];
end

function require_fields(s, fields, structName)
for i = 1:numel(fields)
    if ~isfield(s, fields{i})
        error('build_rs_upper_bounds:MissingField', ...
            '%s.%s is required.', structName, fields{i});
    end
end
end
