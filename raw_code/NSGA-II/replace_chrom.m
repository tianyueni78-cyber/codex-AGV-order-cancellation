function f = replace_chrom(intermediate_chromosome, n_vars, obj_number, pop)
%¾«Ó¢Ñ¡Ôñ²ßÂÔ
[N, ~] = size(intermediate_chromosome);
[~, index] = sort(intermediate_chromosome(:, n_vars + obj_number + 1));

for i = 1: N
    sorted_chromosome(i,:)=intermediate_chromosome(index(i),:);
end
max_rank=max(intermediate_chromosome(:,n_vars+obj_number+1));
previous_index=0;
for i=1:max_rank
    current_index=max(find(sorted_chromosome(:,n_vars+obj_number+1)==i));
    if current_index>pop
        remaining=pop-previous_index;
        temp_pop=sorted_chromosome(previous_index+1:current_index,:);
        [temp_sort,temp_sort_index]=sort(temp_pop(:,n_vars+obj_number+2),'descend');
        for j=1:remaining
            f(previous_index+j,:)=temp_pop(temp_sort_index(j),:);
        end
        return;
    elseif current_index<pop
        f(previous_index+1:current_index,:)=sorted_chromosome(previous_index+1:current_index,:);
    else
        f(previous_index+1:current_index,:)=sorted_chromosome(previous_index+1:current_index,:);
        return;
    end
    previous_index=current_index;
end