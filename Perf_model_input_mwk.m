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
