function d = weakly_dominates(fA, fB)
% [d] = weakly_dominates(fA, fB)
% Compares two solutions A and B given their objective function
% values fA and fB. Returns whether A weakly dominates B.
% Input:
% - fA					- The objective function values of solution A
% - fB					- The objective function values of solution B
% Output:
% - d					- d is 1 if fA dominates fB, otherwise d is 0

% d = (all(fA <= fB) && any(fA < fB));

%弱支配
d = true;
for i = 1:length(fA)
    if (fA(i) > fB(i))%，判断弱支配，B至少弱支配支配，外部需要修改~weakly_dominate
        d = false;
        return
    end
end
end
