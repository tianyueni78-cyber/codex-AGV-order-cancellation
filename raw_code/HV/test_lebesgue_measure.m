function [hv_leb]=test_lebesgue_measure(F,ref_point)
% F：m个非支配解的输入格式：m*n_obj矩阵  n_obj为目标个数；
% ref_point：参考点，输入格式：列向量；
% [] = test_lebesgue_measure()
%
% Computes the hypervolumes of all non-dominated function value
% settings stored as text-files in the current directory. These
% text-files should be tab-separated files where each row
% represents a vector of function values.
%
% IMPORTANT:
%   Considers Minimization of the objective function values!
%
% Author: Johannes W. Kruisselbrink
% Last modified: March 17, 2011
F = F';
[ref_point_F] = compute_reference_point(F, 0);
minus=ref_point-ref_point_F;
sign=(minus>=0);
len=length(find(sign==1));
if len~=size(F,1)
    warning('reference_point is determined not correctly');
end
hv_leb = lebesgue_measure(F, ref_point);
%hv_mc = approximate_hypervolume_ms(F, ref_point, 1000);
%disp([ 'LEB = ', num2str(hv_leb)])
% [ref_point] = compute_reference_point(F, 1);
% hv_leb= lebesgue_measure(F, ref_point);
% hv_mc= approximate_hypervolume_ms(F, ref_point, 100);
% disp([ ': LEB = ', num2str(hv_leb), ' - MC = ', num2str(hv_mc)])
end
