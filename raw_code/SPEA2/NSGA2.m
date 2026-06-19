function NSGA2_Result = NSGA2(p_cross,p_mutation,pop,chrom,max_gen,jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
    AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed)
tstart = tic;               % 计时器
disp('RUNNING --------> NSGA-II <-------- RUNNING')
disp(['工件数：' num2str(jobNum), ' 机器数 ', num2str(machineNum), ' AGV数 ' num2str(AGVNum)]);

% 模型信息
speedNum = length(AGVSpeed);    % AGV速度挡位数目
operaNum = sum(operaVec);       % 工序总数

%% NSGA-II 参数
% [1]. 编码 OS（长度＝总工序数）+MS（长度＝总工序数）＋AS（长度＝总工序数）＋SS（长度＝２＊总工序数）
dim = 5 * operaNum;         % 自变量维度
obj_num = 2;                % 目标函数维度
%pop = 100;                  % 种群数量
pool = round(pop / 2);      % 锦标赛选择法参数 pool_size
tour = 2;                   % 锦标赛选择法参数 tour_size
%max_gen = 5;              % 最大迭代次数
%p_cross = 0.6;              % 交叉概率
%p_mutation = 0.4;           % 变异概率

%% 种群初始化
%chrom = init(pop, jobNum, operaVec, candidateMachine, AGVNum, speedNum);
for i = 1 : pop
    func = fitness(chrom(i, :), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
        distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    chrom(i, dim + 1: dim + obj_num) = func{1};
end
% 快速非支配排序 + 拥挤度计算 ==> 放置在染色体尾部
chrom = non_domination(chrom, dim, obj_num);

%% 迭代主循环
gen = 0;
while gen < max_gen
    % 锦标赛法
    parent_ = tournament_selection(chrom, pool, tour);

    % 交叉、变异
    offspring_ = variation(p_cross, p_mutation, parent_, jobNum, operaVec, AGVNum, AGVSpeed, candidateMachine);
    for i = 1: size(offspring_, 1)
        func = fitness(offspring_(i, :), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
            distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        offspring_(i, dim + 1: dim + obj_num) = func{1};
    end

    % 合并种群
    intermediate_ = [chrom(:, 1: dim + obj_num); offspring_(:, 1: dim + obj_num)];
    intermediate_ = non_domination(intermediate_, dim, obj_num);

    % 精英保留
    chrom = replace_chrom(intermediate_, dim, obj_num, pop);
    gen = gen + 1;

    %% Disp
    fprintf('GEN: %d  MIN Cmax: %.1f  MIN Energy:%.2f\n', gen, min(chrom(:, dim + 1)), min(chrom(:, dim + 2)));
    for k = 1: obj_num
        curve_min(k, gen) = min(chrom(:, dim + k));
        curve_avg(k, gen) = mean(chrom(:, dim + k));
    end
end
RunTime = toc(tstart);
disp(['运行时间：' num2str(RunTime)]);

%%  将非支配解记录
chrom = chrom(chrom(:, dim + obj_num + 1) == 1, :);        % 支配等级为1的个体
obj_matrix = chrom(:, dim + 1: dim + obj_num);
[obj_matrix, uni_index] = unique(obj_matrix, 'rows');
chrom = chrom(uni_index, :);

%% 保存
NSGA2_Result.RunTime = RunTime;
NSGA2_Result.chrom = chrom;
NSGA2_Result.obj_matrix = obj_matrix;
NSGA2_Result.curve.min = curve_min;
NSGA2_Result.curve.avg = curve_avg;
for idx = 1: size(chrom, 1)
    [~, NSGA2_Result.machineTable{idx}, NSGA2_Result.AGVTable{idx}, ~, NSGA2_Result.EG_M_SUM{idx}, ...
        NSGA2_Result.EG_A_SUM{idx}, NSGA2_Result.agvEGRecord{idx}, NSGA2_Result.agvChargeNum{idx}]...
        = fitness(chrom(idx, 1: dim), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
        distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
end