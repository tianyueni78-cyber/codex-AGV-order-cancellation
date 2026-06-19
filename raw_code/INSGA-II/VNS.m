function vns_chrom = VNS(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num, vns_strategy)
O_S_VNS = split(vns_strategy, '+');
OS_VNS = O_S_VNS{1};
MS_VNS = O_S_VNS{2};
agv_VNS = O_S_VNS{3};

% OS邻域搜索
vns_1 = VNS_OS(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num, OS_VNS);
% MS邻域搜索
vns_2 = VNS_MS(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num, MS_VNS);
% AGV邻域搜索
vns_3 = VNS_AGV(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num, agv_VNS);

vns_chrom = [vns_1; vns_2; vns_3];
end

%% 针对工序的邻域结构
function vns_os_chrom = VNS_OS(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num, os_strategy)
vns_os_chrom = [];
dim = 5 * sum(operaVec);        % 自变量维度
os_dim = sum(operaVec);         % OS编码的维度
temp_chrom = chrom(1: dim);
switch os_strategy
    case 'O1'
        %% VNS -- O1
        % O1：随机选取两个相邻位置工序，倒序后插入任意位置.
        os_index = randperm(os_dim - 1, 1);
        os = temp_chrom([os_index, os_index + 1]);
        % 倒序
        os([1 2]) = os([2 1]);
        % chrom中剔除
        temp_chrom([os_index, os_index + 1]) = [];
        % 倒序后插入任意位置
        insert_pos = randperm(os_dim - 2, 1);   % OS编码已经删除了2位  os_dim - 2
        temp_chrom = [temp_chrom(1: insert_pos) os temp_chrom(insert_pos + 1: end)];

    case 'O2'
        %% VNS -- O2
        % O2：随机删除几个工序，然后按删除的顺序依次插入到工序编码段中
        % 随机删除几个工序，不超过jobNum个  ≤jobNum
        delete_num = randperm(jobNum, 1);
        delete_pos = randperm(os_dim, delete_num);
        delete_os = temp_chrom(delete_pos);
        % 删除
        temp_chrom(delete_pos) = [];
        % 插入
        insert_pos = randperm(os_dim - delete_num, 1);  % OS编码已经删除了delete_num位  os_dim - 2
        temp_chrom = [temp_chrom(1: insert_pos) delete_os temp_chrom(insert_pos + 1: end)];
end

% 若 temp_chrom 不被原来的解支配，才说明搜到的解有效（增加收敛性 或者 增加丰富度）
old_obj = chrom(dim + 1: dim + obj_num);
new_obj = fitness(temp_chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
new_obj = new_obj{1};
if ~ weakly_dominates(old_obj, new_obj)
    vns_os_chrom = [temp_chrom new_obj];
end

end

%% 针对机器的局部搜索
function vns_ms_chrom = VNS_MS(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num, ms_strategy)
vns_ms_chrom = [];
dim = 5 * sum(operaVec);        % 自变量维度
os_dim = sum(operaVec);         % OS编码维度
temp_chrom = chrom(1: dim + obj_num);
switch ms_strategy
    case 'M1'
        %% VNS -- M1
        % M1：将最后一个完成的工序，换一个加工时间最小的机器.
        % [1]. 编码的最后一位修改为 最小时间机器.
        % last_job = temp_chrom(os_dim);
        % last_opera = operaVec(last_job);

        
        % [2]. 随机一道工序
        last_job = randperm(jobNum, 1);
        last_opera = randperm(operaVec(last_job), 1);

        pos = sum(operaVec(1: last_job - 1)) + last_opera;  % 最后一道工序所在的MS编码位置
        machineSet = candidateMachine{last_job, last_opera};
        timeSet = jobInfo{last_job}(last_opera, machineSet);
        [~, min_index] = min(timeSet);
        temp_chrom(os_dim + pos) = min_index;
        temp_chrom_obj = fitness(temp_chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
            distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        temp_chrom(dim + 1: dim + obj_num) = temp_chrom_obj{1};
        
    case 'M2'
        %% VNS -- M2
        % M2：将每一个工件（个体）加工过程中，最高能耗的机器换成另外一台可选设备.
        temp_chrom = LSO_M2_IP(temp_chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
            distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num);
end

% 若 temp_chrom 不被原来的解支配，才说明搜到的解有效（增加收敛性 或者 增加丰富度）
old_obj = chrom(dim + 1: dim + obj_num);
for k = 1: size(temp_chrom, 1)
    new_obj = temp_chrom(k, dim + 1: dim + obj_num);
    if ~ weakly_dominates(old_obj, new_obj)
        vns_ms_chrom = [vns_ms_chrom; temp_chrom(k, 1: dim + obj_num)];
    end
end

end

%% 针对AGV的局部搜索
function vns_as_ss_chrom = VNS_AGV(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num, agv_strategy)
vns_as_ss_chrom = [];
dim = 5 * sum(operaVec);        % 自变量维度
os_dim = sum(operaVec);         % OS编码维度
ms_dim = sum(operaVec);         % MS编码维度
as_dim = sum(operaVec);         % AS编码维度
ss_dim = 2 * sum(operaVec);     % SS编码维度
temp_chrom = chrom(1: dim);

switch agv_strategy
    case 'A1'
        %% A1：在AGV速度编码段上，随机选择两个点位，倒序后插入原位置.
        ss_pos = os_dim + ms_dim + as_dim + randperm(ss_dim, 2);
        ss_code = temp_chrom(ss_pos);
        ss_code([1 2]) = ss_code([2 1]);
        temp_chrom(ss_pos) = ss_code;

    case 'A2'
        %% A2：随机选择充电次数最多的一个AGV，随机选取其负责的r道工序（0＜r＜该AGV总充电次数），换成使用其它可选AGV进行运输
        % 计算充电次数
        [~, ~, ~, ~, ~, ~, ~, agvChargeNum] = fitness(temp_chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, ...
            candidateMachine, distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        [~, max_index] = max(agvChargeNum);
        agv = max_index;
        chrom_as = temp_chrom(os_dim + ms_dim + 1: os_dim + ms_dim + as_dim);  % AS片段
        code_pos = find(chrom_as == agv);
        % r道工序
        rand_r = randperm(length(code_pos), 1);
        rand_r_pos = code_pos(randperm(length(code_pos), rand_r));
        % 去除掉现在所选的agv
        can_set = setdiff((1: AGVNum), agv);
        for k = 1: rand_r
            new_agv = can_set(randperm(length(can_set), 1));
            temp_chrom(os_dim + ms_dim + rand_r_pos(k)) = new_agv;
        end
end

old_obj = chrom(dim + 1: dim + obj_num);
new_obj = fitness(temp_chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
new_obj = new_obj{1};
if ~ weakly_dominates(old_obj, new_obj)
    vns_as_ss_chrom = [temp_chrom new_obj];
end

end


%% 局部搜索算子 M2
function return_chrom = LSO_M2(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num)
operaNum = sum(operaVec);
os_dim = operaNum;          % OS编码维度
dim = 5 * operaNum;         % 编码维度
return_chrom = chrom(1: dim + obj_num);

% 随机选择一道工序
randi_job = randperm(jobNum, 1);
randi_opera = randperm(operaVec(randi_job), 1);
machine_set = candidateMachine{randi_job, randi_opera};

ms_pos = sum(operaVec(1: randi_job - 1)) + randi_opera;
cur_index = chrom(os_dim + ms_pos);

if length(machine_set) > 1
    time = jobInfo{randi_job}(randi_opera, machine_set);
    energy_cost = machineEnergy.work(machine_set);
    total_cost = time' .* energy_cost;
    
    [~, cost_min_index] = min(total_cost);

    if ~ isequal(cost_min_index, cur_index)
        return_chrom(os_dim + ms_pos) = cost_min_index;
        new_obj = fitness(return_chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
            distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        return_chrom(dim + 1: dim + obj_num) = new_obj{1};
    end
end
end

%% 局部搜索算子M2_IP 循环遍历法
function return_chrom = LSO_M2_IP(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num)
operaNum = sum(operaVec);
os_dim = operaNum;          % OS编码维度
dim = 5 * operaNum;         % 编码维度
return_chrom = [];
new_chrom = chrom;

% 随机选择一道工序
randi_job = randperm(jobNum, 1);
randi_opera = randperm(operaVec(randi_job), 1);
machine_set = candidateMachine{randi_job, randi_opera};

ms_pos = sum(operaVec(1: randi_job - 1)) + randi_opera;
cur_index = chrom(os_dim + ms_pos);
old_obj = chrom(dim + 1: dim + obj_num);

if length(machine_set) > 1

    for m = 1: length(machine_set)
        if isequal(m, cur_index)
            continue;
        end
        
        % 编码对应位置改变
        new_chrom(os_dim + ms_pos) = m;
        new_obj_cell = fitness(new_chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
            distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        new_obj = new_obj_cell{1};
        % 比较
        if ~ weakly_dominates(old_obj, new_obj)
            return_chrom = [return_chrom; [new_chrom(1: dim), new_obj]];
        end
    end
end

if isempty(return_chrom)
    return_chrom = chrom;
end
end