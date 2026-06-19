%% 生成参考点：lamda向量
%   生成方式：单纯形法

function lambda = generateLamda(pop, obj_number)

% obj_number：目标函数个数
switch obj_number
    case 2
        array = (0:pop - 1) / (pop - 1);
        for i = 1:pop
            lambda(i, 1) = array(i);
            lambda(i, 2) = 1 - array(i);
        end

    case 3
        array = (0:13) / 13; % 间隔 1/13  能产生105个向量
        k = 1;
        for i = 1:14
            for j = 1:14
                if i + j < 16
                    lambda(k, 1) = array(i);
                    lambda(k, 2) = array(j);
                    lambda(k, 3) = array(16-i-j);
                    k = k + 1;
                end
            end
        end

        len = size(lambda, 1);
        index = randperm(len);
        index = sort(index(1:pop));
        lambda = lambda(index, :);

    otherwise
        warning('wrong obj_number');
end
