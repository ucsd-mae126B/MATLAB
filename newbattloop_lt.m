clc;
load battinput 
battdata= battinput.battdata;

tic

timestep = 30;
readingsperday = 24*(60/timestep);
monthdays = [31 28 31 30 31 30 31 31 30 31 30 31];

    for monthnum=1:1;
        maxnow = 0;
        for daynum = 1:monthdays(monthnum);
            [dcload, pvdc, Ps, netdemand] = wewantthefunc( battdata(:,:,daynum,monthnum), maxnow, monthnum);        
            battoutput(monthnum,daynum).dcload = dcload;
            battoutput(monthnum,daynum).pvdc = pvdc;
            battoutput(monthnum,daynum).Ps = Ps;
            battoutput(monthnum,daynum).netdemand = netdemand;

            if max(netdemand) > maxnow
                maxnow = max(netdemand)
            end


        end
    end
    
save battoutput battoutput    

toc