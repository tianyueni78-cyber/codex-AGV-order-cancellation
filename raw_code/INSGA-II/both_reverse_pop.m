function chrom = reverse_pop(chrom, jobNum, operaVec, candidateMachine, AGVNum, AGVSpeedNum)
os_dim = sum(operaVec);     % OS编码维度
ms_dim = sum(operaVec);     % MS编码维度
as_dim = sum(operaVec);     % AS编码维度
ss_dim = 2 * sum(operaVec);     % SS编码维度
chrom_os = chrom(1: os_dim);                    % OS片段
chrom_ms = chrom(os_dim + 1: os_dim + ms_dim);  % MS片段
chrom_as = chrom(os_dim + ms_dim + 1: os_dim + ms_dim + as_dim);  % AS片段
chrom_ss = chrom(os_dim + ms_dim + as_dim + 1: os_dim + ms_dim + as_dim + ss_dim);  % SS片段

% %%部分反向
% % OS编码反转
% os = chrom_os;
% ms = chrom_ms;
% as = chrom_as;
% ss = chrom_ss;
% 
% if rand<0.25
%     %OS编码反转
%     os = reverse_os(chrom_os, jobNum, operaVec);
% elseif rand<0.5&&rand>=0.25
%     %MS编码反转
%     ms = reverse_ms(chrom_ms, jobNum, operaVec, candidateMachine);
% elseif rand<0.75&&rand>=0.5
%     %AS编码反转
%     as = reverse_as(chrom_as, AGVNum);
% else
%     %SS编码反转
%     ss = reverse_ss(chrom_ss, AGVSpeedNum);
% end

os = reverse_os(chrom_os, jobNum, operaVec);
ms = reverse_ms(chrom_ms, jobNum, operaVec, candidateMachine);
as = reverse_as(chrom_as, AGVNum);
ss = reverse_ss(chrom_ss, AGVSpeedNum);
%合并 OS MS
chrom = [os ms as ss];
% 
end

%% OS编码反转
function os_chrom = reverse_os(os_chrom, jobNum, operaVec)
OS_MAX = jobNum;
OS_MIN = 1;
%部分反转
% for i  = 1:length(os_chrom)
%     if rand<0.3
%         os_chrom(i) = OS_MAX + OS_MIN - os_chrom(i);
%     end
% end

% %部分反转
% for i = 1:length(os_chrom)
%     % 生成介于 0 和 1 之间的随机数
%     reverse_os = rand();
%     % 将 os_chrom(i) 乘以反向系数并四舍五入到最接近的整数
%     os_chrom(i) = ceil(reverse_os * (OS_MAX + OS_MIN)) - os_chrom(i);
%     % 检查是否在 OS_MAX 和 OS_MIN 之间
%     if os_chrom(i) < OS_MIN || os_chrom(i) > OS_MAX
%         % 生成一个随机整数在 OS_MIN 和 OS_MAX 之间
%         os_chrom(i) = randi([OS_MIN, OS_MAX]);
%     end
% end

%单段内全反转
os_chrom = OS_MAX + OS_MIN - os_chrom;

% 修复个体
job_rec = zeros(1, jobNum);
for i = 1: length(os_chrom)
    job_rec(os_chrom(i)) = job_rec(os_chrom(i)) + 1;
end

% opera_diff: >0 表示工序变多了  <0 表示工序变少了
opera_diff = job_rec - operaVec;
% opera_less: 变少的工序
% opera_more：变多的工序
% 将 opera_more 中替换为 opera_less
opera_less = [];
opera_more = [];
for i = 1: length(opera_diff)
    if opera_diff(i) < 0
        opera_less = [opera_less ones(1, -1 * opera_diff(i)) * i];
    end
    if opera_diff(i) > 0
        opera_more = [opera_more ones(1, opera_diff(i)) * i];
    end
end

% 替换
opera_less = opera_less(randperm(length(opera_less)));  % 随机打乱保证随机性
for i = 1: length(opera_more)
    delete_index = find(os_chrom == opera_more(i));
    delete_pos = delete_index(randperm(length(delete_index), 1));
    os_chrom(delete_pos) = opera_less(i);
end
end

%% MS编码反转
function ms_chrom = reverse_ms(ms_chrom, jobNum, operaVec, candidateMachine)
% 每个 MS 编码位，修改为其它机器
cnt = 0;
for i = 1: jobNum
    for j = 1: operaVec(i)
        cnt = cnt + 1;
        machine_set = candidateMachine{i, j};
%         if length(machine_set) < 2|| rand > 0.3
        if length(machine_set) < 2
            continue
        end

        % 修改为其他机器
        cur_index = ms_chrom(cnt);
        can = setdiff((1: length(machine_set)), cur_index);
        ms_chrom(cnt) = can(randperm(length(can), 1));
    end
end
end

%% AS编码反转
function as_chrom = reverse_as(as_chrom, AGVNum)
% for i = 1:length(as_chrom)
%     if rand<0.3
%         as_chrom(i) = AGVNum + 1 - as_chrom(i);
%     end
% end

% for i = 1:length(as_chrom)
%     % 生成介于 0 和 1 之间的随机数
%     reverse_as = rand();
%     % 将 os_chrom(i) 乘以反向系数并四舍五入到最接近的整数
%     as_chrom(i) = ceil(reverse_as * (AGVNum+1)) - as_chrom(i);
%     if as_chrom(i) < 1 || as_chrom(i) > AGVNum
%         % 生成一个随机整数在 1 和 AGVNum 之间
%        as_chrom(i) = randi([1, AGVNum]);
%     end
% end


%AGV段内全反转
as_chrom = AGVNum + 1 - as_chrom;
end

%% SS编码反转
function ss_chrom = reverse_ss(ss_chrom, AGVSpeedNum)
% for i = 1:length(ss_chrom)
%     if rand<0.3
%         ss_chrom(i) = AGVSpeedNum + 1 - ss_chrom(i);
%     end
% end

% for i = 1:length(ss_chrom)
%     % 生成介于 0 和 1 之间的随机数
%     reverse_ss = rand();
%     % 将 os_chrom(i) 乘以反向系数并四舍五入到最接近的整数
%     ss_chrom(i) = ceil(reverse_ss * (AGVSpeedNum + 1)) - ss_chrom(i);
%     if ss_chrom(i) < 1 || ss_chrom(i) > AGVSpeedNum
%         % 生成一个随机整数在 1 和 AGVNum 之间
%        ss_chrom(i) = randi([1, AGVSpeedNum]);
%     end
% end

%段内全反转
ss_chrom = AGVSpeedNum + 1 - ss_chrom;
end