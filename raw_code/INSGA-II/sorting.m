function [machineTable, AGVTable, jobCompleteUnLoad, agvEGRecord, agvChargeNum] = sorting(chrom, jobNum, jobInfo, operaVec, ...
    AGVNum, AGVSpeed, ...
    candidateMachine, distance_matrix, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, machineTable, AGVTable)
%% 染色体的 OS MS AS SS 切片
operaNum = sum(operaVec);%存储所有工序总共数量
OS = chrom(1: operaNum);
MS = chrom(operaNum + 1: 2 * operaNum);
AS = chrom(2 * operaNum + 1 : 3 * operaNum);
SS = chrom(3 * operaNum + 1: 5 * operaNum);

%% 主循环：依次循环每个染色体
operaRec = zeros(1, jobNum);        % 记录当前运行在每个Job的第几步
curJobTime = zeros(1, jobNum);      % 记录当前Job的上一道工序的结束时间
jobPosition = -1 * ones(1, jobNum); % 记录当前Job的上一道工序的机器
jobCompleteUnLoad = zeros(1, jobNum);   % 记录每个Job在运送到卸载站的时间
agvRealTimeEG = ones(1, AGVNum) * AGVEG_MAX;    % 记录AGV的电量 ==> 用于约束
% 辅助记录电量变化
agvEGRecord = cell(1, AGVNum);
for a = 1: AGVNum
    agvEGRecord{a} = [0, AGVEG_MAX];
end
% 记录充电次数
agvChargeNum = zeros(1, AGVNum);

%% 循环
for i = 1 : sum(operaVec)%对每个工序
    curJob = OS(i); % 当前工件→curJob
    operaRec(curJob) = operaRec(curJob) + 1;
    jobOpera = operaRec(curJob);    % 当前工件的工序
    rSIndex = sum(operaVec(1: curJob - 1)) + jobOpera;     % 确定当前job的当前工序对应MS/AS上的位置
    machine = candidateMachine{curJob, jobOpera}(MS(rSIndex));  % 所选机器
    agv = AS(rSIndex);                                          % 所选AGV
    
    % 选择速度挡位
    ssIndex = 2 * (sum(operaVec(1: curJob - 1)) + jobOpera); % 速度索引
    freeIndex = ssIndex - 1;
    loadIndex = ssIndex;
    free_speed = AGVSpeed(SS(freeIndex));   % 根据SS片段读取到空载速度
    load_speed = AGVSpeed(SS(loadIndex));   % 根据SS片段读取到负载速度
    freeEGConsume = AGVEnergy.free(SS(freeIndex));  % 空载速度对应的单位时间能耗
    loadEGConsume = AGVEnergy.load(SS(loadIndex));  % 负载速度对应的单位时间能耗


    
    %% AGV分配视为MTSP（多旅行商问题），旅行顺序即为OS顺序
    % 由于不能带负载去充电桩，每次转移（空载+负载）前检查电量
    % 电量低于充电阈值
    % 检查所有AGV

    for ag_idx = 1: AGVNum
        if agvRealTimeEG(ag_idx) <= AGVEG_MIN
            start_m = AGVTable{ag_idx}(end - 1).to_machine;    % AGV目前所在机器
            to_m = -2;                                      % 充电桩（卸载站）代号 -2

            % agv并不在卸载站，需要前往卸载站充电
            if start_m ~= -2
                start_T = AGVTable{ag_idx}(end - 1).end;       % 转移开始时间
                transfer_time = distance_matrix.machine_to_unload(start_m) / AGVSpeed(3);    % 转移耗时：转移不可能从装载站开始
                % 同时默认使用空载3档（最快挡位），因为编码部分没有充电编码

                % 前往卸载站充电
                insertion.start = start_T;
                insertion.end = insertion.start + transfer_time;
                table_out = table_insert(insertion, AGVTable{ag_idx}, length(AGVTable{ag_idx}), 0, 0, -1, to_m, 2);
                AGVTable{ag_idx} = table_out;

                % 更新电量
                agvRealTimeEG(ag_idx) = agvRealTimeEG(ag_idx) - transfer_time * AGVEnergy.free(3);
                agvEGRecord{ag_idx} = [agvEGRecord{ag_idx}; [insertion.end, agvRealTimeEG(ag_idx)]];
            end

            % 充电
            charge_time = (AGVEG_MAX - agvRealTimeEG(ag_idx)) / eChargeSpeed;      % 充至额定电量耗时
            start_T = AGVTable{ag_idx}(end - 1).end;   % 开始充电时间
            insertion.start = start_T;
            insertion.end = insertion.start + charge_time;  % 结束充电时间
            table_out = table_insert(insertion, AGVTable{ag_idx}, length(AGVTable{ag_idx}), 0, 0, 0, to_m, 1);
            AGVTable{ag_idx} = table_out;

            % 充完电后，电量恢复
            agvRealTimeEG(ag_idx) = AGVEG_MAX;
            agvEGRecord{ag_idx} = [agvEGRecord{ag_idx}; [insertion.end, agvRealTimeEG(ag_idx)]];
            % 充电次数 +1
            agvChargeNum(ag_idx) = agvChargeNum(ag_idx) + 1;
        end
    end

    agv_complete = curJobTime(curJob);  % 记录AGV搬运所形成的时间约束

    %% ########################### 空载转移 ############################
    len_ = length(AGVTable{agv});
    agv_spare_start_time = AGVTable{agv}(len_).start;
    agv_spare_start_machine = AGVTable{agv}(len_).from_machine;     % 空载转移的起始机器
    agv_spare_dest_machine = jobPosition(curJob);                   % 空载转移的目标机器
    
    
    % AGVTable{agv}插入空载转移时间块
    if agv_spare_dest_machine ~= machine    % 上一道工序与下一道工序的加工机器不同

        % 计算转移时间
        spare_transfer_time = spare_transfer_time_compute(agv_spare_start_machine, agv_spare_dest_machine, ...
            distance_matrix, free_speed);

        if spare_transfer_time > 1E-6   % spare_transfer_time ~= 0
            insertion.start = agv_spare_start_time;                 % 空载转移的起始时间
            insertion.end = insertion.start + spare_transfer_time;  % 空载转移的结束时间
            table_out = table_insert(insertion, AGVTable{agv}, length(AGVTable{agv}), curJob, jobOpera, -1, ...
                agv_spare_dest_machine, 0);
            AGVTable{agv} = table_out;
            % 更新 空载转移后AGV的电量
            agvRealTimeEG(agv) = agvRealTimeEG(agv) - spare_transfer_time * freeEGConsume;
            agvEGRecord{agv} = [agvEGRecord{agv}; [insertion.end, agvRealTimeEG(agv)]];
        end
    end

    % 
    %% ########################### 负载转移 ############################
    len_ = length(AGVTable{agv});
    % 负载转移的起始时间：MAX（待搬运工件（工序）的完工时间、AGV到达时间）
    agv_load_start_time = max(curJobTime(curJob), AGVTable{agv}(len_).start);
    agv_load_start_machine = AGVTable{agv}(len_).from_machine;  % 负载转移的起始机器
    agv_load_dest_machine = machine;                            % 负载转移的目标机器

    % AGVTable{agv}插入负载转移时间块
    if agv_spare_dest_machine ~= machine    % 上一道工序与下一道工序的加工机器不同
        
        % 计算转移时间
        load_transfer_time = load_transfer_time_compute(agv_load_start_machine, agv_load_dest_machine, ...
            distance_matrix, load_speed);

        if load_transfer_time > 1E-6   % spare_transfer_time == 0
            insertion.start = agv_load_start_time;                 % 负载转移的起始时间
            insertion.end = insertion.start + load_transfer_time;  % 负载转移的结束时间
            table_out = table_insert(insertion, AGVTable{agv}, length(AGVTable{agv}), curJob, jobOpera, -2, ...
                agv_load_dest_machine, 0);
            AGVTable{agv} = table_out;
            % 更新 agv_complete
            agv_complete = insertion.end;
            % 更新 负载转移后AGV的电量
            agvRealTimeEG(agv) = agvRealTimeEG(agv) - load_transfer_time * loadEGConsume;
            agvEGRecord{agv} = [agvEGRecord{agv}; [insertion.end, agvRealTimeEG(agv)]];
        end
    end

    %% machineTable 寻空插入工序加工时间块儿
    for j = 1 : length(machineTable{machine})
        % 寻找空闲时间块
        if isequal(machineTable{machine}(j).job, 0)
            % 判断能否插入
            startT = max(machineTable{machine}(j).start, agv_complete);
            endT = startT + jobInfo{curJob}(jobOpera, machine);
            if endT <= machineTable{machine}(j).end           % 能插入
                insertion.start=startT;     % 插入时间块的起始时间
                insertion.end=endT;         % 插入时间块的结束时间
                table_out = table_insert(insertion, machineTable{machine}, j, curJob, jobOpera);
                machineTable{machine} = table_out;

                % 更新curJobTime、jobPosition 
                curJobTime(curJob) = endT;
                jobPosition(curJob) = machine;
                break;
            end
        end
    end

    %% 遇到每个工件的最后一道工序，安排一辆耗时最短的AGV将其运输到 卸载站
    if jobOpera == operaVec(curJob)
        arrival_time = [];
        for a = 1 : AGVNum
            earlierest_start_time = AGVTable{a}(length(AGVTable{a})).start;
            earlierest_start_machine = AGVTable{a}(length(AGVTable{a})).from_machine;
            % 工件加工完后运送至卸载站，此部分速度没有编码，默认采用三档
            return_free_speed = AGVSpeed(3);
            earlierest_transfer_time = spare_transfer_time_compute(earlierest_start_machine, machine, distance_matrix, return_free_speed);
            earlierest_arrival_time = earlierest_start_time + earlierest_transfer_time;
            arrival_time = [arrival_time, earlierest_arrival_time];
        end

        % 选择最早可以离开的
        leave_time = max([ones(1, AGVNum) * curJobTime(curJob); arrival_time], [], 1);
        agv_candidate = find(leave_time == min(leave_time));
        if length(agv_candidate) > 1
            new_arrival_time = arrival_time(agv_candidate);
            last_arrival_index = find(new_arrival_time == max(new_arrival_time));
            return_agv = agv_candidate(last_arrival_index(1));
        else
            return_agv = agv_candidate;
        end

        % 空载前往搬运工件
        if AGVTable{return_agv}(length(AGVTable{return_agv})).from_machine ~= machine
            insertion.start = AGVTable{return_agv}(length(AGVTable{return_agv})).start;
            insertion.end = arrival_time(return_agv); 
            table_out = table_insert(insertion, AGVTable{return_agv}, length(AGVTable{return_agv}), ...
                curJob, -1, -1, machine, 0);
            AGVTable{return_agv} = table_out;
            % 空载运输后更新电量 return_agv
            agvRealTimeEG(return_agv) = agvRealTimeEG(return_agv) - (insertion.end - insertion.start) * AGVEnergy.free(3);
            agvEGRecord{return_agv} = [agvEGRecord{return_agv}; [insertion.end, agvRealTimeEG(return_agv)]];
        end

        % returnAGV 将该工件运输至 卸载站
        return_load_start_time = max(arrival_time(return_agv), curJobTime(curJob));
        % 工件加工完后运送至卸载站，此部分速度没有编码，默认采用三档
        return_load_speed = AGVSpeed(3);
        return_load_transfer_time = distance_matrix.machine_to_unload(machine) / return_load_speed;
        insertion.start = return_load_start_time;
        insertion.end = insertion.start + return_load_transfer_time;
        table_out = table_insert(insertion, AGVTable{return_agv}, length(AGVTable{return_agv}), ...
                curJob, -1, -2, -2, 0);
        AGVTable{return_agv} = table_out;
        % 负载运输后更新电量 return_agv
        agvRealTimeEG(return_agv) = agvRealTimeEG(return_agv) - (insertion.end - insertion.start) * AGVEnergy.load(3);
        agvEGRecord{return_agv} = [agvEGRecord{return_agv}; [insertion.end, agvRealTimeEG(return_agv)]];

        % 更新 jobCompleteUnLoad
        jobCompleteUnLoad(curJob) = insertion.end;

    end
    
end
end