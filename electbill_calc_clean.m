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

tic
format compact
format long
clear all; close all; clc;

%Set month & year 

start_mo = 1;
end_mo = 12;

%Initializing the results vectors
bill_total_vec = zeros(1,12);
deliv_charge_vec= zeros(1,12);
gen_charge_vec= zeros(1,12);
onpkcharge_vec= zeros(1,12);
noncoincident_charge_vec= zeros(1,12);
onpeak_vec= zeros(1,12);
offpeak_vec= zeros(1,12);
semipeak_vec= zeros(1,12);



%For loop prints out data for each of the 12 months, set the start month &
%end month for desired data range
for month_no = start_mo:end_mo;

    year = 2014; %Set the year
    ns=15;  %Set the time step in minutes (of usage readings)
    nr=(24*(60/ns)); %number of readings per day

    monthvec = [31 28 31 30 31 30 31 31 30 31 30 31]; %Setting the number of days per month
    start_day = [year, month_no, 1]; %The start date of the looping month 
    end_day = [year, month_no, monthvec(month_no)]; %The end date of the looping month

    monthdays= monthvec(month_no); %Reading the number of days in the looping month

    %Excel file names for data of each month
    exc_read_mat = ['01_Jan.xlsx';'02_Feb.xlsx';'03_Mar.xlsx';'04_Apr.xlsx';'05_May.xlsx';'06_Jun.xlsx'; ...
        '07_Jul.xlsx';'08_Aug.xlsx';'09_Sep.xlsx';'10_Oct.xlsx'; '11_Nov.xlsx'; '12_Dec.xlsx'];


    data.usage=xlsread(exc_read_mat(month_no,:), 'E:E'); %Reading in usage data for the looping month

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

 
 
    start_day_no=weekday(datenum(start_day)); %Finding the day of the week for day 1 of looping month
    x=(datenum(start_day):datenum(end_day))'; %Vector of days of the looping month in serial number form
    r=repmat(x,1,nr)'; %creates a nr long matrix of x
    data.date=r(:); %Save the serial date matrix of looping month


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
    data.time=repmat([0:(ns/60):23.99],1,monthdays)'; %Creating a time vector for each day of the month

    %flagging weekends as -1 in time vector to sort out later
    [daynum, dayname] = weekday(data.date);
    for i=1:numel(data.dayno);
        if data.dayno(i) == 6;
            data.time(i)=-1;
        elseif data.dayno(i) == 7;
         data.time(i)=-1;
        end
    end




    %splitting into on, semi, off peak

    for i=1:length(data.time); %length = 24*(readings per hour)*(days in looping month)
    %SUMMER PEAK TIME HOURS
        if month(data.date(i)) > 4 && month(data.date(i)) < 11 %If the month is a summer month, set the summer rates
            onpkhr1=11;
            onpkhr2=18;
            offpkhr1=6;
            offpkhr2=22;
            month_flag(i)='S';%flagging as summer month
        else %If the month is a winter month, set the winter rates
            %winter hours
            onpkhr1=17;
            onpkhr2=20;
            offpkhr1=6;
            offpkhr2=22;
            month_flag(i)='W';%winter months
        end

        if data.time(i) <= onpkhr2 && data.time(i) > onpkhr1; %If the hour is onpeak save the usage to an onpeak vector
           onpeak(i)=data.usage(i);
            %deleting points with no usage bc they won't contribute to the total
            %bill
            onpeak(onpeak==0)=[];
            %If the hour is offpeak save the usage to the offpeak vector   
        elseif data.time(i) > offpkhr2 && data.time(i) <= 24; %Evening off peak hours
            offpeak(i)=data.usage(i);
            offpeak(offpeak==0)=[];
        elseif  data.time(i) > 0 && data.time(i) <= offpkhr1;  %Morning off peak hours
            offpeak(i)=data.usage(i);
            offpeak(offpeak==0)=[];
        elseif data.time(i) == -1;  %Weekend off peakhours
            offpeak(i) = data.usage(i);
            offpeak(offpeak==0)=[];
        else %If non of the prior conditions are met then the time is semi-peak, save to semi-peak vector
            semipeak(i)=data.usage(i);
            semipeak(semipeak==0)=[];
        end
    end

    %Summer vs Winter Rates
    if month_flag(1) ~= month_flag(length(data.time)); %ensuring the first and last day in the looping month is the same season
        sprintf('Please make sure all data is in same season');
    elseif month_flag(1) == 'W'; %If the reading is flagged as a winter month, set the winter rates
        onpeak_rate = wint_onpeak_rate;
        semipeak_rate = wint_semipeak_rate;
        offpeak_rate = wint_offpeak_rate;
        genrate_onpeak = wint_genrate_onpeak;
        genrate_semipeak = wint_genrate_semipeak;
        genrate_offpeak=wint_genrate_offpeak;
        maxonpeak_rate=maxonpeak_winter_rate;
        gen_demand_rate=wint_gendemand_rate;
    else %Otherwise the reading is flagged as a summer month, set the winter rates
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

    %Vectors to save of Net usage
    onpeak_vec(month_no) = sum(onpeak);
    offpeak_vec(month_no) = sum(onpeak);
    semipeak_vec(month_no) = sum(semipeak);

    %Vectors to save of monthly data
    bill_total_vec(month_no) =  bill_total;
    deliv_charge_vec(month_no) =  deliv_charge;
    gen_charge_vec(month_no) = gen_charge;
    onpkcharge_vec(month_no) =  onpkcharge;
    noncoincident_charge_vec(month_no) =  noncoincident_charge;

    clearvarlist =['clearvarlist';setdiff(who,{'bill_total_vec';'deliv_charge_vec';'gen_charge_vec';'onpkcharge_vec';'noncoincident_charge_vec';'onpeak_vec';'offpeak_vec';'semipeak_vec'})];
    clear(clearvarlist{:});
end

results.total=bill_total_vec;
results.deliv=deliv_charge_vec;
results.generation=gen_charge_vec;
results.onpeak=onpkcharge_vec;
results.noncoincident=noncoincident_charge_vec;

results.onpeakuse=onpeak_vec;
results.offpeakuse=offpeak_vec;
results.semipeakuse=semipeak_vec;

toc
