function MOEADResult = MOEAD(pop,chrom,max_gen,jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
    AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed)
tstart = tic;               % 计时器
disp('RUNNING --------> MOEA/D <-------- RUNNING')
disp(['工件数：' num2str(jobNum), ' 机器数 ', num2str(machineNum), ' AGV数 ' num2str(AGVNum)]);

% 模型信息
speedNum = length(AGVSpeed);    % AGV速度挡位数目
operaNum = sum(operaVec);       % 工序总数

%% MOEA/D 参数
% [1]. 编码 OS（长度＝总工序数）+MS（长度＝总工序数）＋AS（长度＝总工序数）＋SS（长度＝２＊总工序数）
dim = 5 * operaNum;         % 自变量维度
obj_num = 2;                % 目标函数维度
%pop = 100;                  % 种群数量
%max_gen = 200;              % 最大迭代次数
p_cross = 0.8;              % 交叉概率
p_mutation = 0.2;           % 变异概率
delta = 0.8;                % 参数
T = round(pop / 20);        % 邻居数量

%% 初始化lambda向量，初始化每个个体的邻居
lamda = generateLamda(pop, obj_num);    % 固定参考点：lambda向量
neighbor = get_neighbor(lamda, T);      % 每个个体的邻居（索引）
minobj = [];
%% 种群初始化
%chrom = init(pop, jobNum, operaVec, candidateMachine, AGVNum, speedNum);

% 计算目标函数值
for i = 1 : pop
    func = fitness(chrom(i, :), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
        distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    chrom(i, dim + 1: dim + obj_num) = func{1};
end

obj_min = min(chrom(:, dim + 1: dim + obj_num), [], 1);

%% MOEA/D 主循环
gen = 0;
while gen < max_gen
    for j = 1: pop
        if rand < delta
            index = randperm(T, 1);
            p0 = chrom(neighbor(j, index), :);
        else
            index = randperm(pop, 1);
            p0 = chrom(index, :);
        end

        p1 = [chrom(j, :); p0];

        off_spring = variation(p_cross, p_mutation, p1, jobNum, operaVec, AGVNum, AGVSpeed, candidateMachine);
        for k = 1: size(off_spring, 1)
            if rand < 0.5 % 为了保证和NSGA-II计算次数相等 应设置为0.5
                continue;
            end
            func = fitness(off_spring(k, :), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
                distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
            off_spring(k, dim + 1: dim + obj_num) = func{1};
            obj_min = min([obj_min; off_spring(k, dim + 1: dim + obj_num)], [], 1);
            chrom = update_neighbor(chrom, neighbor(j, :), off_spring(k, :), lamda, obj_min, dim);
        end
    end
    minobj = min([minobj;chrom(:,dim + 1 : dim + obj_num)],[],1);
    gen = gen + 1;

    %% Disp
    fprintf('MOEA/D GEN: %d  MIN Cmax: %.1f  MIN Energy:%.2f\n', gen, minobj(:, 1), minobj(:, 2));
    for k = 1: obj_num
         curve_min(k, gen) = minobj(:, k);
         curve_avg(k, gen) = mean(chrom(:, dim + k));

    end
end

RunTime = toc(tstart);
disp(['运行时间：' num2str(RunTime)]);

%%  将非支配解记录
chrom = non_domination_only(chrom, obj_num, dim);          % 快速非支配排序
chrom = chrom(chrom(:, dim + obj_num + 1) == 1, :);        % 取 rank==1的个体
obj_matrix = chrom(:, dim + 1 : dim + obj_num);
[obj_matrix, uni_index] = unique(obj_matrix, 'rows');
chrom = chrom(uni_index, :);

%% 保存
MOEADResult.RunTime = RunTime;
MOEADResult.chrom = chrom;
MOEADResult.obj_matrix = obj_matrix;
MOEADResult.curve.min = curve_min;
MOEADResult.curve.avg = curve_avg;
for idx = 1: size(chrom, 1)
    [~, MOEADResult.machineTable{idx}, MOEADResult.AGVTable{idx}, ~, MOEADResult.EG_M_SUM{idx}, ...
        MOEADResult.EG_A_SUM{idx}, MOEADResult.agvEGRecord{idx}, MOEADResult.agvChargeNum{idx}]...
        = fitness(chrom(idx, 1: dim), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
        distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
end
end