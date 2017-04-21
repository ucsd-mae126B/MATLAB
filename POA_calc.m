function [tilt_out,Dir,Diff,Refl] = POA_calc(tilt,time,Lat,Lon,Gh,Dh,Lz)

%Calculating Plane of Array global(tilt_out), direct (Dir), diffuse
%(Diff),and reflective (Refl) Irradiances [W/m^2] given:

% 1. tilt= [azimuth, tilt from horizontal] in degrees. 
%  South azimuth = 0. East azimuth = -90. West azimuth = 90. E.g. 10 degrees east of south, 20o tilt = [-10 20]
% 2. time= MATLAB time vector (must be column vector)
% 3. Lat = Latitude [degrees]
% 4. Lon = Longitude (west is negative) [degrees]
% 5. Gh  = Global Horizontal Irradiance (GHI)
% 6. Dh  = Diffuse Horizontal Irradiance
% 7. Lz  = Local Time Zone: Lz=120 (Pacific), Lz=105 (Mountain), Lz=90 (Central), Lz=75 (Eastern)
%
% Based on Page model
%
alpha=tilt(1);
Beta=tilt(2);
%
time_vec = datevec(time);
DoY = ceil( time - datenum(time_vec(1),1,1) );
ToD = time_vec(:,4)+time_vec(:,5)/60+time_vec(:,6)/3600; clear time_vec
% find net longwave radiation
ep=1+0.03344*cos(2*pi/365.25 * DoY-0.048869);
b = 2*pi/364*(DoY-81);
delta = 0.409 * sin(2*pi/365*DoY-1.39); clear DoY
Sc = 0.1645 * sin(2*b) - 0.1255 * cos(b) - 0.025*sin(b);
omega = pi/12 * ( ToD + 1/15*(Lz+Lon)+Sc -12  ) ; % ASCE
clear ToD
%
phi = pi*Lat/180;
%solar altitude
gamma_s = asin(sin(phi)*sin(delta) + cos(phi)*cos(delta).*cos(omega)); % CIMIS & ASCE, radians!
%
%find solar azimuth angle
cos_alpha_s=(sin(phi).*sin(gamma_s)-sin(delta))./(cos(phi).*cos(gamma_s));
sin_alpha_s=cos(delta).*sin(omega)./cos(gamma_s);

t=length(time);
alpha_s=zeros(t,1);
%
for i=1:1:t
    if sin_alpha_s(i)<0
        alpha_s(i)=-acos(cos_alpha_s(i));
    else
        alpha_s(i)=acos(cos_alpha_s(i));
    end
end
alpha_s=alpha_s.*180/pi;%convert to degrees
%
%angle of incidence
alpha_F=alpha_s-alpha;
for j=1:1:t
    if alpha_F(j)<-180
        alpha_F(j)=alpha_F(j)+360;
    end
    if alpha_F(j)>180
        alpha_F(j)=alpha_F(j)-360;
    end
end
alpha_F=alpha_F.*pi/180;%radians

Beta=Beta.*pi/180;
%find angle of incidence
nu=acos(cos(gamma_s).*cos(alpha_F).*sin(Beta)+sin(gamma_s).*cos(Beta));
%
Bn=zeros(t,1);
for n=1:1:t
    if gamma_s(n)>(1/180)*pi
        Bn(n)=(Gh(n)-Dh(n))./sin(gamma_s(n));
    else
        Bn(n)=0;
    end
end
%
B=zeros(t,1);
for l=1:1:t
    if cos(nu(l))>0
        B(l)=Bn(l).*cos(nu(l));
    else
        B(l)=0;
    end
end
%
Kb=zeros(t,1);
for p=1:1:t
    if abs(gamma_s(p))>0.001
        Kb(p)=(Gh(p)-Dh(p))./(ep(p).*1367.*sin(gamma_s(p)));
    else
        Kb(p)=(Gh(p)-Dh(p))./(ep(p)*1367*.001);
    end
end
%
f_Beta=(cos(Beta/2)).^2+(0.00263-0.712.*Kb-0.6883.*Kb.^2).*(sin(Beta)-Beta.*cos(Beta)-pi.*(sin(Beta/2)).^2); %for Southern Europe/Geneva, change (0.00263...) term as necessary
Dhtilt_Dh=zeros(t,1);
%
for m=1:1:t
    if gamma_s(m)>5.7.*pi/180
        dh1(m)=f_Beta(m).*(1-Kb(m));
        dh2(m)=Kb(m).*cos(nu(m))./sin(gamma_s(m));
        dh3(m)=1;
        Dhtilt_Dh(m)=f_Beta(m).*(1-Kb(m))+Kb(m).*cos(nu(m))./sin(gamma_s(m));
    else
        dh1(m)=(cos(Beta/2))^2*(1+Kb(m)*(sin(Beta/2)^3));
        dh2(m)=(1+Kb(m)*(cos(nu(m)))^2*(sin(pi/2-gamma_s(m)))^3);
        dh3(m)=2;
        Dhtilt_Dh(m)=(cos(Beta/2))^2*(1+Kb(m)*(sin(Beta/2)^3))*(1+Kb(m)*(cos(nu(m)))^2*(sin(pi/2-gamma_s(m)))^3);
    end
end
%Reflected
rB=(1-cos(Beta))./2;
rho_g=0.2; %could add more complex albedo
Refl=rB.*rho_g.*Gh;

Diff=Dhtilt_Dh.*Dh;
Dir=B;
%
tilt_out=Dir+Diff+Refl;
end