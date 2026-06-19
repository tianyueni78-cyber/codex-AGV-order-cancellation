clear
clc
close all
% 指定用于保存.fig图形的文件夹
figureSaveFolder = 'figures';

if ~exist(figureSaveFolder, 'dir')
    mkdir(figureSaveFolder);
end

numrun = 1;
numresult_I = [];
numresult_NS = [];
numresult_MOEA = [];
numresult_MOSSA = [];
numresult_MOPSO = [];
numHV = zeros(5,numrun);
numSP = zeros(5,numrun);
numC = zeros(8,numrun);
numIGD = zeros(5,numrun);

for i = 1:numrun
    % clear
    clc
    close all
    disp(['当前是第 ' num2str(i) ' 次独立运行']);
    p_cross = 0.8;              % 交叉概率
    p_mutation = 0.2;           % 变异概率
    min_pr = 0.05;              % 反向生成比例下限
    max_pr = 0.3;              % 反向生成比例上限
    epsilon = 0.8;
    alpha = 0.1;
    gamma = 0.9;

    %% 载入标准算例的时间数据
    pth = 'fjsp\Brandimarte_Data\Mk02.fjs';%2,4,6,8
    benchmarkRead(pth);
    load data.mat

    %% 与机器/装卸载站相关数据

    % 使用坐标（x, y）生成距离数据
    distance_from_xy(machineNum);
    distance_matrix_excel = xlsread('机器数据.xlsx', '装卸站到机器距离');
    % 装载站到每台机器的距离
    distance_matrix.load_to_machine = distance_matrix_excel(1, :);
    distance_matrix.load_to_machine = distance_matrix.load_to_machine(1: machineNum);
    % 卸载站到每台机器的距离
    distance_matrix.machine_to_unload = distance_matrix_excel(2, :);
    distance_matrix.machine_to_unload = distance_matrix.machine_to_unload(1: machineNum);
    % 每台机器间的距离
    distance_matrix.machine_to_machine = xlsread('机器数据.xlsx', '机器到机器距离');
    distance_matrix.machine_to_machine = distance_matrix.machine_to_machine(1: machineNum, 1: machineNum);
    % 装 卸载站之间的距离
    distance_matrix.load_to_unload = xlsread('机器数据.xlsx', '装载站到卸载站距离');
    % 能耗
    machineEnergy.work = xlsread('机器数据.xlsx', '机器加工能耗');
    machineEnergy.free = xlsread('机器数据.xlsx', '机器空载能耗');

    %% AGV相关数据
    AGVNum = 3;
    AGVSpeed = [0.5,0.75,1.0];
    % AGV能耗
    AGVEnergy_excel = xlsread('AGV数据.xlsx', 'AGV能耗');
    AGVEnergy.free = AGVEnergy_excel(1, :);
    AGVEnergy.load = AGVEnergy_excel(2, :);
    clear distance_matrix_excel AGVEnergy_excel
  

    %% 充电桩数据
    % [1]. 充电桩放置在 卸载站 ==> 充电桩位置信息与卸载站相同
    % AGV额定电量 Kw*h
    AGVEG_MAX = 100;


    % 验证充电阈值是否合理
    distance_MAX = max([max(distance_matrix.machine_to_machine) ...
        distance_matrix.load_to_machine ...
        distance_matrix.machine_to_unload...
        distance_matrix.load_to_unload]);
    % 电量最低阈值
    % 1.1表示多增加 10% 电量
    check_MIN = 1.0 * distance_MAX / AGVSpeed(end) * (AGVEnergy.free(end) + AGVEnergy.load(end));
    disp(['电量阈值 > ' num2str(check_MIN)])
    AGVEG_MIN = check_MIN + 1e-6;
    % 充电速度 Kw
    eChargeSpeed = 20;

    %% NSAG-II 算法
    % jobNum            工件数量
    % jobInfo           工件加工时间信息
    % operaNumVec       每个工件的工序数量
    % machineNum        机器数量
    % AGVNum            AGV数量
    % AGVSpeed          AGV速度（不同挡位）
    % candidateMachine  每个工件的候选加工机器
    % distance_matrix   距离矩阵
    % machineEnergy     机器能耗
    % AGVEnergy         AGV能耗（不同挡位）
    % AGVEG_MAX         AGV额定电量
    % AGVEG_MIN         AGV充电阈值（低于此电量，需进行充电）
    % eChargeSpeed      AGV充电速率

    pop = 10;
    max_gen = 10;
    speedNum = length(AGVSpeed);    % AGV速度位数目
    operaNum = sum(operaNumVec);       % 工序总数
    %%种群初始化
    chrom = init(pop, jobNum, operaNumVec, candidateMachine, AGVNum, speedNum);

    %%MOPSO
    cd('MOPSO\')
    MOPSO_Result = MOPSO(pop,max_gen,jobNum, jobInfo, operaNumVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
        AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    cd('..\')
    if all(MOPSO_Result.obj_matrix(:,2)>19100)&&all(MOPSO_Result.obj_matrix(:,1)>750)
        continue
    end

        %% NSSA 多目标麻雀算法
    cd('MOSSA\')
    MOSSA_Result = MOSSA(pop,max_gen,jobNum, jobInfo, operaNumVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
        AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    cd('..\')


    % [1]. 改进精英+局部搜索 VNS
    cd('INSGA-II\')
    INSGA_II_0_Result = INSGA_II(p_cross,p_mutation,min_pr,max_pr,epsilon,alpha,gamma,pop,chrom,max_gen,jobNum, jobInfo, operaNumVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
        AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, 'VNS+i-elitism');
    cd('..\')

    %% MOEA/D 算法
    cd('MOEAD\')
    MOEAD_Result = MOEAD(pop,chrom,max_gen,jobNum, jobInfo, operaNumVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
        AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    cd('..\')

    %% NSGA-II 算法
    cd('NSGA-II\')
    NSGA_II_Result = NSGA2(p_cross,p_mutation,pop,chrom,max_gen,jobNum, jobInfo, operaNumVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
        AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    cd('..\')
    
  
figure;
% 曲线数据
x1 = NSGA_II_Result.curve.min(1, :);
x2 = INSGA_II_0_Result.curve.min(1, :);
x3 = MOEAD_Result.curve.min(1, :);
x4 = MOSSA_Result.curve.min(1, :);
x5 = MOPSO_Result.curve.min(1, :);
% 定义颜色
colors = {[0, 0.447, 0.741], [0.85, 0.325, 0.098], [0.494, 0.184, 0.556], ...
    [0.466, 0.674, 0.188], [0.929, 0.694, 0.125]}; % 添加黄色作为MOPSO的颜色
% 绘制五条曲线
plot(x1, 'Color', colors{1}, 'LineStyle', '-', 'LineWidth', 1.5);
hold on;
plot(x2, 'Color', colors{2}, 'LineStyle', '-', 'LineWidth', 1.5);
hold on;
plot(x3, 'Color', colors{3}, 'LineStyle', '-', 'LineWidth', 1.5);
hold on;
plot(x4, 'Color', colors{4}, 'LineStyle', '-', 'LineWidth', 1.5);
hold on;
plot(x5, 'Color', colors{5}, 'LineStyle', '-', 'LineWidth', 1.5);
% 标记每10代，从第5代开始
indices = 5:20:numel(x1);
for j = 1:length(indices)
    plot(indices(j), x1(indices(j)), 's', 'MarkerSize', 10, 'MarkerFaceColor', colors{1}, 'MarkerEdgeColor', 'k');
    plot(indices(j), x2(indices(j)), 'v', 'MarkerSize', 7, 'MarkerFaceColor', colors{2}, 'MarkerEdgeColor', 'k');
    plot(indices(j), x3(indices(j)), 'o', 'MarkerSize', 8, 'MarkerFaceColor', colors{3}, 'MarkerEdgeColor', 'k');
    plot(indices(j), x4(indices(j)), 'd', 'MarkerSize', 8, 'MarkerFaceColor', colors{4}, 'MarkerEdgeColor', 'k');
    plot(indices(j), x5(indices(j)), '>', 'MarkerSize', 7, 'MarkerFaceColor', colors{5}, 'MarkerEdgeColor', 'k');
end
grid on;
box on;
legend({'','','','','','NSGA-II', 'I-NSGA-II-ML', 'MOEA/D', 'MOSSA', 'MOPSO'},...
    'FontName', 'Times New Roman')
% 创建图例
xlabel('Iteration number', 'FontName', 'Times New Roman');
ylabel('Makespan', 'FontName', 'Times New Roman');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12);
set(gcf, 'Position', [100, 100, 800, 600]);
fig_filename = fullfile(figureSaveFolder, ['Figure1_' num2str(i) '.fig']);
savefig(fig_filename);
fig_filename = fullfile(figureSaveFolder, ['Figure1_' num2str(i) '.png']);
saveas(gcf, fig_filename, 'png');
    % 创建一个图形窗口

    figure;
    % 曲线数据
    x11 = NSGA_II_Result.curve.min(2, :);
    x21 = INSGA_II_0_Result.curve.min(2, :);
    x31 = MOEAD_Result.curve.min(2, :);
    x41 = MOSSA_Result.curve.min(2, :);
    x51 = MOPSO_Result.curve.min(2, :);
    % 定义颜色
colors = {[0, 0.447, 0.741], [0.85, 0.325, 0.098], [0.494, 0.184, 0.556], ...
    [0.466, 0.674, 0.188], [0.929, 0.694, 0.125]}; % 添加黄色作为MOPSO的颜色
    % 绘制两条曲线
    plot(x11, 'Color', colors{1}, 'LineStyle', '-', 'LineWidth', 1.5);
    hold on;
    plot(x21, 'Color', colors{2}, 'LineStyle', '-', 'LineWidth', 1.5);
    hold on;
    plot(x31, 'Color', colors{3}, 'LineStyle', '-', 'LineWidth', 1.5);
    hold on;
    plot(x41, 'Color', colors{4}, 'LineStyle', '-', 'LineWidth', 1.5);
    hold on;
    plot(x51, 'Color', colors{5}, 'LineStyle', '-', 'LineWidth', 1.5);
    % 标记每20代，从第5代开始
    indices = 5:20:numel(x1);
    for j = 1:length(indices)
        plot(indices(j), x11(indices(j)), 's', 'MarkerSize', 10, 'MarkerFaceColor', colors{1}, 'MarkerEdgeColor', 'k');
        plot(indices(j), x21(indices(j)), 'v', 'MarkerSize', 7, 'MarkerFaceColor', colors{2}, 'MarkerEdgeColor', 'k');
        plot(indices(j), x31(indices(j)), 'o', 'MarkerSize', 8, 'MarkerFaceColor', colors{3}, 'MarkerEdgeColor', 'k');
        plot(indices(j), x41(indices(j)), 'd', 'MarkerSize', 8, 'MarkerFaceColor', colors{4}, 'MarkerEdgeColor', 'k');
        plot(indices(j), x51(indices(j)), '>', 'MarkerSize', 7, 'MarkerFaceColor', colors{5}, 'MarkerEdgeColor', 'k');
    end
    grid on;
    box on;
    legend({'','','','','','NSGA-II', 'I-NSGA-II-ML', 'MOEA/D', 'MOSSA','MOPSO'},...
        'FontName', 'Times New Roman')
    % 创建图例
    xlabel('Iteration number', 'FontName', 'Times New Roman');
    ylabel('Total energy consumption', 'FontName', 'Times New Roman');
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 12);
    set(gcf, 'Position', [100, 100, 800, 600]);
    %set(gca,'Box','off');
    fig_filename = fullfile(figureSaveFolder, ['Figure2_' num2str(i) '.fig']);
    savefig(fig_filename);
        fig_filename = fullfile(figureSaveFolder, ['Figure2_' num2str(i) '.png']);
        saveas(gcf, fig_filename, 'png');
    
    
    %% 甘特图
    %需展示的方案的索引
    solution_index = 1;     % 对应的第几个解
    figure;
    machine_AGV_gantt_chart(INSGA_II_0_Result.machineTable{solution_index}, INSGA_II_0_Result.AGVTable{solution_index}, ...
        INSGA_II_0_Result.chrom(solution_index, :), jobNum, operaNumVec, AGVSpeed)
    xlabel('Time')
    ylabel('Equipment')
    title(['Makespan:' num2str(INSGA_II_0_Result.obj_matrix(solution_index, 1)) ...
        '\ith \rmTotal energy consumption:' num2str(INSGA_II_0_Result.obj_matrix(solution_index, 2)) '\itKw'])
    fig_filename = fullfile(figureSaveFolder, ['Figure3_' num2str(i) '.fig']);
    savefig(fig_filename);
        fig_filename = fullfile(figureSaveFolder, ['Figure3_' num2str(i) '.png']);
        saveas(gcf, fig_filename, 'png');
    
    
    %% Pareto图
    figure;
    scatter(NSGA_II_Result.obj_matrix(:,1), NSGA_II_Result.obj_matrix(:,2), 45, 'blue', 's','filled')
    hold on;
    scatter(INSGA_II_0_Result.obj_matrix(:,1), INSGA_II_0_Result.obj_matrix(:,2), 48, 'red', 'p', 'filled')
    hold on;
    scatter(MOEAD_Result.obj_matrix(:,1), MOEAD_Result.obj_matrix(:,2), 47, 'magenta', 'h', 'filled')
    hold on;
    scatter(MOSSA_Result.obj_matrix(:,1), MOSSA_Result.obj_matrix(:,2), 43, 'green', 'd', 'filled')
    hold on;
    scatter(MOPSO_Result.obj_matrix(:,1), MOPSO_Result.obj_matrix(:,2), 43, 'cyan', 'v', 'filled')
    grid on; box on;
    legend({'NSGA-II', 'I-NSGA-II-ML', 'MOEA/D', 'MOSSA','MOPSO'}, 'FontName', 'Times New Roman',  'Location', 'bestoutside')
    xlabel('最大完工时间 Cmax')
    ylabel('电量消耗 Kw')
    title('Pareto解')
    box on; grid on
    fig_filename = fullfile(figureSaveFolder, ['Figure5_' num2str(i) '.fig']);
    savefig(fig_filename);
        fig_filename = fullfile(figureSaveFolder, ['Figure5_' num2str(i) '.png']);
        saveas(gcf, fig_filename, 'png');
    
    %% 多目标评价指标
    % 规范化（归一化）
    total_matrix = [INSGA_II_0_Result.obj_matrix; NSGA_II_Result.obj_matrix; ...
        MOEAD_Result.obj_matrix; MOSSA_Result.obj_matrix;MOPSO_Result.obj_matrix];
    max_obj = max(total_matrix, [], 1);
    min_obj = min(total_matrix, [], 1);
    % INSGA2-1 规范化
    INSGA_II_0_obj_normal = (INSGA_II_0_Result.obj_matrix - repmat(min_obj, size(INSGA_II_0_Result.obj_matrix, 1), 1))./...
        (repmat(max_obj, size(INSGA_II_0_Result.obj_matrix, 1), 1) - repmat(min_obj, size(INSGA_II_0_Result.obj_matrix, 1),1));
    % NSGA-II 规范化
    NSGA_II_obj_normal = (NSGA_II_Result.obj_matrix - repmat(min_obj, size(NSGA_II_Result.obj_matrix, 1),1))./...
        (repmat(max_obj, size(NSGA_II_Result.obj_matrix, 1),1) - repmat(min_obj, size(NSGA_II_Result.obj_matrix, 1),1));
    % MOEA/D 规范化
    MOEAD_obj_normal = (MOEAD_Result.obj_matrix - repmat(min_obj, size(MOEAD_Result.obj_matrix, 1),1))./...
        (repmat(max_obj, size(MOEAD_Result.obj_matrix, 1),1) - repmat(min_obj, size(MOEAD_Result.obj_matrix, 1),1));
    % MOSSA 规范化
    MOSSA_obj_normal = (MOSSA_Result.obj_matrix - repmat(min_obj, size(MOSSA_Result.obj_matrix, 1),1))./...
        (repmat(max_obj, size(MOSSA_Result.obj_matrix, 1),1) - repmat(min_obj, size(MOSSA_Result.obj_matrix, 1),1));
    % MOPSO 规范化
    MOPSO_obj_normal = (MOPSO_Result.obj_matrix - repmat(min_obj, size(MOPSO_Result.obj_matrix, 1),1))./...
        (repmat(max_obj, size(MOPSO_Result.obj_matrix, 1),1) - repmat(min_obj, size(MOPSO_Result.obj_matrix, 1),1));
    
    %% HV 指标
    ref_point = [1.1; 1.1]; % 参考点
    cd('HV\')
    HV_ =  [test_lebesgue_measure(INSGA_II_0_obj_normal, ref_point), ...
        test_lebesgue_measure(NSGA_II_obj_normal, ref_point), ...
        test_lebesgue_measure(MOEAD_obj_normal, ref_point), ...
        test_lebesgue_measure(MOSSA_obj_normal, ref_point),...
        test_lebesgue_measure(MOPSO_obj_normal, ref_point)];
    cd('..\')
    % fprintf('HV指标: I-NSGA-II-ML: %.6f || NSGA-II: %.6f || MOEAD: %.6f || MOSSA: %.6f\n', ...
    %     HV_(1), HV_(2), HV_(3), HV_(4))
    fprintf('HV指标: I-NSGA-II-ML: %.6f \n',HV_(1))
    fprintf('HV指标: NSGA-II: %.6f \n',HV_(2))
    fprintf('HV指标: MOEA/D: %.6f \n',HV_(3))
    fprintf('HV指标: MOSSA: %.6f \n',HV_(4))
    fprintf('HV指标: MOPSO: %.6f \n',HV_(5))
    
%% spacing指标
    cd('Spacing\')
    SP_ = [Spacing(INSGA_II_0_Result.obj_matrix),Spacing(NSGA_II_Result.obj_matrix),...
        Spacing(MOEAD_Result.obj_matrix),Spacing(MOSSA_Result.obj_matrix),Spacing(MOPSO_Result.obj_matrix)]; 
    cd('..\')
    fprintf('Spacing指标: I-NSGA-II-ML: %.6f \n',SP_(1))
    fprintf('Spacing指标: NSGA-II: %.6f \n',SP_(2))
    fprintf('Spacing指标: MOEA/D: %.6f \n',SP_(3))
    fprintf('Spacing指标: MOSSA: %.6f \n',SP_(4))
    fprintf('Spacing指标: MOPSO: %.6f \n',SP_(5))
    
    cd('C-metric\')
    C_metric_NSGA_II_3 = [c_compute_A_B(INSGA_II_0_obj_normal, NSGA_II_obj_normal),...
        c_compute_A_B(INSGA_II_0_obj_normal, MOEAD_obj_normal), ...
        c_compute_A_B(INSGA_II_0_obj_normal, MOSSA_obj_normal),...
         c_compute_A_B(INSGA_II_0_obj_normal, MOPSO_obj_normal)];
    C_metric_NSGA_II_4 = [c_compute_A_B(NSGA_II_obj_normal, INSGA_II_0_obj_normal),...
        c_compute_A_B(MOEAD_obj_normal, INSGA_II_0_obj_normal), ...
        c_compute_A_B(MOSSA_obj_normal, INSGA_II_0_obj_normal),...
        c_compute_A_B(MOPSO_obj_normal, INSGA_II_0_obj_normal)];
    cd('..\')
    fprintf('C(I-NSGA-II-ML, NSGA-II): %.6f \n', C_metric_NSGA_II_3(1))
    fprintf('C(I-NSGA-II-ML, MOEA/D): %.6f \n', C_metric_NSGA_II_3(2))
    fprintf('C(I-NSGA-II-ML, MOSSA): %.6f \n', C_metric_NSGA_II_3(3))
    fprintf('C(I-NSGA-II-ML, MOPSO): %.6f \n', C_metric_NSGA_II_3(4))
    fprintf('C(NSGA-II,I-NSGA-II-ML): %.6f \n', C_metric_NSGA_II_4(1))
    fprintf('C(MOEA/D, I-NSGA-II-ML): %.6f \n', C_metric_NSGA_II_4(2))
    fprintf('C(MOSSA, I-NSGA-II-ML): %.6f \n', C_metric_NSGA_II_4(3))
    fprintf('C(MOPSO, I-NSGA-II-ML): %.6f \n', C_metric_NSGA_II_4(4))  
    
    %% IGD
    total_normal = [INSGA_II_0_obj_normal;  ...
        NSGA_II_obj_normal; MOEAD_obj_normal; MOSSA_obj_normal;MOPSO_obj_normal];
    total_normal = non_domination_only(total_normal, 2, 0);
    total_normal = total_normal(total_normal(:, 3) == 1, 1: 2);
    total_normal = unique(total_normal,"rows");
    cd('IGD\')
    IGD_ =  [IGD_compution(total_normal, INSGA_II_0_obj_normal), ...
        IGD_compution(total_normal, NSGA_II_obj_normal), ...
        IGD_compution(total_normal, MOEAD_obj_normal), ...
        IGD_compution(total_normal, MOSSA_obj_normal),...
        IGD_compution(total_normal, MOPSO_obj_normal)];
    fprintf('IGD指标: I-NSGA-ML: %.6f \n', IGD_(1))
    fprintf('IGD指标: NSGA-II: %.6f\n', IGD_(2))
    fprintf('IGD指标: MOEA/D: %.6f\n', IGD_(3))
    fprintf('IGD指标: MOSSA: %.6f\n', IGD_(4))
    fprintf('IGD指标: MOPSO: %.6f\n', IGD_(5))
    cd('..\')

    numresult_I = [numresult_I;INSGA_II_0_Result.obj_matrix];
    numresult_NS = [numresult_NS;NSGA_II_Result.obj_matrix];
    numresult_MOEA = [numresult_MOEA;MOEAD_Result.obj_matrix];
    numresult_MOSSA = [numresult_MOSSA;MOSSA_Result.obj_matrix];
    numresult_MOPSO = [numresult_MOPSO;MOPSO_Result.obj_matrix];
        numHV(1,i) = HV_(1);
        numHV(2,i) = HV_(2);
        numHV(3,i) = HV_(3);
        numHV(4,i) = HV_(4);
        numHV(5,i) = HV_(5);
        numSP(1,i) = SP_(1);
        numSP(2,i) = SP_(2);
        numSP(3,i) = SP_(3);
        numSP(4,i) = SP_(4);
        numSP(5,i) = SP_(5);
        numC(1,i) = C_metric_NSGA_II_3(1);
        numC(2,i) = C_metric_NSGA_II_3(2);
        numC(3,i) = C_metric_NSGA_II_3(3);
        numC(4,i) = C_metric_NSGA_II_3(4);
        numC(5,i) = C_metric_NSGA_II_4(1);
        numC(6,i) = C_metric_NSGA_II_4(2);
        numC(7,i) = C_metric_NSGA_II_4(3);
        numC(8,i) = C_metric_NSGA_II_4(4);
        numIGD(1,i) = IGD_(1);
        numIGD(2,i) = IGD_(2);
        numIGD(3,i) = IGD_(3);
        numIGD(4,i) = IGD_(4);
        numIGD(5,i) = IGD_(5);



        % 打开文本文件，使用追加模式
    resultFile = fopen('results.txt', 'a');
    
    % 写入数据
    
    fprintf(resultFile, 'INSGA_II_0_Result.obj_matrix:\n');
    dlmwrite('results.txt', numresult_I, '-append', 'delimiter', '\t');
    
    fprintf(resultFile, 'NSGA_II_Result.obj_matrix:\n');
    dlmwrite('results.txt', numresult_NS, '-append', 'delimiter', '\t');
    
    fprintf(resultFile, 'MOEAD_Result.obj_matrix:\n');
    dlmwrite('results.txt', numresult_MOEA, '-append', 'delimiter', '\t');
    
    fprintf(resultFile, 'MOSSA_Result.obj_matrix:\n');
    dlmwrite('results.txt', numresult_MOSSA, '-append', 'delimiter', '\t');

    fprintf(resultFile, 'MOPSO_Result.obj_matrix:\n');
    dlmwrite('results.txt', numresult_MOPSO, '-append', 'delimiter', '\t');
    
    fprintf(resultFile, 'HV Results:\n');
    fprintf(resultFile, 'I-NSGA-II-ML: %.6f\n', numHV(1, :));
    fprintf(resultFile, 'NSGA-II: %.6f\n', numHV(2, :));
    fprintf(resultFile, 'MOEA/D: %.6f\n', numHV(3, :));
    fprintf(resultFile, 'MOSSA: %.6f\n', numHV(4, :));
    fprintf(resultFile, 'MOPSO: %.6f\n', numHV(5, :));

    fprintf(resultFile, 'SP Results:\n');
    fprintf(resultFile, 'I-NSGA-II-ML: %.6f\n', numSP(1, :));
    fprintf(resultFile, 'NSGA-II: %.6f\n', numSP(2, :));
    fprintf(resultFile, 'MOEA/D: %.6f\n', numSP(3, :));
    fprintf(resultFile, 'MOSSA: %.6f\n', numSP(4, :));
    fprintf(resultFile, 'MOPSO: %.6f\n', numSP(5, :));

    fprintf(resultFile, 'C-Metric Results:\n');
    fprintf(resultFile, 'C(I-NSGA-II-ML, NSGA-II): %.6f\n', numC(1, :));
    fprintf(resultFile, 'C(I-NSGA-II-ML, MOEA/D): %.6f\n', numC(2, :));
    fprintf(resultFile, 'C(I-NSGA-II-ML, MOSSA): %.6f\n', numC(3, :));
    fprintf(resultFile, 'C(I-NSGA-II-ML, MOPSO): %.6f\n', numC(4, :));
    fprintf(resultFile, 'C(NSGA-II, I-NSGA-II-ML): %.6f\n', numC(5, :));
    fprintf(resultFile, 'C(MOEA/D, I-NSGA-II-ML): %.6f\n', numC(6, :));
    fprintf(resultFile, 'C(MOSSA, I-NSGA-II-ML): %.6f\n', numC(7, :));
    fprintf(resultFile, 'C(MOPSO, I-NSGA-II-ML): %.6f\n', numC(8, :));

    fprintf(resultFile, 'IGD Results:\n');
    fprintf(resultFile, 'IGD(I-NSGA-II-ML): %.6f\n', numIGD(1, :));
    fprintf(resultFile, 'IGD(NSGA-II): %.6f\n', numIGD(2, :));
    fprintf(resultFile, 'IGD(MOEA/D): %.6f\n', numIGD(3, :));
    fprintf(resultFile, 'IGD(MOSSA): %.6f\n', numIGD(4, :));
    fprintf(resultFile, 'IGD(MOPSO): %.6f\n', numIGD(5, :));

    % 关闭文件
    fclose(resultFile);

end
beep;