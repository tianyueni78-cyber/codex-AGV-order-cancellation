function NSGA2_Result = nsga2_with_encoding_variation(p_cross, p_mutation, pop, chrom, max_gen, problem, machineData, agvData, AGVEG_MAX, AGVEG_MIN, eChargeSpeed)
%NSGA2_WITH_ENCODING_VARIATION NSGA-II loop using refactored offspring generation.
%   This function mirrors raw NSGA2.m but replaces variation.m with
%   generate_offspring. It still relies on the existing search/evaluation
%   utilities for fitness, non-domination, selection, and replacement.

tstart = tic;
disp('RUNNING --------> NSGA-II with refactored encoding <-------- RUNNING')
disp(['工件数：' num2str(problem.jobNum), ...
    ' 机器数 ' num2str(problem.machineNum), ...
    ' AGV数 ' num2str(agvData.AGVNum)]);

operaNum = sum(problem.operaNumVec);
dim = 5 * operaNum;
obj_num = 2;
pool = round(pop / 2);
tour = 2;

distance_matrix = machineData.distance_matrix;
machineEnergy = machineData.machineEnergy;
AGVEnergy = agvData.AGVEnergy;

for i = 1:pop
    func = fitness(chrom(i, :), problem.jobNum, problem.jobInfo, ...
        problem.operaNumVec, problem.machineNum, agvData.AGVNum, ...
        agvData.AGVSpeed, problem.candidateMachine, distance_matrix, ...
        machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    chrom(i, dim + 1:dim + obj_num) = func{1};
end

chrom = non_domination(chrom, dim, obj_num);
pop_history = cell(1, max_gen);
curve_min = zeros(obj_num, max_gen);
curve_avg = zeros(obj_num, max_gen);

gen = 0;
while gen < max_gen
    parent_ = tournament_selection(chrom, pool, tour);

    variationOptions = struct();
    variationOptions.pCross = p_cross;
    variationOptions.pMutation = p_mutation;
    [offspring_, offspringReport] = generate_offspring( ...
        parent_, problem, agvData, variationOptions);
    if ~offspringReport.isValid
        error('nsga2_with_encoding_variation:InvalidOffspring', ...
            'Refactored encoding generated invalid offspring.');
    end

    for i = 1:size(offspring_, 1)
        func = fitness(offspring_(i, :), problem.jobNum, ...
            problem.jobInfo, problem.operaNumVec, problem.machineNum, ...
            agvData.AGVNum, agvData.AGVSpeed, ...
            problem.candidateMachine, distance_matrix, machineEnergy, ...
            AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        offspring_(i, dim + 1:dim + obj_num) = func{1};
    end

    intermediate_ = [chrom(:, 1:dim + obj_num); ...
        offspring_(:, 1:dim + obj_num)];
    intermediate_ = non_domination(intermediate_, dim, obj_num);
    chrom = replace_chrom(intermediate_, dim, obj_num, pop);

    pop_history{gen + 1} = chrom;
    gen = gen + 1;

    fprintf('GEN: %d  MIN Cmax: %.1f  MIN Energy:%.2f\n', ...
        gen, min(chrom(:, dim + 1)), min(chrom(:, dim + 2)));
    for k = 1:obj_num
        curve_min(k, gen) = min(chrom(:, dim + k));
        curve_avg(k, gen) = mean(chrom(:, dim + k));
    end
end

NSGA2_Result.pop_history = pop_history;
RunTime = toc(tstart);
disp(['运行时间：' num2str(RunTime)]);

chrom = chrom(chrom(:, dim + obj_num + 1) == 1, :);
obj_matrix = chrom(:, dim + 1:dim + obj_num);
[obj_matrix, uni_index] = unique(obj_matrix, 'rows');
chrom = chrom(uni_index, :);

NSGA2_Result.RunTime = RunTime;
NSGA2_Result.chrom = chrom;
NSGA2_Result.obj_matrix = obj_matrix;
NSGA2_Result.curve.min = curve_min;
NSGA2_Result.curve.avg = curve_avg;

for idx = 1:size(chrom, 1)
    [~, NSGA2_Result.machineTable{idx}, ...
        NSGA2_Result.AGVTable{idx}, ~, ...
        NSGA2_Result.EG_M_SUM{idx}, ...
        NSGA2_Result.EG_A_SUM{idx}, ...
        NSGA2_Result.agvEGRecord{idx}, ...
        NSGA2_Result.agvChargeNum{idx}] = fitness( ...
        chrom(idx, 1:dim), problem.jobNum, problem.jobInfo, ...
        problem.operaNumVec, problem.machineNum, agvData.AGVNum, ...
        agvData.AGVSpeed, problem.candidateMachine, distance_matrix, ...
        machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
end
end
