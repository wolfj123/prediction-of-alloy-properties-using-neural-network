function [ p t ] = remove_duplicates( p, t )

%remove_duplicates removes datasets from p and t as denoted by exact duplicates
%found in p.

%Since p and t have the same size in n, this is arbitrary. n is the number
%of distinct datasets.
[m n] = size(p);

idxs = 0;

%For every dataset combination,
for i=1:n 
    
for j=i:n
     %if the number of equal rows is exactly the number of rows AND it's
     %not the same dataset,
    if (sum(p(:,i) == p(:,j)) == m  ) && i ~= j
        %as well as the i dataset isn't registered for deletion already,
         if sum(idxs==i) == 0
             %Mark j for deletion.
          idxs(end+1) = j; %#ok<AGROW>

         end
    end
end    
    
end

%Choose all to delete besides the first one (which always equals 0)
idxs = idxs(2:end);
%Create a logical matrix
idxs3 = true(1,n);
%Mark the ones to delete as "false"
idxs3(idxs) = false;
%Choose only the sets that are marked as "true" and discard the rest.
p =p(:,idxs3);
t = t(:,idxs3);


end

