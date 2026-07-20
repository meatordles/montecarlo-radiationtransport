% ============================================================================================
% compton scattering angle
% ============================================================================================

% https://physics.stackexchange.com/a/767193\
    % thank you stackexchange user369107 i love you
    % however i will change your symbol choices for comprehension and
    % convention
% we cannot (I don't want to) analytically manipulate the above functions 
% to find a direct formula for a scatter angle theta as a function of 
% incident photon energy
% however we can use numerical inverse transform sampling to numerically 
% generate random probable angles from the cumulative distribution function

function [scatterAngle] = comptonScatterAngle(epsilonSingle)
    % indefinite integral of Klein-Nishina with dΩ = sin(θ)dθdϕ
    I = @(theta) ...
        (-1 * (cos(theta)) ./ (epsilonSingle^2)) ...
        + ( ... 
            log(1 + (epsilonSingle .* (1 - cos(theta)))) ...
            .* ((1 ./ epsilonSingle) - (2 ./ (epsilonSingle .^ 2)) - (2 ./ (epsilonSingle .^ 3))) ...
        ) ...
        - (1 ...
            ./ (((2 .* epsilonSingle)) ...
                .* (1 + (epsilonSingle .* ((1 - cos(theta)))))^2 ...
            ) ...
        ) ...
        + ( ...
            ((-2 ./ (epsilonSingle .^ 2)) - (1 ./ (epsilonSingle .^ 3))) ...
            ./ (1 + (epsilonSingle .* (1 - cos(theta)))) ...
        );

    % uniform random variable (0, 1)
    U = rand();

    % bisection method to find theta where the CDF F(theta) = U
    boundL = 0;
    boundH = pi;

    % normalize CDF
    I_0 = I(0);
    I_pi = I(pi);
    I_I = I_pi - I_0; % a face!

    for k = 1:25
        midpoint = (boundL + boundH) / 2;
        Fsample = (I(midpoint) - I_0) / (I_I);
        
        if Fsample < U
            boundL = midpoint;
        elseif Fsample > U
            boundH = midpoint;
        end
    end

    scatterAngle = (boundL + boundH) / 2;
end