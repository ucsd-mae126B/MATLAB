%clear all
tic
close all
clc
format compact
format long
%Program to calculate the electricity bill given an excel file input with
%date, time, and usage data. 
%The usage will then be divided into on peak semi peak and off peak. 
%The output of the file will be the calculated bill cost. Time should be in military time.
%SOME of the output charges and the total bill estimate are saved in an
%array called results.

%Edited by Lucas Thexton: Enter month_no variable for desired month data.
%Currently only for PV only data, not PV+ battery

%Written by Michael Kelleghan for MAE 199 EuroAmerican Propogators Project
%with Canjie Zhong, Overseen by Dr. Jan Kleissl

clear all; close all;
%Set month & year 
start_mo = 1;
end_mo = 12;

bill_total_vec = zeros(1,12);
deliv_charge_vec= zeros(1,12);
gen_charge_vec= zeros(1,12);
onpkcharge_vec= zeros(1,12);
noncoincident_charge_vec= zeros(1,12);


%For loop prints out data for each of the 12 months, comment out the 'for'
%and end statements to run an individual month.


for month_no = start_mo:end_mo;
%month_no = 1;
year = 2014; 
ns=15; %time step in minutes (of usage readings)
monthvec = [31 28 31 30 31 30 31 31 30 31 30 31]; %
start_day = [year, month_no, 1];
end_day = [year, month_no, monthvec(month_no)];

monthdays=monthvec(month_no);

exc_read_mat = ['01_Jan.xlsx';'02_Feb.xlsx';'03_Mar.xlsx';'04_Apr.xlsx';'05_May.xlsx';'06_Jun.xlsx'; ...
    '07_Jul.xlsx';'08_Aug.xlsx';'09_Sep.xlsx';'10_Oct.xlsx'; '11_Nov.xlsx'; '12_Dec.xlsx'];

%Reading in usage data
data.usage=xlsread(exc_read_mat(month_no,:), 'E:E');
%for i=1:days
%pp(:,i)=answer(month_no,i).netdemand;
%end
%data.usage=pp(:);


%Electricity Rates - Default ones are listed as "secondary" on SDGE website
%2014 Electricity Rates

%Electricity Rates - Default ones are listed as "secondary" on SDGE website
%demand charges
noncoincident_rate=19.96;
maxonpeak_sum_rate=9.84;
maxonpeak_winter_rate=6.27;

%distribution rates 
sum_onpeak_rate=.0055;
sum_semipeak_rate=.0055;
sum_offpeak_rate=.0055;
wint_onpeak_rate=.00442;
wint_semipeak_rate=.00241;
wint_offpeak_rate=.00148;

%generation rates
sum_genrate_onpeak=.12322;
sum_genrate_semipeak=.11280;
sum_genrate_offpeak=.0825;
wint_genrate_onpeak=.09259;
wint_genrate_semipeak=.08513;
wint_genrate_offpeak=.06343;
sum_gendemand_rate=10.50;
wint_gendemand_rate=.18;

%DWR Bond Rate
DWR_rate=.00513;


%days=datenum(end_date)+1-datenum(start_date);
 nr=(24*(60/ns)); %number of readings per day
 
 start_day_no=weekday(datenum(start_day));
 x=(datenum(start_day):datenum(end_day))';
 r=repmat(x,1,nr)'; %creates a nr long matrix of x
data.date=r(:);


%Setting up vector corresponding to days of the week so that weekends can
%be stored into off peak

%setting up day-number vector 
for j=1:numel(x);
day_no(j)=weekday(x(j)); %Gives a weekday # to each day
end

%repeating the day-numbers to match up with usage data points
daynumbers=repmat(day_no,nr,1);
data.dayno=daynumbers(:);


%data.time is represented in hours
data.time=repmat([0:(ns/60):23.99],1,monthdays)';

%flagging weekends as -1 and weekdays as 1 in time vector to sort out later
[daynum, dayname] = weekday(data.date);
for i=1:numel(data.dayno);
    if data.dayno(i) == 6;
        data.time(i)=-1;
    elseif data.dayno(i) == 7;
        data.time(i)=-1;
end
end




%splitting into on, semi, off peak

for i=1:length(data.time);
    %SUMMER PEAK TIME HOURS
if month(data.date(i)) > 4 && month(data.date(i)) < 11
    onpkhr1=11;
    onpkhr2=18;
    offpkhr1=6;
    offpkhr2=22;
    constant(i)='S';%flagging as summer month
else
    %winter hours
    onpkhr1=17;
    onpkhr2=20;
    offpkhr1=6;
    offpkhr2=22;
    constant(i)='W';%winter months
end

if data.time(i) <= onpkhr2 && data.time(i) > onpkhr1;
    onpeak(i)=data.usage(i);
    %deleting points with no usage bc they won't contribute to the total
    %bill
    onpeak(onpeak==0)=[];
    
%finding off peak    
elseif data.time(i) > offpkhr2 && data.time(i) <= 24;
    offpeak(i)=data.usage(i);
    offpeak(offpeak==0)=[];
elseif  data.time(i) > 0 && data.time(i) <= offpkhr1;  
    offpeak(i)=data.usage(i);
    offpeak(offpeak==0)=[];
elseif data.time(i) == -1;
    offpeak(i) = data.usage(i);
    offpeak(offpeak==0)=[];
else
    semipeak(i)=data.usage(i);
    semipeak(semipeak==0)=[];
end
end

%Summer vs Winter Rates
if constant(1) ~= constant(length(data.time));
    sprintf('Please make sure all data is in same season');
elseif constant(1) == 'W';
    onpeak_rate = wint_onpeak_rate;
    semipeak_rate = wint_semipeak_rate;
    offpeak_rate = wint_offpeak_rate;
    genrate_onpeak = wint_genrate_onpeak;
    genrate_semipeak = wint_genrate_semipeak;
    genrate_offpeak=wint_genrate_offpeak;
    maxonpeak_rate=maxonpeak_winter_rate;
    gen_demand_rate=wint_gendemand_rate;
else
    onpeak_rate = sum_onpeak_rate;
    semipeak_rate = sum_semipeak_rate;
    offpeak_rate = sum_offpeak_rate;
    genrate_onpeak = sum_genrate_onpeak;
    genrate_semipeak = sum_genrate_semipeak;
    genrate_offpeak=sum_genrate_offpeak;
    maxonpeak_rate=maxonpeak_sum_rate;
    gen_demand_rate=sum_gendemand_rate;
end

    
%noncoincident charge: maximum usage for an hour based on max usage of any
%time step
non_coin_usage=max(data.usage)*(60/ns);
noncoincident_charge=non_coin_usage*noncoincident_rate;

%max on-peak demand
onpkmax=max(onpeak);
onpkcharge=onpkmax*(60/ns)*maxonpeak_rate;

%SD Franchise Fee Differential: 5.78%


%Generation Demand Charge
gendemand_charge=gen_demand_rate*onpkmax*(60/ns);

%DWR Bond Charge
DWR_charge=sum(data.usage)*DWR_rate;

%Delivery Charges
deliv_charge=(sum(onpeak)*onpeak_rate+sum(offpeak)*offpeak_rate+sum(semipeak)*semipeak_rate);

%Summing generation charge
gen_charge=(sum(onpeak)*genrate_onpeak+sum(offpeak)*genrate_offpeak+sum(semipeak)*genrate_semipeak);

%totalling charges
bill_total=noncoincident_charge+onpkcharge+DWR_charge+deliv_charge+gen_charge+gendemand_charge;

%Net usage
net_usage.onpeak=sum(onpeak);
net_usage.offpeak=sum(offpeak);
net_usage.semipeak=sum(semipeak);

%Vectors to save of monthly data
bill_total_vec(month_no) =  bill_total;
deliv_charge_vec(month_no) =  deliv_charge;
gen_charge_vec(month_no) = gen_charge;
onpkcharge_vec(month_no) =  onpkcharge;
noncoincident_charge_vec(month_no) =  noncoincident_charge;

clearvarlist =['clearvarlist';setdiff(who,{'bill_total_vec';'deliv_charge_vec';'gen_charge_vec';'onpkcharge_vec';'noncoincident_charge_vec'})];
clear(clearvarlist{:});
end

results.total=bill_total_vec;
results.deliv=deliv_charge_vec;
results.generation=gen_charge_vec;
results.onpeak=onpkcharge_vec;
results.noncoincident=noncoincident_charge_vec;
%bill_total_vec
toc
