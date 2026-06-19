%2个优化目标 9个非支配解
obj_matrix=[191,543.95;
    192,532.15;
    196,531.40;
    197,523.40;
    198,521.40;
    203,521;
    204,520.40;
    205,517.40;
    207,494.60;
    209,494.40]; 
ref_point=[1000;1000];
HV=test_lebesgue_measure(obj_matrix,ref_point);
disp(['HV：',num2str(HV)])