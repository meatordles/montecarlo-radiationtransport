% ============================================================================================
% simple Bethe formula per wikipedia
% ============================================================================================
function dEdx = calculateAlpha(E_space, materialStruct)
    rho = materialStruct.density;
    Z = materialStruct.Z;

    if rho == 0 || Z == 0
        dEdx = zeros(size(E_space));
        return;
    end
    
    A_eff = Z * 2.1; % rough approximation of atomic mass
    m_e = 0.511; % electron rest mass energy [MeV]
    m_alpha = 3727; % alpha rest mass [MeV/c^2]
    z_alpha = 2; % atominc number of alpha particle
    bethe_I = (10 * Z) * 1e-6; % mean excitation potential I [MeV]
    c = 29979245800; % duh [cm/s]
    N_A = 6.02214076e23; % duh [1/mol]
    M_u = 1 + 1.05e-9; % molar mass constant [g/mol]
    e = 1.602176634e-19; % elementary charge [C]
    eps_0 = 8.8541878188e-12; % vacuum permittivity [(C^2 * s^2 / kg * m^3)] 
    conversion_Jm2MeVcm = 6.241509e14; % J * m to MeV * cm

    % precalculate constants
    bethe_term1 = (4 * pi) / (m_e); 
    bethe_n = (N_A * Z * rho) / (A_eff * M_u);
    bethe_term2numerator = bethe_n * z_alpha^2; % it's just n * 4 but whatever
    bethe_term3 = ((((e^2) / (4 * pi * eps_0)) * conversion_Jm2MeVcm)^2);
    
    % vectorized (optimized?)
    v_alpha = sqrt((2 .* E_space) ./ m_alpha) .* c;
    beta = v_alpha ./c;
    betaSq = beta.^2;

    betaSq = max(betaSq, 1e-5); % if betaSq(k) < 1e-5 then max() will choose 1e-5

    stoppingPower = bethe_term1 .* (bethe_term2numerator ./ betaSq) .* bethe_term3 .* ... 
        (log((2 .* m_e .* betaSq) ./ (bethe_I .* (1 - betaSq))) - betaSq);

    stoppingPower(stoppingPower > 10000 | stoppingPower < 0) = 10000;

    dEdx = stoppingPower;
end