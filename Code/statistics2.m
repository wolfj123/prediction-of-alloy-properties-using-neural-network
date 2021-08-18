%FILE: statistics2.m
%SIZE: 9.27 KB
%MATLAB_VERSION: R2011a
%--------------------------------------------------------------------------
%ABSTRACT: The following script is aimed at processing data from
%generate_networks2.m. It does statistics, including mainly standard
%deviations and mean error values. It also tests the generated networks
%using the rest of the database (Where concentration > 50%  as well as a
%special case when concentration = 100%). It uses a main nested loop to 
%go over every single saved session.
%--------------------------------------------------------------------------
%DEPENDENCIES: generate_networks2.m (or a state-save of it in the output folder),
%clean.csv/data.mat (atleast one), beym.mat
%--------------------------------------------------------------------------
%All rights reserved, 2011 (c) Jonathan Wolf <jonathanwolf09@yahoo.com> and Omri Glass <omri_ilanoth1@hotmail.com> 
%Permission is given to modify and/or use parts of this code in a different
%context while credit is given. Do not make commercial use of this code.
%--------------------------------------------------------------------------
%LAST EDIT: Thursday, June 30th, 2011


%Matlab Editor directives.
%#ok<*SAGROW>
%#ok<*NOPTS>

%Define the elements we use
six_elements = [12 13 25 26 28 29];
%Define how many networks are best.
num_of_networks = 5;

%For every property checked in generate_networks2
for iterator=1:20
	%There's an anomality regarding property 12; it doesn't work.
    if iterator == 12
        continue
    end
	%For every element we test for,
   for second_iterator=1:numel(six_elements)
		%Delete every variable that is not vital,
		clearvars -except iterator second_iterator six_elements num_of_networks
		
		%Load the appropriate file
        fname = strcat('output/APF_' ,num2str(six_elements(second_iterator)),'_' ,num2str(iterator),'_'  ,num2str(1000) , '.mat')
        load(fname );
       
       %Print the progress
		current =(iterator-1)*6 + (second_iterator-1);
		maximum = 20 * 6;
		percentage =(current)/(maximum)*100;
		fprintf( '%d / %d (%.2f%%) \n', current,maximum,percentage )
		
		NUMBER_OF_PROPERTIES=numel(props); % See how many output properties we have.

		%Create new input matrices
		clear p
		clear t
		t = properties( props ,:);
		p = composition(:,:);




		%Select data to keep: only where both the element and the property are in place.
		good_data = (sum(properties(props,:) ~= 0 ,1) ==  numel(props))         & composition(reinforced_element,:)>0 ;
		if props == 16  %There's an oddity regarding electrical resistivity requiring the top-most values <10^6) be removed.
			good_data = sum(properties(props,:) ~= 0 ,1) ==  numel(props) & t<1                 & composition(reinforced_element,:)>0 ;     
		end
		%If there isn't enough data available, continue.
		if (sum(good_data))  <5
			continue
		end
 
		%Use the matrix to choose the "good" data.
		t = t(:,good_data);
		p = p(:,good_data);




		%Normalize (with pre-calculated values).
		t = t/MaxT;
		p = p/MaxP;

		%remove Duplicates
		[p t] = remove_duplicates(p,t);

		%Since we later have a new independent data set holding the pure element
		%data, keep the current in p_1 and t_1.
		p_1  = p;
		t_1 = t;





		%Read from .mat after first run of read_data, for efficiency.
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
		%error on both indices.
		bestest(1,:) = error_at_edges;
		bestest(2,:) = database_error;
 
 
		%bestest(4,:) = std_train;
		%bestest(5,:) = std_calculated;

 
 
		%Sort networks by quality.
		[~, indexing] = sort(mean(bestest));


		%Display area.
		%--------------------------------------------------------------------------


		[~, sets_trained_on] = size(p_train);
		 %-------------------------------------------------------------------------
		 mean_train_error = squeeze(mean_train_error(1,1,indexing(1:10)))';
		 %-------------------------------------------------------------------------
		std_train = squeeze(std_train(1,1,indexing(1:10)))';
		%-------------------------------------------------------------------------
		pure_element_error = pure_element_error(indexing(1:10));
		 %-------------------------------------------------------------------------
		 [ ~,size_of_db_check] = size(t_1);
		 %-------------------------------------------------------------------------
		 database_variance = std(t_1*MaxT);
		 %-------------------------------------------------------------------------
		database_error = database_error(indexing(1:10));
		 %-------------------------------------------------------------------------
		 std_calculated =std_calculated(indexing(1:10));
		 %-------------------------------------------------------------------------
		 error_vs_median = error_vs_median(indexing(1:10));
		%-------------------------------------------------------------------------
		std_median = std_median(indexing(1:10));
		%-------------------------------------------------------------------------
		error_at_edges = error_at_edges(indexing(1:10));
		%-------------------------------------------------------------------------
		error_vs_median_at_edges = error_vs_median_at_edges(indexing(1:10));
		%-------------------------------------------------------------------------
		best_five_element_error = mean(pure_element_error(1:num_of_networks));
		%-------------------------------------------------------------------------
		best_five_db_error = mean(abs(mean(a1_1(indexing(1:num_of_networks), : ) )-t_1) ./t_1*100);


		%Select the correct line to write to in the EXCEL file.
		liner = 6*(iterator-1)+second_iterator;
		%Select the correct rectangle to write to in the EXCEL file.
		range = strcat('A',num2str(liner),':N', num2str(liner));
		%Generate file name to save the Best networks to.
		fname = strcat('Best Brains/APF_' ,num2str(reinforced_element),'_' ,num2str(props),'_'  ,num2str(num_of_networks) , '.mat');
		
		%Save everything.
		toSave = savior(indexing(1:num_of_networks));
		save(fname,'toSave');
		xlswrite('Supplementary Tables/statistics.xlsx', [sets_trained_on(1)  mean_train_error(1) std_train(1)   pure_element_error(1)     size_of_db_check(1)    database_variance(1)    database_error(1)    std_calculated(1)     error_vs_median(1)    std_median(1)    error_at_edges(1)       error_vs_median_at_edges(1)     best_five_element_error(1)        best_five_db_error(1)     ], range);

   end
end
%---------------------------------%
%%% END OF FILE %%%%




