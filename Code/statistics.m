%FILE: statistics.m
%SIZE: 7.33 KB
%MATLAB_VERSION: R2011a
%--------------------------------------------------------------------------
%ABSTRACT: The following script is aimed at processing raw data from
%generate_networks.m. It does statistics, including mainly standard
%deviations and mean error values. It also tests the generated networks
%using the rest of the database (Where concentration > 50%  as well as a
%special case when concentration = 100%)
%--------------------------------------------------------------------------
%DEPENDENCIES: generate_networks.m (or a state-save of it, raw_data.mat),
%clean.csv/data.mat (atleast one), beym.mat/ym-be.csv (atleast one)
%--------------------------------------------------------------------------
%All rights reserved, 2011 (c) Jonathan Wolf <jonathanwolf09@yahoo.com> and Omri Glass <omri_ilanoth1@hotmail.com> 
%Permission is given to modify and/or use parts of this code in a different
%context while credit is given. Do not make commercial use of this code.
%--------------------------------------------------------------------------
%LAST EDIT: Thursday, June 30th, 2011


%Matlab Editor directives.
%#ok<*SAGROW>
%#ok<*NOPTS>

first_run = false;


%load  'raw_data.mat';



% Loads data from CSV file
%This function takes quite a bit of time and effort. Instead of calling it
%everytime, use "load data.mat" after initial run.


clear p
clear t
 t = properties( props ,:);
 p = composition(:,:);





good_data = (sum(properties(props,:) ~= 0 ,1) ==  numel(props))         & composition(reinforced_element,:)>0 ;
if props == 16  %There's an oddity regarding electrical resistivity.
    good_data = sum(properties(props,:) ~= 0 ,1) ==  numel(props) & t<1                 & composition(reinforced_element,:)>0 ;     
end

 if (sum(good_data))  <5
     continue
 end
 
 %Use the matrix to choose the "good" data.
t = t(:,good_data);
p = p(:,good_data);




%Normalize (with pre-calculated values).
t = t/MaxT;
p = p/MaxP;
    
%If the amount of sets is statistically significant,


%remove Duplicates
[p t] = remove_duplicates(p,t);

%Since we later have a new independent data set holding the pure element
%data.
p_1  = p;
t_1 = t;





%See comment in line 32
%read_data( '../Database/Scraping Matweb/ym-be.csv', 'beym.mat');
load beym.mat;

%The set number of the pure element in the new database.
inner_id = find(p( reinforced_element  ,:) == 1);

%Keep it for further use
p_2  = p(:,inner_id);
t_2 = t(props,inner_id);


%Order the targets (and inputs) so that it can later choose the edge sets
%(the 15% smallest target-wise)
[ t_1, ord] = sort(t_1);
p_1 = p_1(:,ord);



%Divide according to the EDGES paramter.
%LOW
t_11 = t_1((1:round(numel(t_1) * edges)));
p_11 = p_1(:,(1:round(numel(t_1) *edges)));

%MEDIUM
t_12 =t_1(:,(round(numel(t_1) *edges)  :  round(numel(t_1)*(1-edges))  ));
p_12 = p_1(:,(round(numel(t_1) *edges)  :  round(numel(t_1) *(1-edges))  ));

%HIGH
t_13 = t_1(:,(round(numel(t_1)*(1-edges))   :end    ));
p_13 = p_1(:,(round(numel(t_1)*(1-edges))    :end  ));

%To be used to find the median value.
[~, the_end ] = size(t_1);

%For every network,
for idx = 1:num_of_tests
    
    %Calculate the lower edge values,
    a1 = sim(savior{idx},p_11);
    %Compare them to actual targets and save it in SLICE,
    slice(1,idx) = mean( abs((a1 - t_11 )./ t_11 * 100));
    
    
    %Calculate the higher edge values,
    a1 = sim(savior{idx},p_13);
    %Compare them to actual targets and save it in SLICE,
    slice(2,idx) = mean( abs((a1 - t_13 )./ t_13 * 100));

    %Calculate the lower edge values in comparison with median values and
    %store them.
     test(1,idx) = mean( abs(t_1(:,round(the_end/2)) - t_11 )./ t_11 * 100);
     %Calculate the higher edge values in comparison with median values and
     %store them.
     test(2,idx) = mean( abs(t_1(:,round(the_end/2)) - t_13 )./ t_13 * 100);
    
     %Then, calculate the entire set of inputs using the same network,
	a1 = sim(savior{idx},p_1);
    a1_1(idx,:) = a1;
	%Compare them to the actual targets and store.
    targets_vs_calculated = abs((a1 - t_1 )./ t_1 * 100);
    %compare the actual targets with the median value.
    targets_vs_median = abs((t_1(:,round(the_end/2)) - t_1 )./ t_1 * 100);
    
    %Find mean error percentage.
	database_error(idx) =mean( targets_vs_calculated);        
    error_vs_median(idx) = mean(targets_vs_median);    
 
    
    %Calculate standard deviation rates.
    std_calculated(idx) = std( targets_vs_calculated);
    std_median(idx) = std( targets_vs_median);

        
    %Calculate and compare the value of the pure element.
    a1 = sim(savior{idx},p_2) * MaxT;
    pure_element_error(idx) = abs((a1 - t_2) / t_2 )* 100;

end

%Find the mean error of both edges (Lower and Higher)
error_at_edges = mean(slice);
error_vs_median_at_edges = mean(test);

%Find the mean error and STD for the learning process test group.
mean_train_error = mean(list,2);
std_train = std(list);
 
%Create the index for finding the best network: find the lowest average
%error on all three indices.
 bestest(1,1:num_of_tests) = error_at_edges;
 bestest(2,1:num_of_tests) = database_error;


 
 
 %Sort networks by quality.
[~, indexing] = sort(mean(bestest));


%Display area.
%--------------------------------------------------------------------------


[~, sets_trained_on] = size(p_train)
 %-------------------------------------------------------------------------
 mean_train_error = squeeze(mean_train_error(1,1,indexing(1:10)))'
 %-------------------------------------------------------------------------
std_train = squeeze(std_train(1,1,indexing(1:10)))'
%-------------------------------------------------------------------------
pure_element_error = pure_element_error(indexing(1:10))
 %-------------------------------------------------------------------------
 [ ~,size_of_db_check] = size(t_1)
 %-------------------------------------------------------------------------
 database_variance = std(t_1*MaxT)
 %-------------------------------------------------------------------------
database_error = database_error(indexing(1:10))
 %-------------------------------------------------------------------------
 std_calculated =std_calculated(indexing(1:10))
 %-------------------------------------------------------------------------
 error_vs_median = error_vs_median(indexing(1:10))
%-------------------------------------------------------------------------
std_median = std_median(indexing(1:10))
%-------------------------------------------------------------------------
error_at_edges = error_at_edges(indexing(1:10))
%-------------------------------------------------------------------------
error_vs_median_at_edges = error_vs_median_at_edges(indexing(1:10))
%-------------------------------------------------------------------------
best_five_element_error = mean(pure_element_error(1:5))
%-------------------------------------------------------------------------
best_five_db_error = mean(abs(mean(a1_1(indexing(1:5), : ) )-t_1) ./t_1*100)


fname = strcat('Best Brains/APF_' ,num2str(reinforced_element),'_' ,num2str(props),'_'  ,num2str(5) , '.mat');
%---------------------------------%
%%% END OF FILE %%%%




