function [CELLTMP,GROUNDTMP] = celltemp_calc(POATOT, AMBTEM, WS, INOCT, array_height)

% (c) Sasa Pregelj
% 
% Estimates the Array Temperature CELLTMP [K](and ground temperature GROUNDTMP [K]) given:
% 1. POA radiation POATOT [W/m2]
% 2. Ambient Temperature AMBTEM [C]
% 3. Wind Speed WS [ m/s]
% 4. Nominal Operating PV panel Temperature [C]
% 5. Array Height [m]
%
% Uses the Simplified Fuentes PV Array Thermal Model.
%

% Convert temperatures to K
INOCT	= INOCT + 273.15;
AMBTEM	= AMBTEM + 273.15;

% Initial values & various constants
T_module_0 = AMBTEM;
DTIME = 1;
sigma           = 5.669E-8;
emissivity      = 0.84;
absorptivity    = 0.83;
XLEN            = 0.5;
CAPO            = 11000;

% FIRST-TIME-ONLY CALCULATIONS (when IFLAGC is set to 0)
% solve the equation at INOCT (800W/m2 insolation, 20C ambient temp., 1m/s wind speed)
% the only variable is INOCT
WINDMD   =   1;
T_avg    = (INOCT + 293.15) / 2;
DENAIR   = 0.003484 * 101325 / T_avg;
VISAIR   = 0.24237E-6 * T_avg^0.76 / DENAIR;
CONAIR   = 2.1695E-4 * T_avg^0.84;
REYNLD   = WINDMD * XLEN / VISAIR;
HFORCE   = 0.8600 / REYNLD^0.5 * DENAIR * WINDMD * 1007 / 0.71^0.67;
GRASHF   = 9.8 / T_avg * (INOCT-293.15) * XLEN^3 / VISAIR^2 * 0.5;
HFREE    = 0.21 * (GRASHF * 0.71)^0.32 * CONAIR / XLEN;
h_conv   = (HFREE^3 + HFORCE^3)^(1/3);
hr_ground    = emissivity * sigma * (INOCT^2 + 293.15^2) * (INOCT + 293.15);
BACKRT       = (absorptivity * 800 - emissivity * sigma * (INOCT^4 - 282.21^4) - h_conv * (INOCT - 293.15)) / ...
	( (hr_ground + h_conv) * (INOCT - 293.15) );
T_ground     = ( INOCT^4 - BACKRT * (INOCT^4 - 293.15^4) )^0.25;

if T_ground > INOCT
	T_ground=INOCT;
end;
if T_ground < 293.15
	T_ground=293.15;
end;
TGRAT    = (T_ground - 293.15) / (INOCT - 293.15);
CONVRT   = ( absorptivity * 800 - emissivity * sigma * ( 2 * INOCT^4 - 282.21^4 - T_ground^4 ) ) / ...
	( h_conv * (INOCT - 293.15) );
CAP=CAPO;
if INOCT > 321.15
	CAP  = CAP * ( 1 + (INOCT - 321.15)/12 );
end;
   

% the rest of the code is executed for each hour of the day
% variables are POATOT, AMBTEM, WS
T_ambient   = AMBTEM;
SUN         = POATOT * absorptivity;
SUNO        = [0; POATOT(1:end-1)] * absorptivity; %SUNO=SUNO(:);%insolation at previous step
WINDMD  = WS * (array_height/9.144)^0.2 + 0.0001;

T_sky   = 0.68 * (0.0552 * T_ambient.^1.5) + 0.32 * T_ambient;

% solve for T_module
T_module    = T_module_0;
iter = 1;epsilon = 1;
while epsilon>1e-3 && iter<10
	
	T_avg    = (T_module + T_ambient) / 2;
    
    DENAIR  = 0.003484 * 101325 ./ T_avg;
    VISAIR  = 0.24237E-6 * T_avg.^0.76 ./ DENAIR;
    CONAIR  = 2.1695E-4 * T_avg.^0.84;
    REYNLD  = WINDMD .* XLEN ./ VISAIR;
    
    HFORCE  = 0.8600 ./ REYNLD.^0.5 .* DENAIR .* WINDMD * 1007 / 0.71^0.67;
    tmp = find(REYNLD > 1.2E5);
    HFORCE(tmp) = 0.0282 ./ REYNLD(tmp).^0.2 .* DENAIR(tmp) .* WINDMD(tmp) * 1007 / 0.71^0.4;
    
    GRASHF  = 9.8./ T_avg .* abs(T_module - T_ambient) * XLEN^3 ./ VISAIR.^2 * 0.5;
    HFREE   = 0.21 * (GRASHF .* 0.71).^0.32 .* CONAIR ./ XLEN;
    
    h_conv  = CONVRT * ( HFREE.^3 + HFORCE.^3 ).^(1/3);
    
    hr_sky      = emissivity * sigma * (T_module.^2 + T_sky.^2) .* (T_module + T_sky);
    
    T_ground    = T_ambient + TGRAT .* ( T_module - T_ambient );
    hr_ground   = emissivity * sigma * (T_module.^2 + T_ground.^2) .* (T_module + T_ground);
    
    EIGEN   = -(h_conv + hr_sky + hr_ground) ./ CAP * DTIME * 3600;
    EX=zeros(size(T_ambient));
    tmp = find(EIGEN > -10);
    EX(tmp) = exp(EIGEN(tmp));
    
    T_module_new = T_module_0 .* EX + ... 
        ( (1-EX) .* ( h_conv .* T_ambient + hr_sky .* T_sky + hr_ground .* T_ground + SUNO + (SUN-SUNO)./EIGEN )   + SUN - SUNO ) ./ ...
        (h_conv + hr_sky + hr_ground);
    
	epsilon = max( abs(T_module_new - T_module) );
	
	T_module = T_module_new;
	T_module_0 = [AMBTEM(1); T_module(1:end-1)]; T_module_0 = T_module_0(:);
    
	iter = iter+1;
end
CELLTMP  =   T_module;
GROUNDTMP = T_ground;