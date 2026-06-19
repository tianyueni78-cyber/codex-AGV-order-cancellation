function total_pop = improved_elitism(pop,reverse_percent,jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, obj_num)
N = size(pop, 1);           % 种群规模
N_reverse = round(N * reverse_percent);   % 执行反向生成的种群的规模

%elitism_pop = pop(N - N_reverse + 1: N, :);%后N个
elitism_pop = pop(1:N_reverse,:);%前N个
%随机N个
% random_indices = randperm(N, N_reverse);
% %使用随机索引从 pop 中选择个体
% elitism_pop = pop(random_indices, :);
% 
% % 获取未选择的个体的索引
% unselected_indices = setdiff(1:N, random_indices);
% % 使用 unselected_indices 从 pop 中获取未选择的个体
% norand = pop(unselected_indices, :);


AGVSpeedNum = length(AGVSpeed); % AGV速度挡位

dim = 5 * sum(operaVec);    % 自变量维度
reversed_pop = [];
strong_pop = [];
strongnum = 0;

for i = 1: N_reverse
    % 反向生成
    new_p = reverse_pop(elitism_pop(i, 1: dim), jobNum, operaVec, candidateMachine, AGVNum, AGVSpeedNum);
    % 计算支配关系 
    % 互不支配关系也视为得到改善
    old_obj = elitism_pop(i, dim + 1: dim + obj_num);
    new_obj = fitness(new_p, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
        distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    new_obj = new_obj{1};

    if ~ weakly_dominates(old_obj, new_obj)
           reversed_pop = [reversed_pop; [new_p new_obj]];
    end
  

end
%测试反向生成个体效果 
%num_individuals_in_reverse_pop = size(reversed_pop, 1);
%disp(['反向学习生成 ' num2str(num_individuals_in_reverse_pop) ' 个非支配解。']);

% 合并种群
%total_pop = [elitism_pop(:, 1: dim + obj_num); reversed_pop;pop(1+N_reverse:N,1: dim + obj_num)];
total_pop = [pop(:, 1: dim + obj_num); reversed_pop];
%前N个
%total_pop = [pop(1+N_reverse:N,1: dim + obj_num);elitism_pop(:, 1: dim + obj_num)];
%后N个
%total_pop = [pop(1:N-N_reverse,1: dim + obj_num);reversed_pop(:, 1: dim + obj_num)];%后N个
%随机N个
%total_pop = [norand(:,1: dim + obj_num);elitism_pop(:, 1: dim + obj_num)];%随机N个

% 快速非支配排序
total_pop = non_domination(total_pop, dim, obj_num);

% 精英保留
total_pop = total_pop(1: N, :);
end