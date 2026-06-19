function benchmarkRead(pth)
[fileID, errmsg] = fopen(pth, 'r');

%% 打开失败
if isequal(fileID,-1)
    disp(errmsg);
    return;
end

%% 打开成功
firstLine=strip(fgetl(fileID));
firstLineVec=split(firstLine);

%% 读取机器，工件数目
jobNum=str2double(firstLineVec{1});
machineNum=str2double(firstLineVec{2});

%% 录入全部工件信息
operaNumVec=[];                % operaNumVec记录每个Job的工序数目
jobInfo=cell(1,jobNum);        
for i=1:jobNum %
    lineInfo=split(strip(fgetl(fileID)));%读取第一行
    operaNum=str2double(lineInfo{1});
    operaNumVec=[operaNumVec,operaNum];

    %如何把标准算例转化为易读矩阵
    countOs=2;
    for j=1:operaNum
        operaInfo=str2double(lineInfo{countOs});
        processVec=ones(1,machineNum)*Inf;
        for k=1:operaInfo
            countOs=countOs+1;
            machine=str2double(lineInfo{countOs});
            countOs=countOs+1;
            processTime=str2double(lineInfo{countOs});
            processVec(machine)=processTime;
        end
        jobInfo{i}=[jobInfo{i};processVec];
        countOs=countOs+1;
    end
end

%% 关闭
status=fclose(fileID);

%% 关闭文件失败
if isequal(status,-1)
    disp('close failed');
    return;
end

%% 读取jobInfo的信息：每个Job的候选机器
candidateMachine=[];
for i=1:length(jobInfo)
    for j=1:size(jobInfo{i},1)
        candidateMachine{i,j}=find(jobInfo{i}(j,:)<Inf);
    end
end

%% 保存
save('data.mat', 'jobInfo', 'candidateMachine', 'machineNum', 'jobNum', 'operaNumVec');
end