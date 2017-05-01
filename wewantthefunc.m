function [dcload, pvdc, Pss, netload] = wewantthefunc( output, maxsofar , monthnum )
%load loopingmat

if monthnum > 4 && monthnum <11
    seasonflag = 1;
else
    seasonflag = 0;
end

dt = 0.5;
t = 0:dt:24-dt;
readingsperday = 24*(1/dt);

pv = output(:,1);
pvenergy = pv.*dt;
rawdemand = output(:,2);
sysDCrating = max(pv);
pvforecast = pvenergy;
rawdemandforecast = rawdemand;

% specs for the SANYO DCB-102 battery array

nbatt = 47; %original number=47 %number of batteries = ~twice the output of the solar array (~17 kW)
Esunit = 1.587; %total (nominal) capacity of 1 batt unit, kWh
Vnom = 48.1;  %nominal battery operating voltage, Volts
Vcharge = 52;  %nominal battery charging voltage, Volts
icharge = 6.6;  %battery charging current, Amperes
idischarge = 15; %battery discharging current, Amperes

safetyfac = .9;
Estotal = nbatt*Esunit;
Es_min = 0.2*Estotal;  
Es_max = 0.99*Estotal;  %lower and upper storage bound on the battery, kWh
Ps_min = -Vcharge*icharge*nbatt/1000; 
Ps_max = Vnom*idischarge*nbatt/1000;  % lower and upper charging rate bound, kW
Rs_min = Ps_min/(0.009/3600); 
Rs_max = Ps_max/(0.009/3600);  %lower and upper charging ramp rate bound, kW/h

Ro_min = -1000000;
Ro_max = 1000000;  %kW/h

rtflag = 1;  %flag to initiate real time optimization


%%%%%%%%%%%%%%%%%%%%% compute the first opimized trajectory
Estart = Es_max;
Eo = Estart;
Pi = pvforecast;  %PV output forecast
Pl = rawdemandforecast; %DC load forecast  

xg1 = Pl-Pi;
xg2 = Pl;
xg = [xg1; xg2];
[ Po, Ps, Es, Rs, Ro, netcost, exitflag ] = solaroptfun_lt(t, dt, Pi, Pl, Es_min, Es_max, Eo, Ps_min, Ps_max, Ro_min, Ro_max, Rs_min, Rs_max, [], [], sysDCrating, xg);

Ps(Ps>Ps_max) = Ps_max;
Ps(Ps<Ps_min) = Ps_min;

netdemandwpv = rawdemand-pv;
Ps(netdemandwpv<maxsofar)=0
netdemandwbatt = rawdemand-pv-Ps;
if max(netdemandwbatt)>maxsofar
    maxsofar = max(netdemandwbatt);
end
Ps(netdemandwbatt<maxsofar) = netdemandwpv(netdemandwbatt<maxsofar) - maxsofar;
netdemandwbatt = rawdemand-pv-Ps;

% Ps_one = Ps
% %Ps_one(netdemandpv < maxsofar) = 0
% 
% if exitflag<=0
%     error('First optimization iteration failed!')
% end
% 
% if rtflag
% 
%     netloadenergy = Pl-Pi;  %Energy requirements with PV
%     netloadenergy(netloadenergy<0) = 0;  %Never let enery requirements be less than 0
%     
%     idealdispatch = netloadenergy - maxsofar;  %Ideal battery dispatch
%     idealdispatch(idealdispatch<0) = 0
%     idealdailyload = sum(idealdispatch);
%     
%      if Ps_one < safetyfac*(Es_max-Es_min)
%             dispatch_mode_flag = 1  %1 indicates real time storage dispatch
%             
%         else
%             dispatch_mode_flag = 2        %2 indicates optimized storage dispatch
%      end
% 
%     switch dispatch_mode_flag
%         case 1    %Realtime
%             battoutput = idealdispatch;
%             Psnew = battoutput;
%             Psnew(Psnew<0) = 0;
%             
%         case 2   %Optimizied
%             Psnew = Ps_one;
%     end
%     

%     
%     %Prevent Charging during on peak hours
    if seasonflag == 0
        %Winter on peak hours are 17 - 20
        onpeakstart = (1/dt)*17;
        onpeakend = (1/dt)*20;
    else
        %Summer on peak hours are 11 - 18
        onpeakstart = (1/dt)*11;
        onpeakend = (1/dt)*18;
    end
    
    for peakreading = onpeakstart:onpeakend
       if Ps(peakreading) < 0
           Ps(peakreading) = 0;
       else
           Ps(peakreading) = Ps(peakreading);
       end
    end
     netdemandwbatt = rawdemand-pv-Ps;
     
     dcload = rawdemand*(1/dt);
     pvdc = pv;
     Pss = Ps;
     netload = netdemandwbatt;
  
end