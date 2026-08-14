function [createdSecondary, secondaryEnergy, secondaryX, secondaryY, secondaryTheta, depositionMap, depositionMapPairpro] ...
    = simulateBeta(sampleType, sampleOrder, sampleEnergy, sampleX, sampleY, sampleTheta, LUT1, LUT2, gridSize, realLength, materialProps, E_space, imgFinal, depositionMap, depositionMapPairpro)

    energy = sampleEnergy;
    posX = sampleX;
    posY = sampleY;
    theta = sampleTheta; 
    stepLength = 1;
    m_e = 0.511;

    createdSecondary = 0;
    secondaryEnergy = 0;
    secondaryX = 0;
    secondaryY = 0;
    secondaryTheta = 0;

    while energy > 0              
        % simulation boundary check
        nextX = posX + stepLength * cos(theta);
        nextY = posY + stepLength * sin(theta);                
        if nextX < 1 || nextX > gridSize || nextY < 1 || nextY > gridSize
            break;
        end            

        % identify material
        currentMaterial = imgFinal(round(nextY), round(nextX)); 

        % energy loss
        [~, idx] = min(abs(E_space - energy));
        if currentMaterial == 1                    
            energyLoss = LUT1(idx) * realLength;
        elseif currentMaterial == 2
            energyLoss = LUT2(idx) * realLength;
        end        
            % test
            if energyLoss < 0
                error('beta particle lost negative energy')
            end                    
        if energyLoss > energy
            energyLoss = energy;
            energy = 0;
        else
            energy = energy - energyLoss;
        end

        % secondary Bremsstrahlung photons placeholder
        
        % update deposition map
        if energyLoss ~= 0 && sampleOrder == 1
            depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss; 
        elseif energyLoss ~= 0 && sampleOrder > 1
            depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss; 
            depositionMapPairpro(round(nextY), round(nextX)) ...
                = depositionMapPairpro(round(nextY), round(nextX)) ...
                + energyLoss;    
        end

        % random scattering angle based on Gaussian distribution
        % standard deviation using Highland approximation, omitting
        % the logarithm to avoid strange step size/number related behavior
        Z = materialProps(currentMaterial).Z;      
        beta_p = (energy * (energy + 2 * m_e)) / (energy + m_e);
        z = 1;
        X_0 = 1504 / Z; % radiation length using A = 2.1 * Z       
        sigma = (13.6 / beta_p) * z * sqrt(realLength / X_0);
        deltaTheta = normrnd(0, sigma);
        
        % update direction and position
        theta = theta + deltaTheta;       
        posX = nextX;
        posY = nextY;   
    end

    % positron annihilation
    if sampleType == 4
        createdSecondary = 2;
        secondaryEnergy = m_e;
        secondaryX = posX;
        secondaryY = posY;
        secondaryTheta = rand * pi;
    end
end