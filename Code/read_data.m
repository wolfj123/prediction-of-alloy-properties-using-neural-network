function [p t]  = read_data(path, output)

%The following function is used to read data from a CSV database in the
%following form:
%E12,50
%E13,50
%P46,7
%,
%E26,75
%E14,25
%P46,7
%And transforms it into two matrices: p and t, to be used with an artificial
%neural network.

%Possible inputs:path, wich is the input path (char vector)
% and output, which is the output target.
%If possible, used save file in future uses, as function is rather resource
%consuming.
% default path: '../Database/Scraping Matweb/clean.csv'
% default output: 'data.mat'

%No rights reserved. Feel free to change, redistribute or otherwise use
%this code. Just admit it isn't yours...

%#ok<*ST2NM>

%Open input file
fid = fopen(path);
%Read it, line by line, specifying comm-seperated cells
A = textscan(fid, '%s %s', 'Delimiter',',');


%Close the fid
fclose(fid);
%Assign left-hand (descriptors) matrix.
lft = (A{1,1});
%Assign right-hand (value) matrix.
rght =(A{1,2});
%Specify size; Both matrix have the same, so taking any means the same.
[m ,~] = size(lft);


%Create empty matrices to hold the final properties and composition data.
%values are rather arbitrary, based on current database. Doesn't need to
%change, whatever databse size is it.
properties =   zeros(60,1077);
composition =zeros(154      ,1077);

%set the dataset pointer to one
line = 1;

%For every entry,
for i=1:m
    %Put the current descriptor data in cur
    cur = cell2mat(lft(i) );
    %And the current value data in val as a double.
    val = str2double(cell2mat(rght(i)));
    
    leng = numel(cur);
    %Then, if descriptor has 0 characters & val is empty,
    if leng == 0 && isnan(val)
            %Advance to the next dataset (Put further information in the
            %next dataset)
            line = line+1;
    elseif leng ==0 %Else if descriptor has 0 characters,
        %Do nothing
    elseif cur(1) == 'P' %Else if descriptor is a property descriptor, 
        %Choose the correct line (Property number)
        col =   str2num (cur(2:leng));  
        %Put into properties, in the correct matrix cell (based on which
        %database we use and the property number) the value.
        properties(col,line) = val;
    elseif cur(1) == 'E' %Else if descriptor is a composition descriptor, 
        %Choose the correct line (Element number)
        col =   str2num (cur(2:leng));
         %Put into properties, in the correct matrix cell (based on which
        %database we use and the element number) the value.
        composition(col,line) = val;
    else
    end
end

%Set which sets are to be deleted: Those that have absolutly nothing in
%their "composition", I.E have no composition data available.
todelete = ~sum(composition)==0;

%Delete those sets.
composition = composition(:,todelete);
properties = properties(:,todelete);

%Arbitrary.
p = composition;
t = properties;
save(output, 'p','t');