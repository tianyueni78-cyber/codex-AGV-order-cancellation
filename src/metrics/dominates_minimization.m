function isDominated = dominates_minimization(objA, objB)
%DOMINATES_MINIMIZATION Return true when A dominates B for minimization.

isDominated = all(objA <= objB) && any(objA < objB);
end
