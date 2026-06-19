function machine_AGV_gantt_chart(machineTable, AGVTable, chrom, jobNum, operaVec, AGVSpeed)
% 工序参数
os_dim = sum(operaVec);         % OS编码维度
ms_dim = sum(operaVec);         % MS编码维度
as_dim = sum(operaVec);         % AS编码维度
ss_dim = 2 * sum(operaVec);     % SS编码维度
chrom_ss = chrom(os_dim + ms_dim + as_dim + 1: os_dim + ms_dim + as_dim + ss_dim);  % SS片段

% 遍历染色体记住速度
cnt = 0;
for i = 1: jobNum
    for j = 1: operaVec(i)
        cnt = cnt + 1;
        agv_speed_{i, j}(1) = chrom_ss(2 * cnt - 1);
        agv_speed_{i, j}(2) = chrom_ss(2 * cnt);
    end
end


% 机器数量、AGV数量
machine_num = length(machineTable);
AGV_num = length(AGVTable);

% 完工时间
c_max = 0;
for i = 1: machine_num
    c_max = max(c_max, machineTable{i}(length(machineTable{i})).start);
end
for i = 1: AGV_num
    c_max = max(c_max, AGVTable{i}(length(AGVTable{i})).start);
end

% 设置坐标轴
axis([0 c_max + 5 0 machine_num + AGV_num + 0.2]);          % x轴 y轴的范围
set(gca, 'ytick', 0 : 1 : machine_num + AGV_num + 0.2);     % y轴的增长幅度
set(gca, 'box', 'on');

% 拼接y轴标签
str_ = [];
machine_name_cell = cell(machine_num, 1);
for i = 1: AGV_num
    str_ = [str_ ',''AGV' num2str(i), ''''];
end

count = 1;
for m = 1 : machine_num
    str_ = [str_, ',''M_{', num2str(m), '}', ''''];
    machine_name_cell{count} = ['M_{' num2str(m) '}'];
    count = count + 1;
end

str_ = str_(2: length(str_));
str_ = ['0,' str_];
command_line = ['yticklabels({', str_, '})'];
eval(command_line);

% 颜色
color = [];
colorNum = [30 9 8 5 9 6 7 6 5];
for i = 1: length(colorNum)
    for j = 1: colorNum(i)
        color = [color; colorScheme(i, j)];
    end
end

% 画图 --> 机器
rec = [0 0 0 0];
for i = 1: machine_num
    for j = 1: length(machineTable{i})
        if machineTable{i}(j).job == 0 && machineTable{i}(j).opera == 0
            continue;
        end

        rec(1) = machineTable{i}(j).start;          % 矩形的横坐标
        rec(2) = i + AGV_num - 0.20;                          % 矩形的纵坐标
        rec(3) = machineTable{i}(j).end - machineTable{i}(j).start;  % 矩形的x轴方向的长度
        rec(4) = 0.4;%矩形的宽度（高度）

        % 画出矩形
        rectangle('Position', rec, 'LineWidth', 1, 'LineStyle', '-', 'FaceColor', color(machineTable{i}(j).job, :));
        % text标签
%         txt = ['J' num2str(machineTable{i}(j).job) newline sprintf('O%d',machineTable{i}(j).opera)];
          txt = ['(' num2str(machineTable{i}(j).job) ',' num2str(machineTable{i}(j).opera) ')' ];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        text(machineTable{i}(j).start, i + AGV_num-0, txt, 'FontWeight', 'Bold', 'FontSize', 10);
    end
end

% 画图 --> AGV
for i = 1: AGV_num
    for j = 1: length(AGVTable{i})
        if AGVTable{i}(j).job == 0 && AGVTable{i}(j).opera == 0 && AGVTable{i}(j).charge == 0
            continue;
        end

        rec(1) = AGVTable{i}(j).start;          % 矩形的横坐标
        rec(2) = i - 0.20;                          % 矩形的纵坐标
        rec(3) = AGVTable{i}(j).end - AGVTable{i}(j).start;  % 矩形的x轴方向的长度
        rec(4) = 0.4;%矩形的高度（宽度）

        % 画出矩形
        face_color = [1 1 1];
        if AGVTable{i}(j).job ~= 0
            face_color = color(AGVTable{i}(j).job, :);
        end
        rectangle('Position', rec, 'LineWidth', 1, 'LineStyle', '-', 'FaceColor', face_color);
        
        % text标签
%         if AGVTable{i}(j).load_status == -2
%             if AGVTable{i}(j).opera == -1
%                 % 加工完，搬运回仓库速度，默认使用三档
%                 load_speed = 3;
%             else
%                 load_speed = agv_speed_{AGVTable{i}(j).job, AGVTable{i}(j).opera}(2);
%             end
% 
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             %txt = ['V' num2str(load_speed) newline sprintf('J%d',AGVTable{i}(j).job)];
%                 %txt = ['' newline sprintf('J%d',AGVTable{i}(j).job)];
%                 %txt = ['' newline sprintf('V%d',load_speed)];
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%         elseif AGVTable{i}(j).load_status == -1
%             if AGVTable{i}(j).charge == 2
%                 % 空载前往充电，默认使用三档
%                 unload_speed = 3;
%             else
%                 if AGVTable{i}(j).opera == -1
%                     % 空载搬运加工完的工件回仓库，默认使用三档
%                     unload_speed = 3;
%                 else
%                     unload_speed = agv_speed_{AGVTable{i}(j).job, AGVTable{i}(j).opera}(1);
%                 end
%             end
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%              %txt = ['V' num2str(unload_speed) newline sprintf('')];
%                 txt = [''];
                %txt = ['' newline sprintf('V%d',unload_speed)];
%           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               
%         elseif AGVTable{i}(j).charge == 1
%             txt = ['' newline sprintf('充电')];
%         end
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
       % text(AGVTable{i}(j).start, i, txt, 'FontWeight', 'Bold', 'FontSize', 10);
        %text(AGVTable{i}(j).start, i-0.4, txt1, 'FontWeight', 'Bold', 'FontSize', 12);
        % 位置标签
        %text(max(0, AGVTable{i}(j).start - 0.5), i + 0.45, get_label(AGVTable{i}(j).from_machine, machine_name_cell), 'FontWeight', 'Bold', 'FontSize', 8);
        %text(max(0, AGVTable{i}(j).end - 0.5), i + 0.45, get_label(AGVTable{i}(j).to_machine, machine_name_cell), 'FontWeight', 'Bold', 'FontSize', 8);
    end
end
end


% function machine_label = get_label(str, name_cell)
% 
% if str == -1
%     machine_label = '';
% elseif str == -2
%     machine_label = '';
% else
%     machine_label = name_cell{str};
% end
% end