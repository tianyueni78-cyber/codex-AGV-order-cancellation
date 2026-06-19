function problem = read_fjsp(pth)
%READ_FJSP Read a flexible job shop scheduling .fjs instance.
%   problem = READ_FJSP(pth) parses the same instance format used by
%   raw_code/benchmarkRead.m, but only returns data and does not write files.

[fileID, errmsg] = fopen(pth, 'r');
if isequal(fileID, -1)
    error('read_fjsp:OpenFailed', '%s', errmsg);
end
cleanupObj = onCleanup(@() fclose(fileID));

firstLine = strip(fgetl(fileID));
firstLineVec = split(firstLine);

jobNum = str2double(firstLineVec{1});
machineNum = str2double(firstLineVec{2});

operaNumVec = [];
jobInfo = cell(1, jobNum);
for i = 1:jobNum
    lineInfo = split(strip(fgetl(fileID)));
    operaNum = str2double(lineInfo{1});
    operaNumVec = [operaNumVec, operaNum];

    countOs = 2;
    for j = 1:operaNum
        operaInfo = str2double(lineInfo{countOs});
        processVec = ones(1, machineNum) * Inf;
        for k = 1:operaInfo
            countOs = countOs + 1;
            machine = str2double(lineInfo{countOs});
            countOs = countOs + 1;
            processTime = str2double(lineInfo{countOs});
            processVec(machine) = processTime;
        end
        jobInfo{i} = [jobInfo{i}; processVec];
        countOs = countOs + 1;
    end
end

candidateMachine = cell(size(jobInfo, 2), max(operaNumVec));
for i = 1:length(jobInfo)
    for j = 1:size(jobInfo{i}, 1)
        candidateMachine{i, j} = find(jobInfo{i}(j, :) < Inf);
    end
end

problem = struct();
problem.jobInfo = jobInfo;
problem.candidateMachine = candidateMachine;
problem.machineNum = machineNum;
problem.jobNum = jobNum;
problem.operaNumVec = operaNumVec;
end
