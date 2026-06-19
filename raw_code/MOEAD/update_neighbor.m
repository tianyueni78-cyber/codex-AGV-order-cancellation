function chrom=update_neighbor(chrom,neighbor,offspring,lamda,obj_min,dim)
obj_number=length(obj_min);
for i=1:length(neighbor)
    chebyshev_1=compare(chrom(neighbor(i),dim+1:dim+obj_number),neighbor(i),lamda,obj_min);
    chebyshev_2=compare(offspring(:,dim+1:dim+obj_number),neighbor(i),lamda,obj_min);
    if chebyshev_2<=chebyshev_1
        chrom(neighbor(i),:)=offspring;
    end
end