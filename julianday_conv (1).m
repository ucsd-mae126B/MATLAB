function daynumber=julianday_conv(month, day)

%Calculating Julian day No. "daynumber" given:
% 1: month number "month"
% 2. day number in month "day"
%
day_no=[31 28 31 30 31 30 31 31 30 31 30 31];
daynumber=0;
for i1=1:month-1
    daynumber=daynumber+day_no(i1);
end
daynumber=daynumber+day;