function [ Po, Ps, Es, Rs, Ro, netcost, varargout  ] = solaroptfun_lt(t, dt, Pi, Pl, Es_min, Es_max, Eo, Ps_min, Ps_max, Ro_min, Ro_max, Rs_min, Rs_max, Ps0, Rs0, sysDCrating, xg)

    nvars = 2;      %number of variables
    N = length(t);  %number of timesteps
    nicon = 8;  %number of inequality constraints
    
    if ~isempty(Ps0) && ~isempty(Rs0)
        neqcon = 3;  %number of equality constraints
    elseif ~isempty(Ps0) && isempty(Rs0)
        neqcon = 2;
    else
        neqcon = 1;
    end

    % allocate memory for linear system
    A = zeros(N*nicon, nvars*N);
    b = zeros(N*nicon, 1);
    Aeq = zeros(N*neqcon, nvars*N);
    beq = zeros(N*neqcon, 1);


    %fill up A and b
    %inequality constraint 1, Ps(1A)
    for m = 1:N   
        A(m,1:m) = -dt;
        b(m) = Es_max - Eo;
    end
    %inequality constraint 2, Ps(1B)
    for m = N+1:2*N
        A(m,1:m-N) = dt;
        b(m) = -Es_min + Eo;
    end
    %inequlaity constraint 3, Ps(3A)
    for m = 2*N+1:3*N 
        A(m, m-2*N) = 1;
        b(m) = Ps_max;
    end
    %inequlaity constraint 4, Ps(3B)
    for m = 3*N+1:4*N 
        A(m, m-3*N) = -1;
        b(m) = -Ps_min;
    end
    %inequality constraint 5, Ps(2B)
    for m = 4*N+1:5*N
        if m < 5*N
            A(m, m-4*N:m-4*N+1) = [-1, 1];
        else
            A(m, m-4*N-1:m-4*N) = [-1, 1];
        end
        b(m) = dt*Rs_max;
    end
    %inequality constraint 6, Ps(3B)
    for m = 5*N+1:6*N
        if m < 6*N
            A(m, m-5*N:m-5*N+1) = -1*[-1, 1];
        else
            A(m, m-5*N-1:m-5*N) = -1*[-1, 1];
        end
        b(m) = -dt*Rs_min;
    end
    %inequality constraint 7, Po(1A)
    for m = 6*N+1:7*N
        if m < 7*N
            A(m, (m-6*N:m-6*N+1)+N) = [-1, 1];
        else
            A(m, (m-6*N-1:m-6*N)+N) = [-1, 1];
        end
        b(m) = dt*Ro_max;
    end
    %inequality constraint 8, Po(1B)
    for m = 7*N+1:8*N
        if m < 8*N
            A(m, (m-7*N:m-7*N+1)+N) = -1*[-1, 1];
        else
            A(m, (m-7*N-1:m-7*N)+N) = -1*[-1, 1];
        end
        b(m) = -dt*Ro_min;
    end
    
    % fill up Aeq and beq
    % equality constraint 1
    for m = 1:N
        Aeq(m, m) = -1;
        Aeq(m, m+N) = 1;
        beq(m) = Pi(m);
    end
    
    if ~isempty(Ps0) && ~isempty(Rs0)
        for m = N+1:2*N
            Aeq(m, 1) = 1;
            beq(m) = Ps0;
        end

        for m = 2*N+1:3*N
            Aeq(m, 1:2) = [-1 1];
            beq(m) = dt*Rs0;
        end
    elseif ~isempty(Ps0) && isempty(Rs0)
        for m = N+1:2*N
            Aeq(m, 1) = 1;
            beq(m) = Ps0;
        end
    end

    ramps = firstdiff1(Pi, dt);
    xsugg = zeros(size(ramps));
    for ind1 = 1:length(ramps)-1
        if ramps(ind1) > Ro_max
            xsugg(ind1+1) = Ro_max*dt-ramps(ind1)*dt;
        elseif ramps(ind1) < Ro_min
            xsugg(ind1+1) = Ro_min*dt-ramps(ind1)*dt;
        end
        ramps = firstdiff1(Pi+xsugg, dt);
    end


    func = @(x)fdevpenalty_lt(x, Pi, Pl, Ps_min, Ps_max);  %##
   
    options = optimset('Algorithm', 'active-set', 'MaxFunEvals', 1000*2*length(t), 'MaxIter', 10000);
    [xout, netcost, exitflag] = fmincon(func, xg, A, b, Aeq, beq, [], [], [], options);
    varargout{1} = exitflag;

    Ps = xout(1:N);
    Po = xout(N+1:2*N);
    
    Es = [Eo; cumsum(-Ps(1:end-1))*dt + Eo];
    Rs = firstdiff1(Ps, dt);
    Ro = firstdiff1(Po, dt);
end