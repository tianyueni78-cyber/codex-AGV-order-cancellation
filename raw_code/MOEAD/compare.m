function chebyshev=compare(fit,i,lamda,obj_min)
for j=1:length(lamda(i,:))
    if lamda(i,j)==0
        lamda(i,j)=1E-5;
    end
    lamda(i,j)=1/lamda(i,j);
end
chebyshev=max(lamda(i,:).*abs(fit-obj_min));
end