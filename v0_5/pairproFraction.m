% ============================================================================================
% pair production product energy fraction
% ============================================================================================

% again i'd like to use numerical inverse transform sampling to generate
% random probable fractions.

% Bethe-Heitler differential cross-section with the Coulomb correction
% http://labmaster.mi.infn.it/wwwasdoc.web.cern.ch/wwwasdoc/geant_html3/node199.html
% reconstructed from broken 31-year-old text into LaTex using Google Gemini:
    % $\frac{d\sigma(Z, E_\gamma, \epsilon)}{d\epsilon} = \alpha r_0^2 Z [Z + \xi(Z)] \left\{ \left[ \epsilon^2 + (1 - \epsilon)^2 \right] \left[ \Phi_1(\delta) - \frac{F(Z)}{2} \right] + \frac{2}{3} \epsilon(1 - \epsilon) \left[ \Phi_2(\delta) - \frac{F(Z)}{2} \right] \right\}$$
    % Kinematic limits
    % $$\epsilon_0 = \frac{m_e c^2}{E_\gamma} \le \epsilon \le 1 - \epsilon_0$$
    % Screening variable
    % $$\delta(\epsilon) = \frac{136}{Z^{1/3}} \frac{\epsilon_0}{\epsilon(1 - \epsilon)}$$
    % Empirical screening functions
    % For $\delta \le 1$:$$\Phi_1(\delta) = 20.867 - 3.242\delta + 0.625\delta^2$$
    % $$\Phi_2(\delta) = 20.209 - 1.930\delta - 0.086\delta^2$$
    % For $\delta > 1$:$$\Phi_1(\delta) = \Phi_2(\delta) = 21.12 - 4.184 \ln(\delta + 0.952)$$
    % Coulomb function
    % For $E_\gamma < 50 \text{ MeV}$:$$F(Z) = \frac{8}{3} \ln Z$$
    % For $E_\gamma \ge 50 \text{ MeV}$:$$F(Z) = \frac{8}{3} \ln Z + 8 f_c(Z)$
% https://arachnoid.com/latex/

% can integrate this with respect to epsilon to get a CDF
% unfortunately i don't know how to integrate that analytically and i have 
% my doubts as to if it's even possible
% use trapezoidal rule approximations instead

function [epsilonPairpro] = pairproFraction(photonEnergy, Z)
    m_e = 0.511; % do i need to say it
    r_e = 2.8179e-13;
    epsilonZero = m_e / photonEnergy;
    epsilon_space = linspace(epsilonZero, 1 - epsilonZero, 10000);
    
    % component functions and constraints
    finestructure = 1 / 137.036;
    a = (finestructure * Z)^2;    
    % vectorized screening 
    delta_space = (136 / Z^(1/3)) * epsilonZero ./ (epsilon_space .* (1 - epsilon_space));
    delta_low = (delta_space <= 1);
    delta_high = (delta_space > 1);
    phi_1 = zeros(size(epsilon_space));
    phi_2 = zeros(size(epsilon_space));
    phi_1(delta_low) = 20.867 - 3.242 * delta_space(delta_low) + 0.625 * delta_space(delta_low).^2;
    phi_2(delta_low) = 20.209 - 1.930 * delta_space(delta_low) - 0.086 * delta_space(delta_low).^2;
    phi_1(delta_high) = 21.12 - 4.184 * log(delta_space(delta_high) + 0.952);
    phi_2(delta_high) = phi_1(delta_high);
    % Coulomb correction
    coulombCorrection = a * (1/(1 + a) ...
        + 0.20206 ...
        - 0.0369 * a ...
        + 0.0083 * a^2 ...
        - 0.0020 * a^3);
    % Coulomb function
    if photonEnergy < 50
        coulombFunc = (8/3) * log(Z);
    elseif photonEnergy >= 50
        coulombFunc = (8/3) * log(Z) + 8 * coulombCorrection;
    end    
    % triplet production 
    xi = (log(1440 / Z^(2/3)) / log(183 / Z^(1/3)) - coulombCorrection);
        % i actually don't really know what this is
    
    % vectorized Bethe-Heitler differential cross-section
    C = finestructure * r_e^2 * Z * (Z + xi);
    dSigmadEpsilon_space = C * ( ...
            (epsilon_space.^2 + (1 - epsilon_space).^2) ...
            .* (phi_1 - coulombFunc / 2) ...
            + (2/3) * epsilon_space .* (1 - epsilon_space) ...
            .* (phi_2 - coulombFunc / 2) ...
        );

    % protect against negative floating point fluctuations
    dSigmadEpsilon_space = max(dSigmadEpsilon_space, 0);
    
    % trapezoidal rule integration
    I = cumtrapz(epsilon_space, dSigmadEpsilon_space);
    
    % normalize
    if I(end) == 0
        epsilonPairpro = 0.5; 
        return;
    end
    % if I(end) rounds to zero then the cross section should be so small
    % that the energy fractions are about symmetric, plus the remaining
    % energy should be negligible anyway
    CDF = I ./ I(end);
    
    % to avoid bugging the interp1() function
    CDF(1) = 0;
    CDF(end) = 1;
    [CDF_unique, unique_indices] = unique(CDF, 'stable');
    epsilon_space_unique = epsilon_space(unique_indices);
    
    % uniform random variable
    U = rand();
    epsilonPairpro = interp1(CDF_unique, epsilon_space_unique, U);
end