clear all; close all; clc;

%Input data for the performance model
%
%Fields marked by (*) are required, (o) are optional
%GHI, DNI, DHI, Temp_Amb, and Wind_speed must be vectors of the same size
% 
%
%(*) Site Latitude [degrees]
Input_Data.Lat=33.25; 

%(*) Site Longitude [degrees]
Input_Data.Lon=-117.15;

%(*) Local Time Zone: Lz=120 (Pacific), Lz=105 (Mountain), Lz=90 (Central), Lz=75 (Eastern), Lz=150 (Hawaii)
Input_Data.Lz=120;

%(*) Serial date number at the center of the first time step, =datenum(Year, month, day, hour, min, sec) 
Input_Data.T_begin=datenum(2014, 1, 1, 0, 0, 0);

%(*) Serial date number at the center of the last time step, =datenum(Year, month, day, hour, min, sec)
Input_Data.T_end=datenum(2014, 12, 31, 23, 30, 0);

%(*) Timeseries time step interval [min]
Input_Data.T_step=30;

%(*) Global Horizontal Irradiation (GHI) at the PV site [W/m^2]
Input_Data.GHI=xlsread('2014_33.285_-117.155_windTemp.xlsx', 'B:B');

%(o) Direct Normal Irradiation (DNI) at the PV site [W/m^2]
%Input_Data.DNI
Input_Data.DNI=xlsread('2014_33.285_-117.155_windTemp.xlsx', 'C:C');

%(o) Diffuse Horizontal Irradiation (DHI) at the PV site [W/m^2]
%Input_Data.DHI=xlsread('1hr_Data_EuroAmerican_Propogators_2011_1_1.xlsx', 'C:C');

%(o) Ambient Temperature at the PV site [^oC]
Input_Data.Temp_Amb=xlsread('2014_33.285_-117.155_windTemp.xlsx', 'D:D');

%(o) Wind Speed at the PV site [m/s]
Input_Data.Wind_Speed=xlsread('2014_33.285_-117.155_windTemp.xlsx', 'E:E');

%(o) PV Array Total Area [m^2]
Input_Data.Area=100;

%(o) PV site DC rated capacity at standard test conditions [kW] 
%Input_Data.KW_DC

%(o) PV site AC rated capacity [kW]
%Input_Data.KW_AC=80;

%(o) Azimuth : PV panel azimuth angle [degrees]. South azimuth = 180. East azimuth = 90. West azimuth = 270.
%Input_Data.Azimuth

%(o) Tilt: Tilt :  PV panel tilt angle [degrees] (default = Lat)
%Input_Data.Tilt=33;

%(o) PV_eff: PV module efficiency at standard test conditions [-] (default = 0.2)
%Input_Data.PV_eff

%(o) PV_loss: Other losses (soiling, line losses, ...) [-] (default=0.9)
%Input_Data.PV_loss

%(o) Max_Inv: Maximum Inverter Efficiency [-] (default=0.95)
%Input_Data.Max_Inv
%
save Input_Data Input_Data

%%%%%%%%%

%
T_begin=Input_Data.T_begin; T_end=Input_Data.T_end; T_step=Input_Data.T_step;
%
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
    %
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

%
Result.GI=GI; Result.P_DC=P_DC; Result.P_AC=P_AC;
Result.Tot_Energy=PV_Tot_Energy;
save Result Result

clearvarlist =['clearvarlist';setdiff(who,{'PVenergyVec'})];
clear(clearvarlist{:});

%%%%%%%
%Set month & year 
start_mo = 1;
end_mo = 12;

%For loop prints out data for each of the 12 months, comment out the 'for'
%and end statements to run an individual month.
yearusage = 0;
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

total_length = length(usage_vec)
for i= 1:total_length/2
    tworeadsum = usage_vec(((2*i)-1))+usage_vec(2*i);
    tworeadavg = tworeadsum;
    new_usage_vec(i,1) = tworeadavg;
end

net_Energy = new_usage_vec - PVenergyVec
