% ============================================================================================
% Berger-Seltzer for electron stopping power
% ============================================================================================
% ICRU 37
function dEdx = calculateBetaLUTs(E_space, materialStruct)
    rho = materialStruct.density;
    Z = materialStruct.Z;

    if rho == 0 || Z == 0
        dEdx = zeros(size(E_space));
        return;
    end
    
    A_eff = Z * 2.1; % rough approximation of atomic mass
    m_e = 0.511; % electron rest mass energy [MeV]
    z_beta = -1; % beta charge
    bethe_I = (10 * Z) * 1e-6; % mean excitation potential I [MeV]
    % c = 29979245800; % duh [cm/s]
    N_A = 6.02214076e23; % duh [1/mol]
    M_u = 1 + 1.05e-9; % molar mass constant [g/mol]
    e = 1.602176634e-19; % elementary charge [C]
    eps_0 = 8.8541878188e-12; % vacuum permittivity [(C^2 * s^2 / kg * m^3)] 
    conversion_Jm2MeVcm = 6.241509e14; % J * m to MeV * cm

    % Berger-Seltzer per ICRU 37
    bethe_term1 = (2 * pi) / (m_e); % maximum energy loss is half its initial energy since the electron with more energy counts as the incident
    bethe_n = (N_A * Z * rho) / (A_eff * M_u);
    bethe_term2numerator = bethe_n * z_beta^2; % it's just n * 1 but whatever
    bethe_term3 = ((((e^2) / (4 * pi * eps_0)) * conversion_Jm2MeVcm)^2);

    % betas are relativistic so we cannot use classical kinematics like we did with alphas
    gamma = (E_space + m_e) ./ m_e;
    RbetaSq = 1 - (1 ./ gamma.^2);
    RbetaSq = max(RbetaSq, 1e-5);

    tau = E_space ./ m_e;
    F_tau = 1 - RbetaSq + ((tau.^2 ./ 8) - (2.*tau + 1) .* log(2)) ./ (tau + 1).^2;

    % collisional stopping power
    stoppingPower_coll = bethe_term1 .* (bethe_term2numerator ./ RbetaSq) .* bethe_term3 .* (log((tau.^2 .* (tau + 2)) ./ (2 * (bethe_I / m_e)^2)) + F_tau);
    % Bremsstrahlung losses
    ratio_rad_to_coll = (E_space .* Z) / 800;
    stoppingPower_rad = stoppingPower_coll .* ratio_rad_to_coll;

    stoppingPower = stoppingPower_coll + stoppingPower_rad;
    stoppingPower(stoppingPower > 10000 | stoppingPower < 0) = 10000;

    dEdx = stoppingPower;
end