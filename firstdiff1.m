function dxdt = firstdiff1(x, dt)
    
    N = length(x);
    
    dxdt = zeros(N,1);
    for ind1 = 1:N-1
        dxdt(ind1) = (x(ind1+1)-x(ind1))/dt;
    end
    dxdt(N) = (x(N)-x(N-1))/dt;
        

end