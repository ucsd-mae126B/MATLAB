function [ Emonthmat ] = Eyear2month( Eyear, leapyrflag )



if leapyrflag == 1
    monthdays=[31 29 31 30 31 30 31 31 30 31 30 31]; %Leap-year day Schedule
else
    monthdays=[31 28 31 30 31 30 31 31 30 31 30 31]; %Regular-year day Schedule
end

yeardays = sum(monthdays);   %Number of days per year
samplesperyear = length(Eyear);  %Number of samples per year
samplesperday = samplesperyear/yeardays;     %Number of samples per day

Emonthmat = zeros(12,31,samplesperday); %Initialize output matrix
readcount = 1;

for mono=1:12;
    for dayno=1:monthdays(mono)
        for readno = 1: samplesperday
            Emonthmat(mono,dayno,readno)=Eyear(readcount);  
            readcount = readcount+1;
        end
    end
end



