function MOPSO_Result = MOPSO(pop,max_gen,jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, distance_matrix, machineEnergy, ...
    AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed)
tstart = tic;               % 计时器
disp('RUNNING --------> MOPSO <-------- RUNNING')
disp(['工件数：' num2str(jobNum), ' 机器数 ', num2str(machineNum), ' AGV数 ' num2str(AGVNum)]);

% 模型信息
operaNum = sum(operaVec);       % 工序总数

%% MOSSA 参数
% [1]. 编码 OS（长度＝总工序数）+MS（长度＝总工序数）＋AS（长度＝总工序数）＋SS（长度＝２＊总工序数）
dim = 5 * operaNum;         % 自变量维度
obj_num = 2;                % 目标函数维度

% Parameters
Np      = pop;
Nr      = 200;
maxgen  = max_gen;
W       = 0.4;
C1      = 2;
C2      = 2;
ngrid   = 20;
maxvel  = 6;
u_mut   = 0.4;
nVar    = dim;%维度
% MultiObj.var_min = -jobNum.*ones(1,nVar);
% MultiObj.var_max = jobNum.*ones(1,nVar);
MultiObj.var_min = -jobNum.*ones(1,nVar);
MultiObj.var_max = jobNum.*ones(1,nVar);
var_min = MultiObj.var_min(:);
var_max = MultiObj.var_max(:);

y=rand(1,dim); 
Z(1,:) = y;
Alpa=0.5;
for i=2:pop
    for j=1:dim
        if Z(i-1,j)<=Alpa
            Z(i,j)=Z(i-1,j)/Alpa+rand(1)/pop;
        else
            Z(i,j)=(1-Z(i-1,j))/(1-Alpa)+rand(1)/pop;
        end
        if Z(i,j)>-jobNum || Z(i,j)<jobNum
            Z(i,j)=rand;
        end
    end
end
for i = 1 : Np
    POS(i, :) = -jobNum + 2*jobNum .* Z(i,:);
end
%POS = repmat((var_max-var_min)',Np,1).*rand(Np,nVar) + repmat(var_min',Np,1);
VEL = zeros(Np,nVar);
%% 适应度值
for i = 1 : Np
    func = fitness(POS(i, :), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
        distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
    POS_fit(i, :) = func{1};
end

%% 初始设定
PBEST    = POS;%每一条中每一个粒子最佳位置，初始设为初始种群
PBEST_fit= POS_fit;
DOMINATED= checkDomination(POS_fit);
REP.pos  = POS(~DOMINATED,:);
REP.pos_fit = POS_fit(~DOMINATED,:);
REP      = updateGrid(REP,ngrid);
maxvel   = (var_max-var_min).*maxvel./100;
gen      = 1;

%% MOPSO主循环
 % Plotting and verbose
%     if(size(POS_fit,2)==2)
%         h_fig = figure(1);
%         h_par = plot(POS_fit(:,1),POS_fit(:,2),'or'); hold on;
%         h_rep = plot(REP.pos_fit(:,1),REP.pos_fit(:,2),'ok'); hold on;
%         try
%             set(gca,'xtick',REP.hypercube_limits(:,1)','ytick',REP.hypercube_limits(:,2)');
%             axis([min(REP.hypercube_limits(:,1)) max(REP.hypercube_limits(:,1)) ...
%                   min(REP.hypercube_limits(:,2)) max(REP.hypercube_limits(:,2))]);
%             grid on; xlabel('f1'); ylabel('f2');
%         end
%         drawnow;
%     end
    %display(['Generation #0 - Repository size: ' num2str(size(REP.pos,1))]);
    
    % Main MPSO loop
    %stopCondition = false;
    %while ~stopCondition
    while gen<=maxgen


        % Select leader
        h = selectLeader(REP);
        % Update speeds and positions
        VEL = W.*VEL + C1*rand(Np,nVar).*(PBEST-POS) ...
                     + C2*rand(Np,nVar).*(repmat(REP.pos(h,:),Np,1)-POS);
        POS = POS + VEL;
        
        % Perform mutation
        POS = mutation(POS,gen,maxgen,Np,var_max,var_min,nVar,u_mut);
        
        % Check boundaries
        [POS,VEL] = checkBoundaries(POS,VEL,maxvel,var_max,var_min);       
        
        % Evaluate the population
        for i = 1 : Np
            func = fitness(POS(i, :), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
                distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        POS_fit(i, :) = func{1};
        end

        for i= 1:Np/10
            % ★★改进3：趋优反向学习★★
            new_p = -POS(i,:);
            old_obj = POS_fit(i,:);
            new_obj = fitness(new_p, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
                    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
            new_obj = new_obj{1};
            if is_B_strongly_dominating_A(old_obj,new_obj)
                POS(i, :) =new_p;
                POS_fit(i, :) =new_obj;
            end
        end

        
        % Update the repository
        REP = updateRepository(REP,POS,POS_fit,ngrid);
        if(size(REP.pos,1)>Nr)
             REP = deleteFromRepository(REP,size(REP.pos,1)-Nr,ngrid);
        end
        
        % Update the best positions found so far for each particle
        pos_best = dominates(POS_fit, PBEST_fit);
        best_pos = ~dominates(PBEST_fit, POS_fit);
        best_pos(rand(Np,1)>=0.5) = 0;
        if(sum(pos_best)>1)
            PBEST_fit(pos_best,:) = POS_fit(pos_best,:);
            PBEST(pos_best,:) = POS(pos_best,:);
        end
        if(sum(best_pos)>1)
            PBEST_fit(best_pos,:) = POS_fit(best_pos,:);
            PBEST(best_pos,:) = POS(best_pos,:);
        end


%         % Plotting and verbose
%         if(size(POS_fit,2)==2)
%             figure(h_fig); delete(h_par); delete(h_rep);
%             h_par = plot(POS_fit(:,1),POS_fit(:,2),'or'); hold on;
%             h_rep = plot(REP.pos_fit(:,1),REP.pos_fit(:,2),'ok'); hold on;
%             try
%                 set(gca,'xtick',REP.hypercube_limits(:,1)','ytick',REP.hypercube_limits(:,2)');
%                 axis([min(REP.hypercube_limits(:,1)) max(REP.hypercube_limits(:,1)) ...
%                       min(REP.hypercube_limits(:,2)) max(REP.hypercube_limits(:,2))]);
%             end
%             if(isfield(MultiObj,'truePF'))
%                 try delete(h_pf); end
%                 h_pf = plot(MultiObj.truePF(:,1),MultiObj.truePF(:,2),'.','color','g'); hold on;
%             end
%             grid on; xlabel('f1'); ylabel('f2');
%             drawnow;
%             axis square;
%         end
        
        % Update generation and check for termination
        
        %% 打印、保存
        % 迭代曲线
        for k = 1: obj_num
            curve_min(k, gen) = min(REP.pos_fit(:, k));
            curve_avg(k, gen) = mean(REP.pos_fit(:, k));
        end
        fprintf('MOPSO GEN: %d  MIN Cmax: %.1f  MIN Energy:%.2f\n', gen, min(REP.pos_fit(:, 1)), min(REP.pos_fit(:, 2)));
        gen = gen + 1;
    end
    RunTime = toc(tstart);
    disp(['运行时间：' num2str(RunTime)]);
    % %% 结果保存
        PSO = REP.pos;
        Arc = REP.pos_fit;
        [obj_matrix, uni_idx] = unique(Arc, 'rows');

        MOPSO_Result.RunTime = RunTime;
        MOPSO_Result.obj_matrix = obj_matrix;
        MOPSO_Result.pop = PSO(uni_idx, :);
        MOPSO_Result.curve.min = curve_min;
        MOPSO_Result.curve.avg = curve_avg;
        for idx = 1: size(MOPSO_Result.pop, 1)
            [~, MOPSO_Result.machineTable{idx}, MOPSO_Result.AGVTable{idx}, ~, MOPSO_Result.EG_M_SUM{idx}, ...
                MOPSO_Result.EG_A_SUM{idx}, MOPSO_Result.agvEGRecord{idx}, MOPSO_Result.agvChargeNum{idx}]...
                = fitness(MOPSO_Result.pop(idx, 1: dim), jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
                distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed);
        end
end
    

% Function that updates the repository given a new population and its
function REP = updateRepository(REP,POS,POS_fit,ngrid)
    % Domination between particles
    DOMINATED  = checkDomination(POS_fit);
    REP.pos    = [REP.pos; POS(~DOMINATED,:)];
    REP.pos_fit= [REP.pos_fit; POS_fit(~DOMINATED,:)];
    % Domination between nondominated particles and the last repository
    DOMINATED  = checkDomination(REP.pos_fit);
    REP.pos_fit= REP.pos_fit(~DOMINATED,:);
    REP.pos    = REP.pos(~DOMINATED,:);
    % Updating the grid
    REP        = updateGrid(REP,ngrid);
end

% Function that corrects the positions and velocities of the particles that
% exceed the boundaries
function [POS,VEL] = checkBoundaries(POS,VEL,maxvel,var_max,var_min)
    % Useful matrices
    Np = size(POS,1);
    MAXLIM   = repmat(var_max(:)',Np,1);
    MINLIM   = repmat(var_min(:)',Np,1);
    MAXVEL   = repmat(maxvel(:)',Np,1);
    MINVEL   = repmat(-maxvel(:)',Np,1);
    
    % Correct positions and velocities
    VEL(VEL>MAXVEL) = MAXVEL(VEL>MAXVEL);
    VEL(VEL<MINVEL) = MINVEL(VEL<MINVEL);
    VEL(POS>MAXLIM) = (-1).*VEL(POS>MAXLIM);
    POS(POS>MAXLIM) = MAXLIM(POS>MAXLIM);
    VEL(POS<MINLIM) = (-1).*VEL(POS<MINLIM);
    POS(POS<MINLIM) = MINLIM(POS<MINLIM);
end

% Function for checking the domination between the population. It
% returns a vector that indicates if each particle is dominated (1) or not
function dom_vector = checkDomination(fitness)
    Np = size(fitness,1);
    dom_vector = zeros(Np,1);
    all_perm = nchoosek(1:Np,2);    % Possible permutations
    all_perm = [all_perm; [all_perm(:,2) all_perm(:,1)]];
    
    d = dominates(fitness(all_perm(:,1),:),fitness(all_perm(:,2),:));
    dominated_particles = unique(all_perm(d==1,2));
    dom_vector(dominated_particles) = 1;
end

% Function that returns 1 if x dominates y and 0 otherwise
function d = dominates(x,y)
    d = all(x<=y,2) & any(x<y,2);
end

% Function that updates the hypercube grid, the hypercube where belongs
% each particle and its quality based on the number of particles inside it
function REP = updateGrid(REP,ngrid)
    % Computing the limits of each hypercube
    ndim = size(REP.pos_fit,2);
    REP.hypercube_limits = zeros(ngrid+1,ndim);
    for dim = 1:1:ndim
        REP.hypercube_limits(:,dim) = linspace(min(REP.pos_fit(:,dim)),max(REP.pos_fit(:,dim)),ngrid+1)';
    end
    
    % Computing where belongs each particle
    npar = size(REP.pos_fit,1);
    REP.grid_idx = zeros(npar,1);
    REP.grid_subidx = zeros(npar,ndim);
    for n = 1:1:npar
        idnames = [];
        for d = 1:1:ndim
            REP.grid_subidx(n,d) = find(REP.pos_fit(n,d)<=REP.hypercube_limits(:,d)',1,'first')-1;
            if(REP.grid_subidx(n,d)==0), REP.grid_subidx(n,d) = 1; end
            idnames = [idnames ',' num2str(REP.grid_subidx(n,d))];
        end
        REP.grid_idx(n) = eval(['sub2ind(ngrid.*ones(1,ndim)' idnames ');']);
    end
    
    % Quality based on the number of particles in each hypercube
    REP.quality = zeros(ngrid,2);
    ids = unique(REP.grid_idx);
    for i = 1:length(ids)
        REP.quality(i,1) = ids(i);  % First, the hypercube's identifier
        REP.quality(i,2) = 10/sum(REP.grid_idx==ids(i)); % Next, its quality
    end
end

% Function that selects the leader performing a roulette wheel selection
% based on the quality of each hypercube
function selected = selectLeader(REP)
    % Roulette wheel
    prob    = cumsum(REP.quality(:,2));     % Cumulated probs
    sel_hyp = REP.quality(find(rand(1,1)*max(prob)<=prob,1,'first'),1); % Selected hypercube
    
    % Select the index leader as a random selection inside that hypercube
    idx      = 1:1:length(REP.grid_idx);
    selected = idx(REP.grid_idx==sel_hyp);
    selected = selected(randi(length(selected)));
end

% Function that deletes an excess of particles inside the repository using
% crowding distances
function REP = deleteFromRepository(REP,n_extra,ngrid)
    % Compute the crowding distances
    crowding = zeros(size(REP.pos,1),1);
    for m = 1:1:size(REP.pos_fit,2)
        [m_fit,idx] = sort(REP.pos_fit(:,m),'ascend');
        m_up     = [m_fit(2:end); Inf];
        m_down   = [Inf; m_fit(1:end-1)];
        distance = (m_up-m_down)./(max(m_fit)-min(m_fit));
        [~,idx]  = sort(idx,'ascend');
        crowding = crowding + distance(idx);
    end
    crowding(isnan(crowding)) = Inf;
    
    % Delete the extra particles with the smallest crowding distances
    [~,del_idx] = sort(crowding,'ascend');
    del_idx = del_idx(1:n_extra);
    REP.pos(del_idx,:) = [];
    REP.pos_fit(del_idx,:) = [];
    REP = updateGrid(REP,ngrid); 
end

% Function that performs the mutation of the particles depending on the
% current generation
function POS = mutation(POS,gen,maxgen,Np,var_max,var_min,nVar,u_mut)
    % Sub-divide the swarm in three parts [2]
    fract     = Np/3 - floor(Np/3);
    if(fract<0.5), sub_sizes =[ceil(Np/3) round(Np/3) round(Np/3)];
    else           sub_sizes =[round(Np/3) round(Np/3) floor(Np/3)];
    end
    cum_sizes = cumsum(sub_sizes);
    
    % First part: no mutation
    % Second part: uniform mutation
    nmut = round(u_mut*sub_sizes(2));
    if(nmut>0)
        idx = cum_sizes(1) + randperm(sub_sizes(2),nmut);
        POS(idx,:) = repmat((var_max-var_min)',nmut,1).*rand(nmut,nVar) + repmat(var_min',nmut,1);
    end
    
    % Third part: non-uniform mutation
    per_mut = (1-gen/maxgen)^(5*nVar);     % Percentage of mutation
    nmut    = round(per_mut*sub_sizes(3));
    if(nmut>0)
        idx = cum_sizes(2) + randperm(sub_sizes(3),nmut);
        POS(idx,:) = repmat((var_max-var_min)',nmut,1).*rand(nmut,nVar) + repmat(var_min',nmut,1);
    end
end