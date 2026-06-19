%% 空载转移时间计算函数
function spare_transfer_time = spare_transfer_time_compute(start_machine, dest_machine, distance_matrix, free_speed)
% 计算转移时间
% 空载移动只5有种情况：
%   1、机器间转移（AGV从装载点运往机器也视为：一次空载转移（转移时间为0）+一次负载转移）
%   2、装载点到机器
%   3、机器到装载站
%   4、卸载站到机器
%   5、卸载站到装载站
if start_machine == dest_machine    % 1
    spare_transfer_time = 0;
elseif start_machine == -1    % 2 装载站到机器
    spare_transfer_time = distance_matrix.load_to_machine(dest_machine) ...
        / free_speed;
elseif start_machine ~= -2 && dest_machine == -1    % 3 机器到装载站
    spare_transfer_time = distance_matrix.load_to_machine(start_machine) ...
        / free_speed;
elseif start_machine == -2    % 4 5 卸载站到装载站 与 卸载站到机器
    if dest_machine == -1
        spare_transfer_time = distance_matrix.load_to_unload / free_speed;
    else
        spare_transfer_time = distance_matrix.machine_to_unload(dest_machine) ...
            / free_speed;
    end
else    % 1 机器到机器
    spare_transfer_time = distance_matrix.machine_to_machine(start_machine, dest_machine)...
        /free_speed;
end
% disp(['agv ', num2str(agv),' spare from ', num2str(start_machine), ' to ', num2str(dest_machine), ' time ', num2str(spare_transfer_time)])
end