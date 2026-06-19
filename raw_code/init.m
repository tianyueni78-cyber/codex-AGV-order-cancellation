function chrom = init(pop, jobNum, operaVec, candidateMachine, AGVNum, speedNum)
%% 由 OS MS AS SS 四部分组成
% OS：工序编码
% MS：机器编码
% AS：AGV编码
% SS：AGV速度挡位编码
chrom = [];
operaNum = sum(operaVec);
opera = [];

%% OS段编码
for i = 1: jobNum
    opera = [opera, ones(1, operaVec(i)) * i];
end
% 将 opera 复制 pop 次以构成一个 pop*operaNum 的矩阵
B = repmat(opera, pop, 1);
%调用chaos
z_os = chaos(pop,operaNum);
% 对每一行进行排序
sorted_z = sort(z_os, 2);
% 这里生成一个矩阵，存储排序的等级数
sorted_ranks = zeros(pop,operaNum);
for i = 1:pop
    [~, ranks] = ismember(z_os(i, :), sorted_z(i, :));  % 找到原始矩阵中每个元素在排序后的位置
    sorted_ranks(i, :) = ranks;  % 存储排序的等级数
end
%%存储排序过后的OS矩阵
OS = zeros(pop,operaNum);
for i = 1:pop
    [~, idx] = sort(sorted_ranks(i, :));
    OS(i, :) = B(i, idx);
end

%% MS段编码
z_ms = chaos(pop,operaNum);
%获取每个个体的工件的工序的可用机器数量（上界）
MS = [];
upper_bound = [];
for i = 1: pop
    Mijk_num = [];
    for j = 1: jobNum
        for k = 1: operaVec(j)
            if isempty(candidateMachine{j, k})
                continue; % 如果存在空值，则跳过剩余部分
            end
            Mijk_num = [Mijk_num, length(candidateMachine{j, k})];
        end
    end
    upper_bound = repmat(Mijk_num, pop, 1);
end
MS = ceil(z_ms .* upper_bound);

%% AGV编码段
z_as = chaos(pop,operaNum);
upper_bound = AGVNum;
AS = ceil(z_as .* upper_bound);

%% AGV速度编码段
z_ss = chaos(pop,2*operaNum);
upper_bound = speedNum;
SS = ceil(z_ss .* upper_bound);

%% 合并长度5*operaNum的染色体种群
chrom = [OS,MS,AS,SS];
end

%% 构建tent映射函数
function z = chaos(pop, operaNum)
N = pop;
D = operaNum;
% 1) 生成初始的随机向量 z1
z1 = rand(1, D);
% 2) 计算剩余分量
z = zeros(N, D);
z(1, :) = z1;
for i = 2:N
    for j = 1:D
        if z(i-1,j) < 0.5
            z(i,j) = 2 * z(i-1,j);
        else
            z(i,j) = 2 * (1 - z(i-1,j));
        end
        if z(i,j) == 0 || z(i,j) == 0.25 || z(i,j) == 0.5 || z(i,j) == 0.75
            z(i,j) = rand() * z(i,j);
        end
        if (i>1&&z(i,j)==z(i-1,j)) || (i>2&&z(i,j)==z(i-2,j)) ||...
                (i>3&&z(i,j)==z(i-3,j)) || (i>4&&z(i,j)==z(i-4,j))
            z(i,j) = rand() * z(i,j);
        end
    end
end
end