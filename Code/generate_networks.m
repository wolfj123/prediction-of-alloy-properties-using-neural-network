%FILE: generate_networks.m
%SIZE: 5.87 KB
%--------------------------------------------------------------------------
%ABSTRACT: The following script is aimed at manufacturing an artificial neural
%network capable of calculating different alloy properties based solely on
%alloy composition.
%The code first sets a few parametres, and then loads a database, either
%from a .csv or a .mat file (.csv loading is quite slow; use once, and then
%load from .mat file).
%It then proceeds by training num_of_tests networks and moves over to
%statistics.m
%--------------------------------------------------------------------------
%DEPENDENCIES: read_data.m, clean.csv/data.mat (atleast one),
%remove_duplicates.m, TrainTest1.m, statistics.m 
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
 
hid_layer_size=7;   % default = 7
hid_layer_size2 =2;   % default = 2
trainfunc = 'trainscg'; %Set the training function: trainscg, traingdx, trainlm etc. default = trainscg
transfunc = 'logsig';  %Which transfer function to use: logsig, tansig, purelin, hardlim. etc. default = logsig
statistical_significance = 20; %Number of sets that are considered statistically significant. default = 20
goalError=0.0000005;        % what goal error (MSE) do we have? default = 0.0000005
MAX_EPOCH=1000;                 %Maximum number of epochs; almost never reaches 1000. default = 1000

perc = 0.7;                               %What percent of P is P_TRAIN. default = 0.7

num_of_tests = 12;        %How many networks to manufacture. default = 1000


props = 20;   %Selects output Properties (Properties #). default = 8
reinforced_element =   26; %Select main test Element. default = 13
%Define whether we try and figure property-from-property or property-from-composition

%If false, following doesn't matter. If true, it defines which properties
%to use as input to calculate output properties.


edges = 0.15;      %default = 0.15
threshold = 50;% default = 50



% Load data from CSV file
%This function takes quite a bit of time and effort. Instead of calling it
%everytime, comment it out after initial run.

%read_data('../Database/Scraping Matweb/clean.csv', 'data.mat');



%%%Load and process the database. END OF PARAMETER AREA - MODIFY WITH CARE.
%--------------------------------------------------------------------------

prop_from_prop = false;

load data.mat

%Keep P and T in a safe place.
composition = p;
properties = t;







NUMBER_OF_PROPERTIES=numel(props); % See how many output properties we have.

%Reset p,t and input into them the elements we need: Output property into t
%and input (properties OR composition) into p. Also, remove any
%insignificant composition properties.

clear p
clear t
 t = properties( props ,:);
 if prop_from_prop
     p = properties(props_input,:); %#ok<UNRCH>
 else 
   
  p = composition(:,:);
  
  
 end

%remove Duplicates
[p t] = remove_duplicates(p,t);



 if prop_from_prop == true
    good_data = sum(t ~= 0 ,1) ==  numel(props) & sum(p > 0 ,1)==numel(props_input);
    
% Creates a logical matrix, where every 0 is a point in which there's a
% missing input or output parameter.
 else
     good_data = sum(t ~= 0 ,1) ==  numel(props);
     if props == 16  %There's an oddity regarding electrical resistivity.
    good_data = sum(t ~= 0 ,1) ==  numel(props) & t<1;     
     end
    % Creates a logical matrix, where every 0 is a point in which there's a
    % missing output parameter. (As there's always composition data
    % available)
 end

 
 
 %Use the matrix to choose the "good" data.
t = t(:,good_data);
p = p(:,good_data);


% Choose data that has the chosen element but doesn't cross the threshold
% concentration of it.
t = t(:,p(reinforced_element,:) < threshold            & p(reinforced_element,:) >0 );
p = p(:,p(reinforced_element,:) < threshold          & p(reinforced_element,:) >0   ); 





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
    percentage =(w-1)/(num_of_tests)*100;
	fprintf( '%d / %d (%.2f%%) \n', w-1,num_of_tests,percentage )
    
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
fname = strcat('APF_' ,num2str(reinforced_element),'_' ,num2str(props),'_'  ,num2str(num_of_tests),'_' , '.mat')
save(fname );

statistics
%---------------------------------%
%%% END OF FILE %%%%

