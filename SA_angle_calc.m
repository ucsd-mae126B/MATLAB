function [SA_angle]=SA_angle_calc(Time, lat, lon, Lz)

%Calculating Solar Altitude Angle using
% 1. Time = MATLAB time vector
% 2. lat = Latitude [degrees]
% 3. lon = Longitude (west is negative) [degrees]
% 4. Lz  = Local Time Zone: Lz=120 (Pacific), Lz=105 (Mountain), Lz=90 (Central), Lz=75 (Eastern)
%
phi_ang= pi*lat/180;
%
time_vec=datevec(Time);
julian_day=julianday_conv(time_vec(:,2), time_vec(:,3));
%
for k1=1:length(julian_day)
    DoY=julian_day(k1); coef_b= 2*pi/364*(DoY-81);
    delta_ang = 0.409* sin(2*pi/365*DoY-1.39); % delta = Declination of the sun above the celestial equator (radians)
    coef_sc = 0.1645 * sin(2*coef_b) - 0.1255 * cos(coef_b) - 0.025*sin(coef_b);
    %
    ToD=(time_vec(k1,4)+time_vec(k1,5)/60+time_vec(k1,6)/3600);
    omega_ang= pi/12*(ToD + 1/15*(Lz+lon)+coef_sc-12); % ASCE
    SA_angle(k1,1)= asin(sin(phi_ang)*sin(delta_ang) + cos(phi_ang)*cos(delta_ang).*cos(omega_ang))*180/pi;
end