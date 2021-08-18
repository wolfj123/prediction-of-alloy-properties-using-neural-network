function [p_train,p_test,t_train,t_test,rtest]=TrainTest1(p,t,perc)

%The following function divides two matrices into randomly-chosen pairs of
%test and train. To be used with an Artificial Neural Network.
%p and t are matrices with the same amount of datasets (columns) in them.
%perc = division ratio, numel(t_train)/numel(t). default = 0.7


n=floor(perc*size(p,2));
r=randperm(size(p,2));
r1 = r(1:n);
r2 = r(n:end);
t_train = t(:,r2);
p_train = p(:,r2);

t_test = t(:,r1);
p_test = p(:,r1);

rtest = r1;