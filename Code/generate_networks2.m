%FILE: generate_networks2.m
%SIZE: 6.02 KB
%MATLAB_VERSION: R2011a
%--------------------------------------------------------------------------
%ABSTRACT: The following script is aimed at creating and finding the first
%best error that can be achieved with the method for every element and
%every property.
%--------------------------------------------------------------------------
%DEPENDENCIES: read_data.m, clean.csv/data.mat (atleast one),
%remove_duplicates.m, TrainTest1.m, statistics2.m 
%--------------------------------------------------------------------------
%All rights reserved, 2011 (c) Jonathan Wolf <jonathanwolf09@yahoo.com> and Omri Glass <omri_ilanoth1@hotmail.com> 
%Permission is given to modify and/or use parts of this code in a different
%context while credit is given. Do not make commercial use of this code.
%--------------------------------------------------------------------------
%LAST EDIT: Thursday, June 30th, 2011


%Matlab Editor directives.
%#ok<*SAGROW>
%#ok<*NOPTS>


%%%Define model parametres
%--------------------------------------------------------------------------




clear, clc;

hid_layer_size=7;   % default = 7
hid_layer_size2 =2;   % default = 2
trainfunc = 'trainscg'; %Set the training function: trainscg, traingdx, trainlm etc. default = trainscg
transfunc = 'logsig';  %Which transfer function to use: logsig, tansig, purelin, hardlim. etc. default = logsig
statistical_significance = 20; %Number of sets that are considered statistically significant. default = 20
goalError=0.0000005;        % what goal error (MSE) do we have? default = 0.0000005
MAX_EPOCH=1000;                 %Maximum number of epochs; almost never reaches 1000. default = 1000

perc = 0.7;                               %What percent of P is P_TRAIN. default = 0.7

num_of_tests = 1000;        %How many networks to manufacture. default = 1000


edges = 0.15;      %default = 0.15
threshold = 50;% default = 50

six_elements = [12 13 25 26 28 29] %Choose the elements (by atomic number);


load data.mat

[composition properties] = remove_duplicates(p,t);

counter = 0;

%Main Loop
%--------------------------------------------------------------------------

for iterator=16:20
    tic
   for second_iterator=1:6
       clear list

       if(iterator == 1 && second_iterator == 1 && num_of_tests == 1000)
            continue
       end
        if(iterator == 6 && second_iterator < 6 && num_of_tests == 1000)
            continue
       end
		props = iterator;   %Selects output Properties (Properties #). default = 8
		reinforced_element =   six_elements(second_iterator); %Select main test Element. default = 13
		%Define whether we try and figure property-from-property or property-from-composition

		%If false, following doesn't matter. If true, it defines which properties
		%to use as input to calculate output properties.





		% Load data from CSV file
		%This function takes quite a bit of time and effort. Instead of calling it
		%everytime, comment it out after initial run.

		%read_data('../Database/Scraping Matweb/clean.csv', 'data.mat');



		%%%Load and process the database. END OF PARAMETER AREA - MODIFY WITH CARE.
		%--------------------------------------------------------------------------


		NUMBER_OF_PROPERTIES=numel(props); % See how many output properties we have.


		%Reset p,t and input into them the elements we need: Output property into t
		%and input (properties OR composition) into p. 
		clear p
		clear t
		  
		good_data = (sum(properties(props,:) ~= 0 ,1) ==  numel(props))         & composition(reinforced_element,:) >0 ;
		if props == 16  %There's an oddity regarding electrical resistivity.
			good_data = sum(properties(props,:) ~= 0 ,1) ==  numel(props) & properties(props,:)<1                 & composition(reinforced_element,:) >0 ;     
		end
			% Creates a logical matrix, where every 0 is a point in which there's a
			% missing output parameter. (As there's always composition data
			% available)


		 
		 
		 %Use the matrix to choose the "good" data.
		t = properties(props,good_data);
		p = composition(:,good_data);






		%Normalize.
		MaxT =max( max(properties(props,:))) ;
		t = t/MaxT;

		MaxP = 100;
		p = p/MaxP;
			


		%If the amount of sets is statistically significant,
		if(numel(t) > statistical_significance)


		% Create the SAVIOR cell array to hold NET objects that are to be kept for further use.
		savior = {};



		%For each test,
		for w=1:num_of_tests
		 


			%Show progress,
			current =(iterator-1)*6*num_of_tests + (second_iterator-1)*num_of_tests+ w-1;
			maximum = num_of_tests * 20 * 6;
			percentage =(current)/(maximum)*100;
			fprintf( '%d / %d (%.2f%%) \n', current,maximum,percentage )
			
			%Divide input and ouput matrices into test and train matrices, by a
			%ratio defined by perc.
			[p_test,p_train,t_test,t_train,rtest]=TrainTest1(p,t,perc);
			
			
		  
			%Create a new network object
			net = newff(p,t, [ hid_layer_size  hid_layer_size2]  ,{ transfunc   transfunc  },trainfunc);

			%Prevent unwanted data from showing
			net.trainParam.showWindow = false;
			net.trainParam.showCommandLine = false;
			
			%set NET parametres
			net.trainParam.goal = goalError;
			net.trainParam.epochs = MAX_EPOCH;

			%train NET object using P_TRAIN AND T_TRAIN
			[net tr] = train(net,p_train,t_train);


			%Calculate parametres using NET.
			a1 = abs(sim(net,p_test));
			
			%save error percentage in the LIST matrix.
			list(:,:,w) = abs((a1(:,:)-t_test(:,:))./t_test(:,:))*100;

			%Save the NET object for use outside the loop.
			savior{w} = net; 


		end

		else 
			fprintf( 'There are only %i data sets availible. Not statistically significant, as defined by user.\n',  numel(t)  )
		end
		%Save state.
		fname = strcat('output/APF_' ,num2str(reinforced_element),'_' ,num2str(props),'_'  ,num2str(num_of_tests) , '.mat')
		save(fname );
   end
   counter(iterator) =toc;
end
statistics2
%---------------------------------%
%%% END OF FILE %%%%