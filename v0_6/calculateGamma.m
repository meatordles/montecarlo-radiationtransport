% ============================================================================================
% cross-section of photoelectric effect, compton scattering, pair production
% ============================================================================================
% https://en.wikipedia.org/wiki/Gamma_ray_cross_section
function [photo, compton, pairpro, sigma, mu] = calculateGamma(E_space, materialStruct, epsilon)
    rho = materialStruct.density;
    Z = materialStruct.Z;

    if rho == 0 || Z == 0
        photo = zeros(size(E_space));
        compton = zeros(size(E_space));
        pairpro = zeros(size(E_space));
        sigma = zeros(size(E_space));
        mu = zeros(size(E_space));
        return;
    end

    r_e = 2.82e-13; % classical electron radius [cm]
    finestructure = 1/137.036; % fine structure constant
    % m_e = 0.511; % rest mass energy of electron [MeV]
    % c = 29979245800; % duh [cm/s]
    N_A = 6.02214076e23; % duh [1/mol]
    A_eff = Z * 2.1; % rough approximation of atomic mass

    % photoelectric effect cross-section
        photo = (16 * sqrt(2) * pi / 3) * (r_e^2) * (finestructure^4) * (Z^5) ./ (epsilon .^ 3.5); 

    % Compton scattering cross-section
        % Thomson cross-section
        % thomson = (8 * pi / 3) * (r_e ^ 2); 
        % Klein-Nishina total cross section per target electron * Z
        compton = Z * (2 * pi * (r_e^2)) ...
            .* (...
                ((1 + epsilon) ./ (epsilon .^ 3)) ...
                    .* (...
                        (((2 .* epsilon) .* (1 + epsilon)) ./ (1 + (2 .* epsilon))) ...
                        - log(1 + (2 .* epsilon))...
                    ) ...
                + (log(1 + (2 .* epsilon)) ./ (2 .* epsilon)) ...
                - (1 + (3 .* epsilon)) ./ ((1 + (2 .* epsilon)) .^ 2) ...
            );
        % so confusing to look at

    % pair production cross-section
        % Maximon equation for epsilon < 4
        rho_pair = (2 .* epsilon - 4) ./ (2 + epsilon + 2 .* sqrt(2 .* epsilon));
        pairpro = (Z^2) * finestructure * (r_e^2) * (2/3) * pi ...
            .* ((((epsilon - 2) ./ epsilon)).^3) ...
            .* (1 + 0.5 .* rho_pair ...
                + (23/40) .* (rho_pair.^2) ...
                + (11/60) .* (rho_pair.^3) ...
                + (29/960) .* (rho_pair.^4) ...
            );

        % enforce pair production energy threshold
        pairproThresholdEnergy = 1.022; % 2 * m_e, [MeV]
        for j = 1:length(E_space)
            if E_space(j) < pairproThresholdEnergy
                pairpro(j) = 0;
            end
        end
        % this doesn't actually work for some reason so the threshold is
        % enforced again in the main simulation loop

    % total interaction cross-section
    sigma = photo + compton + pairpro;

    % linear attenuation coefficient
    mu = rho * (N_A / A_eff) .* sigma;
end
