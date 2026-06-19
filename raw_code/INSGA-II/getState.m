function state=getState(delt_Hv,delt_Sp)
if delt_Hv>0 && delt_Sp<0
    state=1;
elseif delt_Hv>0 && delt_Sp>=0
    state=2;
elseif delt_Hv<=0 && delt_Sp<0
    state=3;
elseif delt_Hv<=0 && delt_Sp>=0
    state=4;
else
    state = 4;
    %     if delt_Hv>0
    %         state=1;
    %     else
    %         state = 2;
end
end



