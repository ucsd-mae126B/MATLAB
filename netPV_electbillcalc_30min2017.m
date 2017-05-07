
tic
%%%%%%%%%%%%%%%%%%%Create a PV year long vector%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Ensure the Input_Data is in the Current Folder %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Output = PVenergyVec %%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;clear all;close all;
load Input_Data

T_begin=Input_Data.T_begin; T_end=Input_Data.T_end; T_step=Input_Data.T_step;

if T_end<T_begin
    disp('The ending time should be greater than the begining time ');
else
    Lat=Input_Data.Lat; Lon=Input_Data.Lon; Lz=Input_Data.Lz;
    if isfield(Input_Data, 'PV_eff'), PV_eff=Input_Data.PV_eff; else PV_eff=0.2; end
    if isfield(Input_Data, 'PV_loss'), PV_loss=Input_Data.PV_loss; else PV_loss=0.9; end
    if isfield(Input_Data, 'Max_Inv'), Max_Inv=Input_Data.Max_Inv; else Max_Inv=0.95; end
    %
    if isfield(Input_Data, 'KW_DC')
        KW_DC=Input.Data.KW_DC;
    else
        if isfield(Input_Data, 'Area'), Area=Input_Data.Area; else Area=1; disp('Calculation is for unit area (kW/m^2)'); end
        KW_DC=Area*PV_eff;
    end
    %
    if isfield(Input_Data, 'KW_AC'), KW_AC=Input_Data.KW_AC; else KW_AC=KW_DC*PV_loss*Max_Inv; end
    %
    if isfield(Input_Data, 'Azimuth')
        Azimuth=Input_Data.Azimuth;
    else
        if Lat>0, Azimuth=180; else Azimuth=0; end
    end
    if isfield(Input_Data, 'Tilt'), Tilt=Input_Data.Tilt; else Tilt=abs(Lat); end
    PV_angles=[(Azimuth-180) Tilt];
    %
    Time=[T_begin:T_step/(24*60):T_end]';
    %
    GHI=Input_Data.GHI;
    %
    if isfield(Input_Data, 'DHI')
        DHI=Input_Data.DHI;
    else
        if isfield(Input_Data, 'DNI')
            DNI=Input_Data.DNI;
            SA_angle=SA_angle_calc(Time, Lat, Lon, Lz);
            DHI=GHI-sin(SA_angle.*pi/180).*DNI;
        else
            %Using Boland function to calculate DHI in case that there is niether DHI nor DNI
            Ra=CIMIS_ET_calc(Time, Lat, Lon, Lz); kt=GHI./Ra; dt=1./( 1+exp(-5.00+8.60*kt) ); %coo
            DHI=GHI.*dt;
        end
        DHI(DHI<0)=0;
    end
    %POA Irradiation
    [GI,Dir,Diff,Refl]=POA_calc(PV_angles, Time, Lat, Lon, GHI, DHI, Lz); GI(GI<=0)=0;
    
    %Temp Eff
    if isfield(Input_Data, 'Temp_Amb')
        Temp_Amb=Input_Data.Temp_Amb;
        if isfield(Input_Data, 'Wind_Speed'), Wind_Speed=Input_Data.Wind_Speed; else Wind_Speed=0; end
        Temp_Cell=celltemp_calc(GI, Temp_Amb, Wind_Speed, 46, 1)-273.15;
        E_Temp=1-0.005.*(Temp_Cell-25); 
    else
        E_Temp=1;
    end
    %
    %DC
    P_DC=E_Temp.*GI*KW_DC*PV_loss/1000;
    %
    %Inv Eff
    pfact=P_DC/KW_AC;
    E_Inv=pfact./(0.007+(1.009*pfact)+(0.0375*(pfact.^2))); E_Inv(isinf(E_Inv))=NaN; E_Inv=E_Inv*Max_Inv/nanmax(E_Inv);
    %
    %AC
    P_AC=P_DC.*E_Inv;
    %
    PV_Tot_Energy=nansum(P_AC)*T_step/60;
    PVenergyVec = P_AC.*T_step/60;
end

Result.GI=GI; Result.P_DC=P_DC; Result.P_AC=P_AC;
Result.Tot_Energy=PV_Tot_Energy;
save Result Result

clearvarlist =['clearvarlist';setdiff(who,{'PVenergyVec'})];
clear(clearvarlist{:});

%Create a current energy consumption vector in 30 min step, calcualtes net usage with PV %
%%%%%%%%% Ensure that Monthly Data is in the Current Folder %%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Output = new_usage_vec, net_E_usage  %%%%%%%%%%%%%%%%%%%%%


start_mo = 1;
end_mo = 12;

currentreadings=0;
for month_no = start_mo:end_mo;

    exc_read_mat = ['01_Jan.xlsx';'02_Feb.xlsx';'03_Mar.xlsx';'04_Apr.xlsx';'05_May.xlsx';'06_Jun.xlsx'; ...
    '07_Jul.xlsx';'08_Aug.xlsx';'09_Sep.xlsx';'10_Oct.xlsx'; '11_Nov.xlsx'; '12_Dec.xlsx'];

    usage=xlsread(exc_read_mat(month_no,:), 'E:E');
    read_num=length(usage);
   
    for i = 1:read_num
        usage_vec(i+currentreadings,1) = usage(i);
    end
      currentreadings=length(usage_vec);
end
total_length = length(usage_vec);
for i= 1:total_length/2
    tworeadsum = usage_vec(((2*i)-1))+usage_vec(2*i);
    tworeadavg = tworeadsum;
    new_usage_vec(i,1) = tworeadavg;
end

net_E_usage = new_usage_vec - PVenergyVec;

%%%%%%%%%%%%%%%%%%%%%%Create A Matrix of net E Usage%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Output = netEmat %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvarlist =['clearvarlist';setdiff(who,{'PVenergyVec','net_E_usage','new_usage_vec'})];
clear(clearvarlist{:});

 ns=30;  %Set the time step in minutes (of usage readings)
 nr=(24*(60/ns)); %number of readings per day

 monthvec = [31 28 31 30 31 30 31 31 30 31 30 31]; %Setting the number of days per month
 netEmat = zeros(12,max(monthvec*nr));
 mo_vec = zeros(1,max(monthvec*nr));
 readcount = 0;
for mo_num = 1:12
  read_tot= nr * monthvec(mo_num);
  for read_num = 1:read_tot 
      mo_vec(read_num) = net_E_usage(read_num + readcount);
  end
  netEmat(mo_num,:) = mo_vec(:);
  readcount = readcount + read_tot;
  mo_vec = zeros(1,max(monthvec*nr));
end
 
%%%%%%%%%%%%%%%%% Calculate New Energy Cost on net Energy %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% Output = netresults structure %%%%%%%%%%%%%%%%%%%%%%

start_mo = 1;
end_mo = 12;

%Initializing the results vectors
bill_total_vec_net = zeros(1,12);
deliv_charge_vec_net= zeros(1,12);
gen_charge_vec_net= zeros(1,12);
onpkcharge_vec_net= zeros(1,12);
noncoincident_charge_vec_net= zeros(1,12);
onpeak_vec_net= zeros(1,12);
offpeak_vec_net= zeros(1,12);
semipeak_vec_net= zeros(1,12);
DWR_charge_vec = zeros(1,12);
gendemand_charge_vec = zeros(1,12);



for month_no = start_mo:end_mo;

    year = 2014; %Set the year
    ns=30;  %Set the time step in minutes (of usage readings)
    nr=(24*(60/ns)); %number of readings per day

    monthvec = [31 28 31 30 31 30 31 31 30 31 30 31]; %Setting the number of days per month
    start_day = [year, month_no, 1]; %The start date of the looping month 
    end_day = [year, month_no, monthvec(month_no)]; %The end date of the looping month

    monthdays= monthvec(month_no); %Reading the number of days in the looping month

    data.netusage = netEmat(month_no,:); %Reading in usage data for the looping month

    %Electricity Rates - Default ones are listed as "secondary" on SDGE website
    %2014 Electricity Rates
    %Electricity Rates - Default ones are listed as "secondary" on SDGE website
    %demand charges
    noncoincident_rate=24.51;
    maxonpeak_sum_rate=10.25;
    maxonpeak_winter_rate=7.57;

    %distribution rates 
    sum_onpeak_rate=.00424;
    sum_semipeak_rate=.00424;
    sum_offpeak_rate=.00424;
    wint_onpeak_rate=.00424;
    wint_semipeak_rate=.00424;
    wint_offpeak_rate=.00424;

    %generation rates
    sum_genrate_onpeak=.011783;
    sum_genrate_semipeak=.10809;
    sum_genrate_offpeak=.07724;
    wint_genrate_onpeak=.10595;
    wint_genrate_semipeak=.09040;
    wint_genrate_offpeak=.06898;
    sum_gendemand_rate=10.88;
    wint_gendemand_rate=.00;

    %DWR Bond Rate
    DWR_rate=.00549;

 
 
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
           onpeak(i)=data.netusage(i);
            %deleting points with no usage bc they won't contribute to the total
            %bill
            onpeak(onpeak==0)=[];
            %If the hour is offpeak save the usage to the offpeak vector   
        elseif data.time(i) > offpkhr2 && data.time(i) <= 24; %Evening off peak hours
            offpeak(i)=data.netusage(i);
            offpeak(offpeak==0)=[];
        elseif  data.time(i) > 0 && data.time(i) <= offpkhr1;  %Morning off peak hours
            offpeak(i)=data.netusage(i);
            offpeak(offpeak==0)=[];
        elseif data.time(i) == -1;  %Weekend off peakhours
            offpeak(i) = data.netusage(i);
            offpeak(offpeak==0)=[];
        else %If non of the prior conditions are met then the time is semi-peak, save to semi-peak vector
            semipeak(i)=data.netusage(i);
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
    non_coin_usage=max(data.netusage)*(60/ns);
    noncoincident_charge=non_coin_usage*noncoincident_rate;

    %max on-peak demand
    onpkmax=max(onpeak);
    onpkcharge=onpkmax*(60/ns)*maxonpeak_rate;

    %SD Franchise Fee Differential: 5.78%


    %Generation Demand Charge
    gendemand_charge=gen_demand_rate*onpkmax*(60/ns);

    %DWR Bond Charge
    DWR_charge=sum(data.netusage)*DWR_rate;

    %Delivery Charges
    deliv_charge=(sum(onpeak)*onpeak_rate+sum(offpeak)*offpeak_rate+sum(semipeak)*semipeak_rate);

    %Summing generation charge
    gen_charge=(sum(onpeak)*genrate_onpeak+sum(offpeak)*genrate_offpeak+sum(semipeak)*genrate_semipeak);

    %totalling charges
    bill_total=noncoincident_charge+onpkcharge+DWR_charge+deliv_charge+gen_charge+gendemand_charge;

    %Vectors to save of Net usage
    onpeak_vec_net(month_no) = sum(onpeak);
    offpeak_vec_net(month_no) = sum(onpeak);
    semipeak_vec_net(month_no) = sum(semipeak);

    %Vectors to save of monthly data
    bill_total_vec_net(month_no) =  bill_total;
    deliv_charge_vec_net(month_no) =  deliv_charge;
    gen_charge_vec_net(month_no) = gen_charge;
    onpkcharge_vec_net(month_no) =  onpkcharge;
    noncoincident_charge_vec_net(month_no) =  noncoincident_charge;
    DWR_charge_vec(month_no) = DWR_charge;
    gendemand_charge_vec(month_no) = gendemand_charge;


    clearvarlist =['clearvarlist';setdiff(who,{'bill_total_vec_net';'deliv_charge_vec_net';'gen_charge_vec_net';'onpkcharge_vec_net';'noncoincident_charge_vec_net';'onpeak_vec_net';'offpeak_vec_net';'semipeak_vec_net';'DWR_charge_vec';'gendemand_charge_vec';'netEmat'})];
    clear(clearvarlist{:});
end

netresults.nettotal=bill_total_vec_net;
netresults.netdeliv=deliv_charge_vec_net;
netresults.netgeneration=gen_charge_vec_net;
netresults.netonpeak=onpkcharge_vec_net;
netresults.netnoncoincident=noncoincident_charge_vec_net;

netresults.netonpeakuse=onpeak_vec_net;
netresults.netoffpeakuse=offpeak_vec_net;
netresults.netsemipeakuse=semipeak_vec_net;
netresults.netDWR=DWR_charge_vec;
netresults.netgendemand = gendemand_charge_vec;
save netresults netresults

clear all; 
toc
