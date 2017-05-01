%looping over battfunc alternitive
%Must run netPV_electbillcalc_30min to prepare Result structure
clear all; close all; clc
tic

load Result

PV_AC_yr = Result.P_AC;

monthdays = [31 28 31 30 31 30 31 31 30 31 30 31 29];
leapyearflag = 0;  %Set to 1 if leapyear 

[ PV_AC_mat ] = Eyear2month( PV_AC_yr,leapyearflag); %PV_AC_MAT(month number, day number, readingnumber)

exc_read_mat = ['01_Jan.xlsx';'02_Feb.xlsx';'03_Mar.xlsx';'04_Apr.xlsx';'05_May.xlsx';'06_Jun.xlsx'; ...
    '07_Jul.xlsx';'08_Aug.xlsx';'09_Sep.xlsx';'10_Oct.xlsx'; '11_Nov.xlsx'; '12_Dec.xlsx'];

currentreadings=0;
for month_no = 1:12;
    rawusage = xlsread(exc_read_mat(month_no,:), 'E:E');
    read_num=length(rawusage);
    for i = 1:read_num
        raw_usage_vec(i+currentreadings,1) = rawusage(i);
    end
      currentreadings=length(raw_usage_vec);
end
total_length = length(raw_usage_vec);
for i= 1:total_length/2
    tworeadsum = raw_usage_vec(((2*i)-1))+raw_usage_vec(2*i);
    tworeadavg = tworeadsum;
    raw_usage_yr(i,1) = tworeadavg;
end

[ rawusage_mat ] = Eyear2month( raw_usage_yr,leapyearflag); %rawusage_mat(month number, day number, readingnumber)
[ battdata ] = battprep( PV_AC_mat,rawusage_mat);  %battdata(reading num, solar(1) or load (2), day num, month num)

battinput.battdata = battdata;

save battinput battinput
 
                
            
    
    
    
            