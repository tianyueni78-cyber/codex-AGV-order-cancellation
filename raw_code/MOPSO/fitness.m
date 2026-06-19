function [FUNC, machineTable, AGVTable, makespan, EG_M_SUM, EG_A_SUM, agvEGRecord, agvChargeNum] = ...
    fitness(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed)
%% machineTable 记录每个机器的工作时间表
% 建立结构体 workTable
workTable = [];
workTable.start = 0;    % 开始时间
workTable.end = Inf;    % 结束时间
workTable.job = 0;      % 加工的工件号：0表示空闲
workTable.opera = 0;    % 加工的工序号
% 初始化machineTable
for i = 1 : machineNum
    machineTable{1, i} = workTable;
end

%% AGVTable 记录每个AGV的移动时间表
% 建立结构体 transferTable
transferTable = [];
transferTable.start = 0;
transferTable.end = Inf;
transferTable.job = 0;          % 搬运的工件号
transferTable.opera = 0;        % 搬运的工序号
transferTable.load_status = 0;  % 搬运的状态   -1 空载转移  -2 负载转移
transferTable.from_machine = -1;    % 从哪个机器出发： -1：装载站  -2：卸载站  -3：充电桩（卸载站） 0：空闲 其余代表机器编号
transferTable.to_machine = 0;       % 同上
transferTable.charge = 0;       % 0 正常状态  1 充电状态  2 前往充电状态
% 初始化 AGVTable
for i = 1 : AGVNum
    AGVTable{1, i} = transferTable;
end

%% 解码排序
[machineTable, AGVTable, jobCompleteUnLoad, agvEGRecord, agvChargeNum] = sorting(chrom, jobNum, jobInfo, operaVec, AGVNum, ...
    AGVSpeed, candidateMachine, distance_matrix, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, machineTable, AGVTable);

% 仅供调试检查使用
% figure(1)
% machine_AGV_gantt_chart(machineTable, AGVTable);
% figure(2)
% ag_str = [];
% for ag = 1: AGVNum
%     ag_str = [ag_str ',''AGV' num2str(ag), ''''];
% end
% ag_str = ag_str(2: end);
%
% color = ['r'; 'g'; 'b'; 'y'; 'c'];
% for ag = 1: AGVNum
%     plot(agvEGRecord{ag}(:, 1), agvEGRecord{ag}(:, 2), [color(ag) '-s'], 'MarkerEdgeColor', 'k', 'MarkerFaceColor', color(ag), 'LineWidth', 1.0);
%     hold on
%     for i = 1: size(agvEGRecord{ag}, 1)
%         txt = sprintf('%0.2f Kw', agvEGRecord{ag}(i, 2));
%         text(agvEGRecord{ag}(i, 1) + 1, agvEGRecord{ag}(i, 2) - 1, txt, 'FontWeight', 'Bold', 'FontSize', 8)
%         hold on
%     end
% end
% eval(['legend(' ag_str ', ''Location'', ''NorthEastOutside'')'])

%% 目标函数 1 ：makespan
makespan = max(jobCompleteUnLoad);

%% 目标函数 2：总能耗
%
% [1]. 机器能耗
machine_work = zeros(machineNum, 1);
machine_spare = zeros(machineNum, 1);
for i = 1: machineNum
    for j = 1: length(machineTable{i})
        if isequal(machineTable{i}(j).end, inf)
            continue;
        end

        if isequal(machineTable{i}(j).job, 0)
            machine_spare(i) = machine_spare(i) + (machineTable{i}(j).end - machineTable{i}(j).start);
        else
            machine_work(i) = machine_work(i) + (machineTable{i}(j).end - machineTable{i}(j).start);
        end
    end
end

EG_M_SUM = machineEnergy.work(1: machineNum)' * machine_work + machineEnergy.free(1: machineNum)' * machine_spare;

% [2]. AGV能耗
% 通过电量即可计算
EG_AGV = zeros(1, AGVNum);
for i = 1: AGVNum
    for j = 1: size(agvEGRecord{i}, 1)
        if j == 1
            continue;
        end

        if agvEGRecord{i}(j - 1, 2) - agvEGRecord{i}(j, 2) < 0
            continue;
        end

        EG_AGV(i) = EG_AGV(i) + agvEGRecord{i}(j - 1, 2) - agvEGRecord{i}(j, 2);
    end
end

EG_A_SUM = sum(EG_AGV);

FUNC = {[makespan, EG_M_SUM + EG_A_SUM]};

end