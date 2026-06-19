function f = tournament_selection(chromosome, pool_size, tour_size)
[pop, variables] = size(chromosome);
rank = variables-1;
distance = variables;
% 竞标赛选择法  每次随机选择tour_size个 个体，优先选择排序等级高的个体，如果排序等级一样，优先
%              选择拥挤度大的个体
for i=1:pool_size
    for j=1:tour_size
        candidate(j)=round(pop*rand(1));
        if candidate(j)==0
            candidate(j)=1;
        end
        if j>1
            while ~isempty(find(candidate(1:j-1)==candidate(j)))
                candidate(j)=round(pop*rand(1));
                if candidate(j)==0
                    candidate(j)=1;
                end
            end
        end
    end
    for j=1:tour_size  %记录每个参赛者的排序等级，拥挤度
        c_obj_rank(j)=chromosome(candidate(j),rank);
        c_obj_distance(j)=chromosome(candidate(j),distance);
    end
    min_candidate=find(c_obj_rank==min(c_obj_rank));   %选择排序等级较小的参赛者
    if length(min_candidate)~=1   %两个参赛者排序等级相同  接着继续比较拥挤度
        max_candidate=find(c_obj_distance(min_candidate)==max(c_obj_distance(min_candidate)));
        if length(max_candidate)~=1
            max_candidate=max_candidate(1);
        end
        f(i,:)=chromosome(candidate(min_candidate(max_candidate)),:);
    else
        f(i,:)=chromosome(candidate(min_candidate(1)),:);
    end
end