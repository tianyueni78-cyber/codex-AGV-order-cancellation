%% 计算每个点的邻居索引
function f = get_neighbor(lamda, num_of_neighbor)
N = size(lamda, 1);
distance = zeros(N, N);
for i = 1: N
    for j = 1: N
        s = lamda(i, :) - lamda(j, :);
        distance(i, j) = sqrt(s * s');  % 记录欧氏距离
    end
end

for i = 1: N
    [~, index] = sort(distance(i, :));
    f(i, :) = index(1: num_of_neighbor);
end