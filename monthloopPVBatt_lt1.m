clc;clear all;%close all

load battoutput
monthdays=[31 28 31 30 31 30 31 31 30 31 30 31 29];

startmo=1;
endmo=1;
sum41 = cumsum(monthdays);
moperiod = [monthdays(startmo:endmo)];
cumdays = sum(moperiod);
Es_max = 73.84311;
readingcount = 0
for monthno = startmo:endmo;
    %readingcount = 0
for dayno=1:monthdays(monthno);
    for readno = 1:48;
        bess(readingcount+readno) = battoutput(monthno,dayno).Ps(readno);
        netdemand(readingcount+readno) = battoutput(monthno,dayno).netdemand(readno);
        netpvdemand(readingcount+readno) = ...
            battoutput(monthno,dayno).dcload(readno)-battoutput(monthno,dayno).pvdc(readno);
        dcload(readingcount+readno) = battoutput(monthno,dayno).dcload(readno);
        pv(readingcount+readno) = battoutput(monthno,dayno).pvdc(readno);
        Battlevel(readingcount+readno) = battoutput(monthno,dayno).Battlevel(readno);
        Es_max(readingcount+readno) = 73.84311;
        Es_min(readingcount+readno) = 14.9178;
    end
    readingcount=readingcount+48;

    
    %close all
end
end
%     figure(1)
%     plot(0.5:0.5:24*monthdays(monthno),bess)
%     hold on
%     plot(0.5:0.5:24*monthdays(monthno),netdemand,'LineWidth',3);
%     %
%     plot(0.5:.5:24*monthdays(monthno),netpvdemand);
%     plot(0.5:.5:24*monthdays(monthno),dcload);
%     plot(0.5:.5:24*monthdays(monthno),pv);
%     plot(0.5:.5:24*monthdays(monthno),Battlevel,'LineWidth',2);
%     plot(0.5:.5:24*monthdays(monthno),Es_max,'r');
%     title({'PV System with Optimized Battery Dispatch, Month;', monthno});
%     legend({'bess .. >0 is discharge', 'demand-(pv+bess)', 'demand-pv',...
%         'demand', 'pv'}, 'FontSize', 8, 'Location', 'EastOutside'); %'Battlevel'
%     xlabel('Hours');
%     ylabel('Power kW');

mohours = monthdays*24;
hrperiod = mohours(startmo:endmo);
cumhours = cumsum(hrperiod);
tothours = sum(hrperiod);

figure(1)
plot(0.5:0.5:24*cumdays,bess,'b')
hold on
plot(0.5:0.5:24*cumdays,netdemand,'LineWidth',3);
plot(0.5:.5:24*cumdays,netpvdemand,'g');
plot(0.5:.5:24*cumdays,dcload,'m');
plot(0.5:.5:24*cumdays,pv,'c');
plot(0.5:.5:24*cumdays,Battlevel)%'LineWidth',1);
plot(0.5:.5:24*cumdays,Es_max,'r');
plot(0.5:.5:24*cumdays,Es_min,'r');
for i = startmo:endmo
    plot(cumhours(i),-15:1:Es_max,'k.','LineWidth',0.01);
end
%set(gca,'XTick',0:250:tothours);
str = sprintf('PV System with Optimized Battery Dispatch, Start Month = %2.0f , and End Month = %2.0f',startmo,endmo);
title(str);
legend({'bess .. >0 is discharge', 'demand-(pv+bess)', 'demand-pv',...
    'demand', 'pv','Battlevel','Es max','Month Divider'}, 'FontSize', 8, 'Location', 'EastOutside');
xlabel('Hours');
ylabel('Power kW');



    
    