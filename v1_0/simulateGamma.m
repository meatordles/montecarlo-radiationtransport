function [pairproduced, electronEnergy, positronEnergy, secondaryX, secondaryY, electronTheta, positronTheta, ...
            depositionMap, depositionMapPhotoelectric, depositionMapCompton] ...
        = simulateGamma(sampleEnergy, sampleX, sampleY, sampleTheta, ...
                LUT_Photo1, LUT_Compton1, LUT_Pairpro1, LUT_Sigma1, LUT_Mu1, ...
                LUT_Photo2, LUT_Compton2, LUT_Pairpro2, LUT_Sigma2, LUT_Mu2, ...
                gridSize, cmPerPixel, materialProps, E_space, epsilon, imgFinal, depositionMap, depositionMapPhotoelectric, depositionMapCompton)

    energy = sampleEnergy;
    posX = sampleX;
    posY = sampleY;
    theta = sampleTheta; 
    stepLength = 1;
    m_e = 0.511;

    pairproduced = false;
    electronEnergy = 0;
    positronEnergy = 0;
    secondaryX = 0;
    secondaryY = 0;
    electronTheta = 0;
    positronTheta = 0;

    while energy > 0
        % material check
        % only load linear attentuation in case free path length is
        % interrupted and material changes
        startingMaterial = imgFinal(round(posY), round(posX));
        [~, idx] = min(abs(E_space - energy));
        if startingMaterial == 1
            linearAttCoeff = LUT_Mu1(idx);
        elseif startingMaterial == 2
            linearAttCoeff = LUT_Mu2(idx);
        end             
        
        % find free path length
        if materialProps(startingMaterial).density == 0 || materialProps(startingMaterial).Z == 0
            freePathLength = gridSize;
        else
            freePathLength = -log(1 - rand()) / linearAttCoeff;
        end
        freePathPixels = freePathLength / cmPerPixel;            
        
        % step along free path and identify boundaries
        checkNeedsCulling = false;
        checkCrossedBoundary = false;
        traveledPixels = 0;
        while traveledPixels < freePathPixels
            nextX = posX + stepLength * cos(theta);
            nextY = posY + stepLength * sin(theta);
            % if gamma left simulation
            if nextX < 1 || nextX > gridSize || nextY < 1 || nextY > gridSize
                checkNeedsCulling = true;
                break;
            end                            
            % if gamma entered new material
            currentMaterial = imgFinal(round(nextY), round(nextX));
            if currentMaterial ~= startingMaterial
                checkCrossedBoundary = true;
                break
            end
            % if gamma did not encounter a boundary
            % advance along free path
            posX = nextX;
            posY = nextY;
            traveledPixels = traveledPixels + stepLength;
        end
        
        % cull gamma if left simulation
        if checkNeedsCulling == true
            break % cull gamma
        end       
        
        if checkCrossedBoundary == true
            % advance gamma to boundary
            posX = nextX;
            posY = nextY;                
            continue % return to free path calculation
        end
        
        % could add refraction for lower energy gamma:
        % refractiveIndex1 = 1 + ((Z1 * finestructure) / c);
        % refractiveIndex2 = 1 + ((Z2 * finestructure) / c);
        % incidenceAngle = abs(normalMap(round(boundaryY), round(boundaryX) - theta);
        % refractionAngle = asin((refractiveIndex1/refractiveIndex2) * sin(incidenceAngle));
        % theta = normalMap(round(boundaryY), round(boundaryX) + refractionAngle 
        % but why?
        
        % load gamma cross sections and material properties
        if startingMaterial == 1
            sigmaPhoto = LUT_Photo1(idx);
            sigmaCompton = LUT_Compton1(idx);
            sigmaPairpro = LUT_Pairpro1(idx);
            sigmaTotal = LUT_Sigma1(idx);
            rho = materialProps(1).density;
            Z = materialProps(1).Z;
        elseif startingMaterial == 2
            sigmaPhoto = LUT_Photo2(idx);
            sigmaCompton = LUT_Compton2(idx);
            sigmaPairpro = LUT_Pairpro2(idx);
            sigmaTotal = LUT_Sigma2(idx);
            rho = materialProps(2).density;
            Z = materialProps(2).Z;
        end                            
        
        % backup pair production energy threshold
        if energy < 1.022
            sigmaPairpro = 0;
        end
        
        % choose random interaction 
        gammaInteraction = rand();                   
        % interaction probabilities
        threshPhoto = sigmaPhoto / sigmaTotal;
        threshCompton = threshPhoto + (sigmaCompton / sigmaTotal);
        threshPairpro = 1 - (sigmaPairpro / sigmaTotal);
        % only two thresholds needed but whatever
        
        % photoelectric interaction
        if gammaInteraction <= threshPhoto
            % deposit all energy
            energyLoss = energy;
            energy = 0;
        
            % update photoelectric component of deposition map
            depositionMapPhotoelectric(round(nextY), round(nextX)) ...
                = depositionMapPhotoelectric(round(nextY), round(nextX)) ...
                + energyLoss;
        
        % Compton scattering
        elseif gammaInteraction > threshPhoto && gammaInteraction <= threshCompton
            % calculate scatter angle and energy
            thisEpsilon = epsilon(idx);
            scatterAngle = comptonScatterAngle(thisEpsilon);
            scatterEnergy = energy / (1 + (thisEpsilon * (1 - cos(scatterAngle))));
        
                % test
                if scatterEnergy < 0
                    error('scatter energy negative')
                elseif scatterEnergy <= 0
                    error('scatter energy zero')
                end                  
           
            % energy loss
            energyLoss = energy - scatterEnergy;       
                % test
                if energyLoss < 0
                    error('gamma ray lost negative energy')
                end                              
            if energyLoss > energy
                energyLoss = energy;
                energy = 0;
            else
                energy = scatterEnergy;
            end              
            
            % update Compton component of deposition map
            depositionMapCompton(round(nextY), round(nextX)) ...
                = depositionMapCompton(round(nextY), round(nextX)) ...
                + energyLoss;
            
            % update gamma direction
            theta = theta + scatterAngle;
        
        % pair production            
        elseif gammaInteraction > threshCompton     
            % flag
            pairproduced = true;

            % product kinematics
            remainder = energy - 1.022;
            electronKenergy = pairproFraction(energy, Z) * remainder; % You are Kenough!
            positronKenergy = remainder - electronKenergy;
            electronEnergy = electronKenergy + m_e;
            positronEnergy = positronKenergy + m_e;
            pairproAngle = acos(1 - (2 * m_e^2)/(electronEnergy * positronEnergy)); % c^4 cancels with [MeV/c^2]^2
                % electronAngle + positronAngle = pairproAngle
                % sin(electronAngle) * electronKenergy = sin(positronAngle) * positronKenergy
            electronDeflection = atan2((positronKenergy * sin(pairproAngle)), ...
                (positronKenergy * cos(pairproAngle) + electronKenergy));
            positronDeflection = atan2((electronKenergy * sin(pairproAngle)), ...
                (electronKenergy * cos(pairproAngle) + positronKenergy));
            deflectionChoice = randi([0 1]);
            if deflectionChoice == 0
                electronTheta = theta + electronDeflection;
                positronTheta = theta - positronDeflection;
            elseif deflectionChoice == 1
                electronTheta = theta - electronDeflection;
                positronTheta = theta + positronDeflection;
            end
                    
            % output secondary lepton information
            secondaryX = nextX;
            secondaryY = nextY;
        
            % delete photon, products already accounted for energy deposition                        
            energy = 0;
            energyLoss = 0;
        end % pair production
        
        % update deposition map
        depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss;
        
        % update gamma position
        posX = nextX;
        posY = nextY;   
    end % energy
end