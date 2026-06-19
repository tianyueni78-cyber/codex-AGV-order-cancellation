function NSSA_Result = MOSSA(pop,max_gen,jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
    AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed)
tstart = tic;               % 计时器
disp('RUNNING --------> MOSSA <-------- RUNNING')
disp(['工件数：' num2str(jobNum), ' 机器数 ', num2str(machineNum), ' AGV数 ' num2str(AGVNum)]);

% 模型信息
operaNum = sum(operaVec);       % 工序总数

%% MOSSA 参数
% [1]. 编码 OS（长度＝总工序数）+MS（长度＝总工序数）＋AS（长度＝总工序数）＋SS（长度＝２＊总工序数）
dim = 5 * operaNum;         % 自变量维度
obj_num = 2;                % 目标函数维度
LB = -jobNum * ones(1, dim);% 自变量下界
UB = jobNum * ones(1, dim); % 自变量上界
%max_gen = 200;        % 最大迭代次数
%pop = 100;      % 种群规模

% 初始化外部存档
archive_size = 60;%存档大小

% ★★改进1：改进的Tent混沌映射种群初始化★★
%% 混沌序列
% 改进的Tent 注意有时候这个初始化会是周期 和初始值y有关
y=rand; 
x(1) = y;
Alpa=0.5;
for i=2:1000
    if x(i-1)<=Alpa
        x(i)=x(i-1)/Alpa+rand/1000;
    else
        x(i)=(1-x(i-1))/(1-Alpa)+rand/1000;
    end
end
clear x Z

y=rand(1,dim); 
Z(1,:) = y;
Alpa=0.5;
for i=2:pop
    for j=1:dim
        if Z(i-1,j)<=Alpa
            Z(i,j)=Z(i-1,j)/Alpa+rand(1)/pop;
        else
            Z(i,j)=(1-Z(i-1,j))/(1-Alpa)+rand(1)/pop;
        end
        if Z(i,j)>-jobNum || Z(i,j)<jobNum
            Z(i,j)=rand;
        end
    end
end
for i = 1 : pop
    chrom(i, :) = -jobNum + 2*jobNum .* Z(i,:);
end
% 随机初始化 实数编码 编码范围: [-jobNum, jobNum]
%chrom = rand(pop, dim) * 2 * jobNum - jobNum;
% 计算目标函数值 并加入编码染色体尾部
for i = 1 : pop
    func = fitness(chrom(i, :), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
        distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    chrom(i, dim + 1: dim + obj_num) = func{1};
end

% 快速非支配排序，并计算拥挤度 --> 并将非支配等级、拥挤度加入到编码个体尾部
chrom = non_domination(chrom, obj_num, dim);
external_archive = chrom(:,1:dim + obj_num);
%% NSSA主循环
% 文献改进方法：自适应种群（ST、p_E、p_D 参数自适应）
ST_max = 0.9;
ST_min = 0.7;
p_E_max = 0.6;
p_E_min = 0.4;
p_D_max = 0.9;
p_D_min = 0.2;

Iteration = 1;
newPOS = zeros(pop, dim + obj_num);
while Iteration <= max_gen
    % 自适应ASSA：计算 ST、p_E、p_D
    ST = (ST_max + ST_min)/2 + (ST_max - ST_min)/2 * tanh(-4 + 8*Iteration/max_gen);
    p_E = (p_E_max + p_E_min)/2 + (p_E_max - p_E_min)/2 * tanh(-4 + 8*Iteration/max_gen);
    m_E = round(pop * p_E);
    p_D = (p_D_max + p_D_min)/2 + (p_D_max - p_D_min)/2 * tanh(-4 + 8*(max_gen-Iteration)/max_gen);
    m_D = round(pop * p_D);

    % 随机选择 Pareto rank == 1 的个体作为best
    % best individual
    rank_first_idx = find(chrom(:, dim + obj_num + 1) == 1);
    bestPOS = chrom(rank_first_idx(randperm(length(rank_first_idx), 1)), 1: dim + obj_num);

    % 随机选择非支配等级最低的个体作为worst
    % worst individual
    rank_last = chrom(size(chrom, 1), dim + obj_num + 1);
    rank_last_idx = find(chrom(:, dim + obj_num + 1) == rank_last);
    worstPOS = chrom(rank_last_idx(randperm(length(rank_last_idx), 1)), 1: dim + obj_num);

    for i = 1 : pop
        % explorers of sparrows.
        if i <= m_E
            if(rand < ST)
                r1 = rand;
                newPOS(i, 1: dim) = chrom(i, 1: dim) * exp(-i / (r1 * max_gen));
            else
                Q = randn(1);                               % 标准正态分布
                newPOS(i, 1: dim) = chrom(i, 1: dim) + Q * ones(1, dim);
            end

        % followers of sparrows.
        else
            if( i > pop/2)
                Q = randn(1); 
                newPOS(i, 1: dim) = Q * exp((worstPOS(1: dim) - chrom(i, 1: dim)) / i^2);
            else
                A = floor(rand(1, dim) * 2) * 2 - 1;
                newPOS(i, 1: dim) = bestPOS(1: dim) + abs((chrom(i, 1: dim) - bestPOS(1: dim))) * (A' * (A * A') ^ (-1)) * ones(1, dim);  
            end
        end

        newPOS(i, 1: dim) = bound(newPOS(i, 1: dim), UB, LB);                   % 越界判断
        func = fitness(newPOS(i, 1: dim), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
            distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        newPOS(i, dim + 1: dim + obj_num) = func{1};    % 计算函数值
    end
    
    % defenders of sparrows.
    randi_pop = randperm(pop);
    defender_pop = randi_pop(1: m_D);
    for d = 1: numel(defender_pop)
        d_index = defender_pop(d);
        
        % 经典方法
        fitnewpos = sum(abs(chrom(d_index, dim + 1: dim + obj_num)));
        fMin = sum(abs(bestPOS(dim + 1: dim + obj_num)));% 计算函数值      
        if fitnewpos > fMin
            newPOS(d_index, 1: dim) = bestPOS(1: dim) + randn(1, dim) .* (abs((chrom(d_index, 1: dim) - bestPOS(1: dim)))); 
        else
            fmax = sum(worstPOS(dim + 1: dim + obj_num));% 计算函数值      
            newPOS(d_index, 1: dim) = chrom(d_index, 1: dim) + (2 * rand - 1) * (abs(chrom(d_index, 1: dim) - worstPOS(1: dim))) / (fitnewpos - fmax + 1E-6);   
        end

        newPOS(d_index, 1: dim) = bound(newPOS(d_index, 1: dim), UB, LB);              % 越界判断
        func = fitness(newPOS(d_index, 1: dim), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
            distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        newPOS(d_index, dim + 1: dim + obj_num) = func{1};  % 计算函数值
    end
    
    for i= 1:pop/4
            % ★★改进3：趋优反向学习★★
            new_p = -newPOS(i,1:dim);
            old_obj = newPOS(i, dim + 1: dim + obj_num);
            new_obj = fitness(new_p, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
                    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
            new_obj = new_obj{1};
            if is_B_strongly_dominating_A(old_obj,new_obj)
                newPOS(i, 1:dim+obj_num) = [new_p new_obj];
            end
     end





    %% 更新种群Pop(t)和Arc
    % 合并Pop(t)和newPOS
%     intermediate_Pop(1: pop, :) = chrom;
%     intermediate_Pop(pop + 1: 2 * pop, 1: dim + obj_num) = newPOS;

    for ii = 1:pop
        new_individual = newPOS(ii, 1:dim + obj_num);  % 获取当前个体
        % 检查个体与外部存档中的个体的支配关系
        dominated_flag = 0;  % 标记个体是否被外部存档中的个体支配
        to_remove = [];  % 存储需要从外部存档中移除的个体的索引
        nownum_archive = size(external_archive,1);
        for jj = 1:nownum_archive
            archive_individual = external_archive(jj,:);%第j个存档个体
            if archive_individual(1,dim + 1) <= new_individual(1,dim + 1)&&...
                    archive_individual(1,dim + 2)<=new_individual(1,dim +2)
                % 个体被外部存档中的某个个体支配
                dominated_flag = 1;
                break;
            elseif archive_individual(1,dim+1)>new_individual(1,dim + 1)&&...
                    archive_individual(1,dim + obj_num)>new_individual(1,dim + obj_num)
                % 外部存档中的个体被个体支配，标记需要移除
                to_remove = [to_remove,jj];%存储索引值
            end
        end
        if  dominated_flag == 0
            % 如果个体未被外部存档中的任何个体支配，则将其加入外部存档
            external_archive = [external_archive; new_individual];
        end
        if size(to_remove,2) ~= 0
            external_archive(to_remove, :) = [];
        end
    end

%     % 执行裁剪以保持多样性
%     if size(external_archive, 1) > archive_size
%        % 计算拥挤度距离
%         intermediate_Pop = non_domination(external_archive, obj_num, dim);
%         external_archive = intermediate_Pop(1: archive_size, :);
%         chrom =  external_archive;
%     elseif size(external_archive, 1) < archive_size
%         % 合并外部存档和子代种群
%         combined_population = [external_archive; newPOS(:,1:dim + obj_num)];
%         [unique_rows, ~, unique_indices] = unique(combined_population(:, 1:dim), 'rows');
%         combined_population = combined_population(unique_indices, :);
%         intermediate_Pop = non_domination(combined_population, obj_num, dim);
%         % 最终的种群大小为 pop
%         chrom = intermediate_Pop(1:pop, :);
%     end

    % 执行裁剪以保持多样性
    if size(external_archive, 1) > archive_size
       % 计算拥挤度距离
        intermediate_Pop = non_domination(external_archive, obj_num, dim);
        external_archive = intermediate_Pop(1: archive_size, 1:dim+obj_num);
    end
        % 合并外部存档和子代种群
        combined_population = [external_archive; newPOS(:,1:dim + obj_num)];
        [unique_rows, ~, unique_indices] = unique(combined_population(:, 1:dim), 'rows');
        combined_population = combined_population(unique_indices, :);
        intermediate_Pop = non_domination(combined_population, obj_num, dim);
        % 最终的种群大小为 pop
        chrom = intermediate_Pop(1:pop, :);
    
    %% 打印、保存
    % 迭代曲线
    for k = 1: obj_num
        curve_min(k, Iteration) = min(chrom(:, dim + k));
        curve_avg(k, Iteration) = mean(chrom(:, dim + k));
    end
    fprintf('NSSA GEN: %d  MIN Cmax: %.1f  MIN Energy:%.2f\n', Iteration, min(chrom(:, dim + 1)), min(chrom(:, dim + 2)));

    Iteration = Iteration + 1;
end

RunTime = toc(tstart);
disp(['运行时间：' num2str(RunTime)]);

%% 结果保存
chrom = chrom(chrom(:, dim + obj_num + 1) == 1, :);
Arc = chrom(:, dim + 1: dim + obj_num);
[obj_matrix, uni_idx] = unique(Arc, 'rows');

NSSA_Result.RunTime = RunTime;
NSSA_Result.obj_matrix = obj_matrix;
NSSA_Result.pop = chrom(uni_idx, :);
NSSA_Result.curve.min = curve_min;
NSSA_Result.curve.avg = curve_avg;
for idx = 1: size(NSSA_Result.pop, 1)
    [~, NSSA_Result.machineTable{idx}, NSSA_Result.AGVTable{idx}, ~, NSSA_Result.EG_M_SUM{idx}, ...
        NSSA_Result.EG_A_SUM{idx}, NSSA_Result.agvEGRecord{idx}, NSSA_Result.agvChargeNum{idx}]...
        = fitness(NSSA_Result.pop(idx, 1: dim), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
        distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
end

end

%% Check the boundary limit
function a=bound(a,ub,lb)
if rand<0.5
    a(a>ub)=ub(a>ub);
    a(a<lb)=lb(a<lb);
else
    a(a>ub)=rand*(ub(a>ub)-lb(a>ub))+lb(a>ub);
    a(a<lb)=rand*(ub(a<lb)-lb(a<lb))+lb(a<lb);
end
end
