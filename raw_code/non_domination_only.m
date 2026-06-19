function sorted_based_on_front=non_domination_only(chromosome,obj_number,variables_number)
[N,~]=size(chromosome);
% clear m;
front=1;
F(front).f=[];
individual=[];

% 计算每个个体对应的排序值
for i=1:N
    individual(i).n=0;    %n  对应个体i被支配的个体数量  即非支配度
    individual(i).p=[];   %p  对应个体i支配的个体集合
    for j=1:N
        dom_less=0;
        dom_equal=0;
        dom_more=0;
        for k=1:obj_number
            if chromosome(i,variables_number+k)<chromosome(j,variables_number+k)
                dom_less=dom_less+1;
            elseif chromosome(i,variables_number+k)==chromosome(j,variables_number+k)
                dom_equal=dom_equal+1;
            else
                dom_more=dom_more+1;
            end
        end
        if dom_less==0&&dom_equal~=obj_number  %(优化目标为最小值)对于i，j中所有目标值都小于等于
                                               %（不全部等于）i,说明i受j支配。则i的在非支配度加1
            individual(i).n=individual(i).n+1;
        elseif dom_more==0&&dom_equal~=obj_number  %(优化目标为最小值)对于i，j中目标值都等于大于
                                                    %（不全部等于）i,说明i支配j。则把j加入到i的支配集中
            individual(i).p=[individual(i).p j];
        end
    end
    if individual(i).n==0   %个体i的非支配度最小 ,即非支配等级最高，属于当前个体中的最优解，在其染色中加入排序信息
        chromosome(i,variables_number+obj_number+1)=1;
        F(front).f=[F(front).f i];  %等级为1的非支配解集
    end
end
%以上的代码遍历所有染色体，找到了等级最高的非支配集
%                              每个个体的被支配数
%                              每个个体的支配集

%%%下面的代码将其进行分级
while ~isempty(F(front).f)
    Q=[];   %存放下一个front集合
    for i=1:length(F(front).f)    %循环当前非支配解集中的个体
        if ~isempty(individual(F(front).f(i)).p)    %个体i有自己所支配的解集
            for j=1:length(individual(F(front).f(i)).p)   %循环个体i所支配解集中的个体
                individual(individual(F(front).f(i)).p(j)).n=...
                    (individual(individual(F(front).f(i)).p(j)).n)-1;
                if individual(individual(F(front).f(i)).p(j)).n==0
                    chromosome(individual(F(front).f(i)).p(j),...
                        variables_number+obj_number+1)=front+1;
                    Q=[Q individual(F(front).f(i)).p(j)];
                end
            end
        end
    end
    front=front+1;
    F(front).f=Q;
end

[~,index_of_fronts]=sort(chromosome(:,variables_number+obj_number+1));   %d对个体的代表排序的列进行升序排序
for i=1:length(index_of_fronts)
    sorted_based_on_front(i,:)=chromosome(index_of_fronts(i),:);   %sorted_based_on_front是按照等级排序后的矩阵
end
end

