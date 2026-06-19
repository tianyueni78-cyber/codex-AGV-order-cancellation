clc
clear
close all

% 读取 Excel 文件中的数据（将文件名替换为你的文件路径）
excelFileName = 'Parameter_ testing.xlsx';

data1 = xlsread(excelFileName, 'Sheet9','A:B');
data2 = xlsread(excelFileName, 'Sheet9','C:D');
data3 = xlsread(excelFileName, 'Sheet9','E:F');
data4 = xlsread(excelFileName, 'Sheet9','G:H');
data1 = data1(~any(isnan(data1), 2), :);
data2 = data2(~any(isnan(data2), 2), :);
data3 = data3(~any(isnan(data3), 2), :);
data4 = data4(~any(isnan(data4), 2), :);

max_x = 84;
min_x = 59.8234;
max_y = 1414.3890;
min_y = 1229.9;

% 归一化数据1
data1(:, 1) = (data1(:, 1) - min_x) / (max_x - min_x);
data1(:, 2) = (data1(:, 2) - min_y) / (max_y - min_y);
% 归一化数据2
data2(:, 1) = (data2(:, 1) - min_x) / (max_x - min_x);
data2(:, 2) = (data2(:, 2) - min_y) / (max_y - min_y);
% 归一化数据3
data3(:, 1) = (data3(:, 1) - min_x) / (max_x - min_x);
data3(:, 2) = (data3(:, 2) - min_y) / (max_y - min_y);
% 归一化数据4
data4(:, 1) = (data4(:, 1) - min_x) / (max_x - min_x);
data4(:, 2) = (data4(:, 2) - min_y) / (max_y - min_y);

% 设置参考点
% max_x = max([max(data1(:, 1)), max(data2(:, 1)), max(data3(:, 1)), max(data4(:, 1))]);
% min_x = min([min(data1(:, 1)), min(data2(:, 1)), min(data3(:, 1)), min(data4(:, 1))]);
% max_y = max([max(data1(:, 2)), max(data2(:, 2)), max(data3(:, 2)), max(data4(:, 2))]);
% min_y = min([min(data1(:, 2)), min(data2(:, 2)), min(data3(:, 2)), min(data4(:, 2))]);
ref_point = [1.1;1.1];

current_data1 = data1(:, 1:2);
current_data2 = data2(:, 1:2);
current_data3 = data3(:, 1:2);
current_data4 = data4(:, 1:2);

cd('HV\')
% 计算 HV
HV1 = test_lebesgue_measure(current_data1, ref_point);
HV2 = test_lebesgue_measure(current_data2, ref_point);
HV3 = test_lebesgue_measure(current_data3, ref_point);
HV4 = test_lebesgue_measure(current_data4, ref_point);
cd('..\')
cd('Spacing\')
% 计算 Spacing
Spacing1 = Spacing(current_data1);
Spacing2 = Spacing(current_data2);
Spacing3 = Spacing(current_data3);
Spacing4 = Spacing(current_data4);
cd('..\')

% 输出 HV 和 Spacing 结果
fprintf( '%f\n',HV1);
fprintf('%f\n', HV2);
fprintf('%f\n', HV3);
fprintf('%f\n', HV4);
fprintf('%f\n', Spacing1);
fprintf('%f\n', Spacing2);
fprintf('%f\n', Spacing3);
fprintf('%f\n', Spacing4);
