function [d] = lbfgs(g,s,y,Hdiag)
% BFGS Search Direction
%
% This function returns the search direction as computed by (L-BFGS)
% approximate INVERSE Hessian, multiplied by the gradient
%
% If you pass in all previous directions/sizes, it will be the same as full BFGS
% If you truncate to the k most recent directions/sizes, it will be L-BFGS
%
% p is number of dimensions, k is the history
% s - previous search directions i.e., x - x_old (p by k)
% y - previous step sizes i.e., g - g_old (p by k)
% g - current gradient (p by 1)
% Hdiag - value of initial Hessian diagonal elements (scalar)

% see LBFGS wikipedia article

[p,k] = size(s);

for i = 1:k
    ro(i,1) = 1/(y(:,i)'*s(:,i));
end

q = zeros(p,k+1);
r = zeros(p,k+1);
al =zeros(k,1);
be =zeros(k,1);

q(:,k+1) = g;

for i = k:-1:1
    al(i) = ro(i)*s(:,i)'*q(:,i+1);
    q(:,i) = q(:,i+1)-al(i)*y(:,i);
end

% Multiply by Initial Hessian
r(:,1) = Hdiag*q(:,1);

for i = 1:k
    be(i) = ro(i)*y(:,i)'*r(:,i);
    r(:,i+1) = r(:,i) + s(:,i)*(al(i)-be(i));
end
d=r(:,k+1);