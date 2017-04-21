%clear all; close all; clc;

% Photovoltaic power output performance model
% See also the report "A Power Conversion Model for Distributed PV Systems in California Using SolarAnywhere Irradiation" by M Jamaly, JL Bosch, Jan Kleissl posted at http://calsolarresearch.ca.gov/component/option,com_sobipro/Itemid,0/pid,54/sid,65/

% This software is Copyright © 2013 The Regents of the University of California. All Rights Reserved.
% Permission to copy, modify, and distribute this software and its documentation for educational, research and non-profit purposes, without fee, and without a written agreement is hereby granted, provided that the above copyright notice, this paragraph and the following three paragraphs appear in all copies.

% Permission to make commercial use of this software may be obtained by contacting:
% Technology Transfer Office
% 9500 Gilman Drive, Mail Code 0910
% University of California
% La Jolla, CA 92093-0910
% (858) 534-5815
% invent@ucsd.edu

% This software program and documentation are copyrighted by The Regents of the University of California. The software program and documentation are supplied "as is", without any accompanying services from The Regents. The Regents does not warrant that the operation of the program will be uninterrupted or error-free. The end-user understands that the program was developed for research purposes and is advised not to rely exclusively on the program for any reason.

% IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO
% ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
% CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING
% OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
% EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE. THE UNIVERSITY OF
% CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
% INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
% THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO
% PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
% MODIFICATIONS.

% INPUT: see "Perf_model_input.m"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Temp_Cell : PV module temperature [^oC]
%  E_Temp : Temperature efficiency [-]
%  E_Inv : Inverter efficiency [-]
%
%  Result structure containing:
%    GI : Plane of Array global irradiance [W/m^2]
%    P_DC : DC output power [kW]
%    P_AC : AC output power [kW]
%    Tot_Energy : Total output energy during the given period [kWh]
%   

load Input_Data
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
    Tot_Energy=nansum(P_AC)*T_step/60;
end
clear Input_Data
%
Result.GI=GI; Result.P_DC=P_DC; Result.P_AC=P_AC;
Result.Tot_Energy=Tot_Energy;
save Result Result
