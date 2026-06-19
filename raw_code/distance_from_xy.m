function distance_from_xy(machine_num)
xy_excel = xlsread('机器数据.xlsx', '机器仓库坐标');

% 卸载/装载站个数 ==> 前station_num个分别为装载、卸载站
station_num = 2;

%% 存入Excel里，装卸站到机器距离
d_res_total = [];
for i = 1: station_num
    d_res = [];
    for j = 1 + station_num: machine_num  + station_num
        d = abs(xy_excel(i, 1) - xy_excel(j, 1)) + abs(xy_excel(i, 2) - xy_excel(j, 2));
        d_res = [d_res d];
    end
    d_res_total = [d_res_total; d_res];
end

xlswrite('机器数据.xlsx', ' ', '装卸站到机器距离', 'A1:T20');
xlswrite('机器数据.xlsx', d_res_total, '装卸站到机器距离');

%% 存入Excel里， 机器到机器的距离
d_res_total = [];
for i = 1: machine_num
    d_res = [];
    for j = 1: machine_num
        d = abs(xy_excel(i + station_num, 1) - xy_excel(j + station_num, 1)) + abs(xy_excel(i + station_num, 2) - xy_excel(j + station_num, 2));
        d_res = [d_res d];
    end
    d_res_total = [d_res_total; d_res];
end

xlswrite('机器数据.xlsx', ' ', '机器到机器距离', 'A1:T20');
xlswrite('机器数据.xlsx', d_res_total, '机器到机器距离');

end