function IGD_value=IGD_compution(PF_point,obj_matrix)
IGD_value=0;
for i=1:size(PF_point,1)
    distance=Inf;
    for j=1:size(obj_matrix,1)
        D=norm(PF_point(i,:)-obj_matrix(j,:));
        if D<distance
            distance=D;
        end
    end
    IGD_value=IGD_value+distance;
end
IGD_value=IGD_value/size(PF_point,1);
end