function [ mergeddata ] = battprep(solar, load)
%UNTITLED4 Summary of this function goes here

%   input solar and load data w/ data broken down:
%   solar(month number, day number, readingnumber), load(month number, day number, readingnumber)

%   output is battprep where battprep(a,b,c,d) 
%   a is the sample number of the day.(1-48)
%   b is 1 for solar data and 2 for the load data. (1-2)
%   c is the day number of the month. (1-31)
%   d is the month number. (1-13)

%USE MONTH no=13 for leap year february
nodays=[31 28 31 30 31 30 31 31 30 31 30 31 29];

mergeddata = zeros(48,2,31,12);
for mono = 1:12
    for dayno=1:nodays(mono)
        mergeddata(:,1,dayno,mono)=solar(mono,dayno,:);
        mergeddata(:,2,dayno,mono)=load(mono,dayno,:);
    end
end

save mergeddata mergeddata
end

