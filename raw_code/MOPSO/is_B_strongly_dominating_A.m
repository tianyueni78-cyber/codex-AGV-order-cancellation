function B_strongly_dominates_A = is_B_strongly_dominating_A(fA, fB)
    B_strongly_dominates_A = true;
    for i = 1:length(fB)
        if (fB(i)>fA(i))  % 判断强支配，B的每个目标值都小于A对应的目标值
            B_strongly_dominates_A = false;
            break;  % 如果有一个目标值不满足条件，就可以退出for循环了
        end
    end
end

