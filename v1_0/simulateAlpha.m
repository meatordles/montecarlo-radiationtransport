function depositionMap = simulateAlpha(sampleEnergy, sampleX, sampleY, sampleTheta, LUT1, LUT2, gridSize, realLength, E_space, imgFinal, depositionMap)
    energy = sampleEnergy;
    posX = sampleX;
    posY = sampleY;
    theta = sampleTheta; 
    stepLength = 1;
              
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
                error('alpha particle lost negative energy!')
            end      

        if energyLoss > energy
            energyLoss = energy;
            energy = 0; % no negative energy
        else
            energy = energy - energyLoss;
        end

        % update deposition map
        if energyLoss ~= 0
            depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss;
        end
        
        % update position, ignore scattering
        posX = nextX;
        posY = nextY;                
    end 
end