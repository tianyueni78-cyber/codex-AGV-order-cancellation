%% 负载转移时间计算函数
function load_transfer_time = load_transfer_time_compute(start_machine, dest_machine, distance_matrix, load_speed)
% 注：工件完工后，AGV搬运回卸载站的时间，不在此文件计算；
% 故：↘↘↘↘↘↘↘
% 负载转移只有2种情况：
%   1、机器间转移
%   2、装载点到机器
if start_machine == dest_machine
    load_transfer_time = 0;
elseif start_machine == -1  % 2
    load_transfer_time = distance_matrix.load_to_machine(dest_machine) ...
        / load_speed;
else    % 1
    load_transfer_time = distance_matrix.machine_to_machine(start_machine, dest_machine)...
        /load_speed;
end
end