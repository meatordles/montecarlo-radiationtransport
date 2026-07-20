% ====================================================================================================================================
% ====================================================================================================================================
%
% DESCRIPTION
%
% ====================================================================================================================================
% ====================================================================================================================================

% v0_5
% start: 2026 07 20, 11:34 EST
% completion: 2026 07 20, 18:08 EST

% goals:
    % graphics
        % dialog
        % figure
            % better color map to discern low values from background
            % data cursor to get exact value
    % organization
        % split functions into separate files
        % table of contents
        % indentation
        % more explanation comments

% ====================================================================================================================================
% ====================================================================================================================================
%
% TABLE OF CONTENTS
%
% ====================================================================================================================================
% ====================================================================================================================================
    
    % ============================================================================================================
    %
    % FUNCTIONS
    %
    % ============================================================================================================
    
        % ============================================================================================
        % Alpha functions
        % ============================================================================================
        %
        % calculateAlpha(E_space, materialStruct)
        
        % ============================================================================================
        % Beta functions
        % ============================================================================================
        %
        % calculateBeta(E_space, materialStruct)
        
        % ============================================================================================
        % Gamma functions
        % ============================================================================================
        %
        % calculateGamma(E_space, materialStruct, epsilon)
        % comptonScatterAngle(epsilonSingle)
        % pairproFraction(photonEnergy, Z)
        
        % ============================================================================================
        % Figure functions
        % ============================================================================================
        %
        % getPixelInfo(~, info)
    
    % ============================================================================================================
    %
    % SCRIPT
    %
    % ============================================================================================================
    
        % ============================================================================================
        % Setup
        % ============================================================================================
        % 
        % import and process 2D map
        % physical grid properties
        % set simulation parameters
    
        % ============================================================================================
        % Simulation
        % ============================================================================================
        % 
        % alpha cycle
        % beta cycle
        % gamma cycle 

        % ============================================================================================
        % Output Graphics
        % ============================================================================================
        % 
        % total energy deposition map
        % gamma interaction component energy deposition maps
        % dose map
        % miscellaneous figures

% ====================================================================================================================================
% ====================================================================================================================================
%
% SCRIPT
%
% ====================================================================================================================================
% ====================================================================================================================================

    
    % ============================================================================================================
    % Setup
    % ============================================================================================================
    % clear
    clear; 
    clc; 
    close all;
    
        % ============================================================================================
        % import & process 2D map
        % ============================================================================================
        % read file
        [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tiff', 'Image Files (*.png, *.jpg, *.jpeg, *.bmp, *.tiff)'});
        if isequal(file,0) 
            error('User canceled file selection'); 
        end
        imgRaw = imread(fullfile(path, file));
        
        % convert to Cartesian
        imgCart = flip(imgRaw, 1);
        
        % convert to grayscale
        if size(imgCart, 3) == 3
            imgGray = im2gray(imgCart);
        else
            imgGray = imgCart;
        end
        
        % resize to 1000x1000
        promptSize = {'Enter linear resolution of the simulation grid [px]'};
        dlgTitleSize = 'Size';
        defaultSize = {'1000'};
        answerSize = inputdlg(promptSize, dlgTitleSize, 1, defaultSize);
        gridSize = str2double(answerSize{1});
        imgResize = imresize(imgGray, [gridSize, gridSize]);
        
        % create regions
        level = graythresh(imgResize);
        imgDisplay = imbinarize(imgResize, level);
        imgFinal = imgDisplay + 1;
        numRegions = [1 2];
        
        % these are actually never used and i don't remember why i made them
        % % create directional gradient maps
        % [G_x, G_y] = imgradientxy(imgFinal, 'Sobel');
        % %G_y = -G_y; % invert y to match cartesian space
        % % get normal vectors
        % mag = hypot(G_x, G_y);
        % mag(mag == 0) = 1;
        % Nx = G_x ./ mag;
        % Ny = G_y ./ mag;
        % % create normal map
        % normalMap = atan(Ny ./ Nx);
        
        % ============================================================================================
        % physical grid properties
        % ============================================================================================
        % prompt to define actual size [cm]
        promptScale = {'Enter physical width of the simulation grid [cm]'};
        dlgTitleScale = 'Scale';
        defaultScale = {'10.0'};
        answerScale = inputdlg(promptScale, dlgTitleScale, 1, defaultScale);
        gridWidthCm = str2double(answerScale{1});

        % calculate scaling factor of physical results and simulation
        cmPerPixel = gridWidthCm / gridSize;
        
        % show binarized image
        figure(1);
        xRange = [0, gridSize * cmPerPixel];
        yRange = [0, gridSize * cmPerPixel];        
        imagesc(xRange, yRange, imgDisplay);
        colormap("gray")
        axis xy;
        axis tight;
        axis square;
        xlabel('cm');
        ylabel('cm');        
        title({'Region 1: Black', 'Region 2: White'});
        
        % prompt to input material names, densities, and Z
        materialProps = struct();
        for r = 1:length(numRegions)
            regionID = numRegions(r);
            promptMat = {sprintf('Enter material name for Region %d', regionID), ...
                sprintf('Enter density for Region %d [g/cm^3]', regionID), ...
                sprintf('Enter effective Z (Atomic Number) for Region %d', regionID)};
            dlgTitleMat = sprintf('Material Configuration: Region %d', regionID);
            defaultMat = {'water', '1.0', '7.4'}; 
            answerMat = inputdlg(promptMat, dlgTitleMat, 1, defaultMat);
            materialProps(regionID).name = answerMat{1};
            materialProps(regionID).density = str2double(answerMat{2});
            materialProps(regionID).Z = str2double(answerMat{3});
        end
        
        % close imgDisplay
        close(gcf);
    
        % ============================================================================================
        % set simulation parameters
        % ============================================================================================
        % prompt for particle type, energy, and sample count
        particleTypeText = "Particle type" + newline + "(1=Alpha, 2=Beta, 3=Gamma)";
        sampleCountText = "Sample count linear density [n/px]" + newline ...
            + "Recommended: 100 for alphas, 500 for betas, 1000 for gammas";
            %+ "This scales with the square of the simulation grid linear resolution!" + newline ...
            % alpha samples are super quick and show little noise without scattering
            % beta samples are slow but noise is not very detrimental
            % gammas samples are fast but very noisy and lack clarity undersampled
        promptParams = {particleTypeText, 'Particle energy [MeV]:', sampleCountText};
        dlgTitleParams = 'Particle Configuration';
        defaultParams = {'2', '2.0', '100'};
        answerParams = inputdlg(promptParams, dlgTitleParams, 1, defaultParams);
        particleType = str2double(answerParams{1});
        initialEnergy = str2double(answerParams{2});
        samplesPerPixel = str2double(answerParams{3});
        numSamples = samplesPerPixel * gridSize; % i said it scales with the square but i don't think that's actually necessary until we get to a custom activity source
    
    % ============================================================================================================
    % Simulate
    % ============================================================================================================        
    % constants
    c = 29979245800; % duh [cm/s]
    m_e = 0.511; % electron rest mass [MeV/c^2]

    % steps
    stepLength = 1; % step length per cycle in pixels
    realLength = stepLength * cmPerPixel;

    % create empty energy deposition map
    depositionMap = zeros(gridSize, gridSize);
    
    % progress bar
    % fun little thing i thought of while waiting for beta with n = 1e6
    progressBar = waitbar(0);
    
        % ============================================================================================
        % alpha cycle
        % ============================================================================================
        if particleType == 1
            % precalculate lookup-tables for energy loss for optimization
            E_space = linspace(0.01, initialEnergy, 10000); 
            LUT_Alpha1 = calculateAlpha(E_space, materialProps(1)); 
            LUT_Alpha2 = calculateAlpha(E_space, materialProps(2)); 

            % cycles
            for i = 1:numSamples
                % progress bar update
                progressPercent = round(100 * i/numSamples, 1);
                waitbar(i/numSamples, progressBar, sprintf('Sample %d out of %d\n\n%.1f%%', i, numSamples, progressPercent));
        
                % initial particle position, direction, and energy
                posX = 1;
                posY = randi(gridSize); % random spread on left end of image
                theta = 0; % straight right
                energy = initialEnergy;
                          
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
                        energyLoss = LUT_Alpha1(idx) * realLength;
                    elseif currentMaterial == 2
                        energyLoss = LUT_Alpha2(idx) * realLength;
                    end      
                        % test
                        if energyLoss < 0
                            error('alpha particle lost negative energy')
                        end            
                    if energyLoss > energy
                        energyLoss = energy;
                        energy = 0; % no negative energy
                    else
                        energy = energy - energyLoss;
                    end
        
                    % update deposition map
                    depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss;    
                    
                    % update position, ignore scattering
                    posX = nextX;
                    posY = nextY;                
                end % energy
            end % samples
    
        % ============================================================================================
        % beta cycles
        % ============================================================================================
        elseif particleType == 2
            % precalculate
            E_space = linspace(0.01, initialEnergy, 10000); 
            LUT_Beta1 = calculateBeta(E_space, materialProps(1)); 
            LUT_Beta2 = calculateBeta(E_space, materialProps(2));
        
            % cycles
            for i = 1:numSamples
                % progress bar update
                progressPercent = round(100 * i/numSamples, 1);
                waitbar(i/numSamples, progressBar, sprintf('Sample %d out of %d\n%.1f%%', i, numSamples, progressPercent));
        
                % initial particle position, direction, and energy
                posX = 1;
                posY = randi(gridSize);
                theta = 0;
                energy = initialEnergy;
        
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
                        energyLoss = LUT_Beta1(idx) * realLength;
                    elseif currentMaterial == 2
                        energyLoss = LUT_Beta2(idx) * realLength;
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
                    depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss;    
        
                    % random scattering angle based on Gaussian distribution
                    % standard deviation using Highland approximation, omitting
                    % the logarithm to avoid strange step size/number related behavior
                    Z = materialProps(currentMaterial).Z;
                    rho = materialProps(currentMaterial).density;            
                    beta_p = (energy * (energy + 2 * m_e)) / (energy + m_e);
                    z = 1;
                    X_0 = 1504 / Z; % radiation length using A = 2.1 * Z       
                    sigma = (13.6 / beta_p) * z * sqrt(realLength / X_0);
                    deltaTheta = normrnd(0, sigma);
                    
                    % update direction and position
                    theta = theta + deltaTheta;       
                    posX = nextX;
                    posY = nextY;   
                end % energy
            end % samples
                
        % ============================================================================================
        % gamma cycles
        % ============================================================================================
        elseif particleType == 3
            % more maps for fun
            depositionMapPhotoelectric = zeros(gridSize, gridSize);
            depositionMapCompton = zeros(gridSize, gridSize);
            depositionMapPairpro = zeros(gridSize, gridSize);
        
            % precalculate
            E_space = linspace(0.01, initialEnergy, 10000); 
            epsilon = E_space ./ m_e;

            [LUT_GammaPhoto1, ...
                LUT_GammaCompton1, ...
                LUT_GammaPairpro1, ...
                LUT_GammaSigma1, ...
                LUT_GammaMu1] ...
                = calculateGamma(E_space, materialProps(1), epsilon); 
        
            [LUT_GammaPhoto2, ...
                LUT_GammaCompton2, ...
                LUT_GammaPairpro2, ...
                LUT_GammaSigma2, ...
                LUT_GammaMu2] ...
                = calculateGamma(E_space, materialProps(2), epsilon); 
        
            % precalculate for pair production secondary particles
            if initialEnergy > 1.022
                secondaryBetaE_space = linspace(0.01, initialEnergy - 1.022, 10000);
                LUT_Beta1 = calculateBeta(secondaryBetaE_space, materialProps(1)); 
                LUT_Beta2 = calculateBeta(secondaryBetaE_space, materialProps(2));
            end
        
            % cycles
            for i = 1:numSamples
                % progress bar update
                progressPercent = round(100 * i/numSamples, 1);
                waitbar(i/numSamples, progressBar, sprintf('Sample %d out of %d\n%.1f%%', i, numSamples, progressPercent));
        
                % initial position, direction, and energy
                posX = 1;
                posY = randi(gridSize);
                theta = 0;
                energy = initialEnergy;
        
                % cycles
                while energy > 0
                    % material check
                    % only load linear attentuation in case free path length is
                    % interrupted and material changes
                    startingMaterial = imgFinal(round(posY), round(posX));
                    [~, idx] = min(abs(E_space - energy));
                    if startingMaterial == 1
                        linearAttCoeff = LUT_GammaMu1(idx);
                    elseif startingMaterial == 2
                        linearAttCoeff = LUT_GammaMu2(idx);
                    end             

                    % find free path length
                    freePathLength = -log(1 - rand()) / linearAttCoeff;
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
                        sigmaPhoto = LUT_GammaPhoto1(idx);
                        sigmaCompton = LUT_GammaCompton1(idx);
                        sigmaPairpro = LUT_GammaPairpro1(idx);
                        sigmaTotal = LUT_GammaSigma1(idx);
                        rho = materialProps(1).density;
                        Z = materialProps(1).Z;
                    elseif startingMaterial == 2
                        sigmaPhoto = LUT_GammaPhoto2(idx);
                        sigmaCompton = LUT_GammaCompton2(idx);
                        sigmaPairpro = LUT_GammaPairpro2(idx);
                        sigmaTotal = LUT_GammaSigma2(idx);
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
                            electronAngle = theta + electronDeflection;
                            positronAngle = theta - positronDeflection;
                        elseif deflectionChoice == 1
                            electronAngle = theta - electronDeflection;
                            positronAngle = theta + positronDeflection;
                        end
        
                        % positron annihilation
                        [~, idxPositron] = min(abs(secondaryBetaE_space - positronKenergy));
                        % calculate positron range based on material
                        % does not account for material boundaries
                        if startingMaterial == 1
                            positronRange = positronKenergy / (LUT_Beta1(idxPositron));
                        elseif startingMaterial == 2
                            positronRange = positronKenergy / (LUT_Beta1(idxPositron));
                        end
                        % find annihilation position
                        positronAnnihilationX = nextX + positronRange * cos(positronAngle);
                        positronAnnihilationY = nextY + positronRange * sin(positronAngle);
                        % annihilate and update deposition maps if within simulation boundaries
                        if positronAnnihilationX >= 0.5 && positronAnnihilationX < gridSize ...
                                && positronAnnihilationY >= 0.5 && positronAnnihilationY < gridSize
                            depositionMapPairpro(round(positronAnnihilationY), round(positronAnnihilationX)) ... 
                                = depositionMapPairpro(round(positronAnnihilationY), round(positronAnnihilationX)) ...
                                + positronEnergy;
                            depositionMap(round(positronAnnihilationY), round(positronAnnihilationX)) ...
                                = depositionMap(round(positronAnnihilationY), round(positronAnnihilationX)) ...
                                + positronEnergy;
                        end
                           
                        % electron scattering
                        % spawn electron
                        electronX = nextX;
                        electronY = nextY;
                        % duplicate of beta cycles
                        while electronKenergy > 0
                            % simulation boundary check
                            nextElectronX = electronX + stepLength * cos(electronAngle);
                            nextElectronY = electronY + stepLength * sin(electronAngle);               
                            if nextElectronX < 1 || nextElectronX > gridSize ...
                                    || nextElectronY < 1 || nextElectronY > gridSize
                                break;
                            end          
                
                            % material check
                            currentMaterial = imgFinal(round(nextElectronY), round(nextElectronX)); 

                            % energy loss
                            [~, idxElectron] = min(abs(secondaryBetaE_space - electronKenergy));
                            if currentMaterial == 1                    
                                electronEnergyLoss = LUT_Beta1(idxElectron) * realLength;
                            elseif currentMaterial == 2
                                electronEnergyLoss = LUT_Beta2(idxElectron) * realLength;
                            end                                        
                                if electronEnergyLoss < 0
                                    error('secondary electron lost negative energy')
                                end                            
                            if electronEnergyLoss > electronKenergy
                                electronEnergyLoss = electronKenergy;
                                electronKenergy = 0;
                            else
                                electronKenergy = electronKenergy - electronEnergyLoss;
                            end

                            % update deposition maps
                            depositionMapPairpro(round(nextElectronY), round(nextElectronX)) ...
                                = depositionMapPairpro(round(nextElectronY), round(nextElectronX)) ...
                                + electronEnergyLoss;    
                            depositionMap(round(nextElectronY), round(nextElectronX)) ...
                                = depositionMap(round(nextElectronY), round(nextElectronX)) ...
                                + electronEnergyLoss;
                            
                            % random scattering angle
                            secElectronZ = materialProps(currentMaterial).Z;
                            secElectronRho = materialProps(currentMaterial).density;            
                            beta_p = (electronKenergy * (electronKenergy + 2 * m_e)) / (electronKenergy + m_e);
                            z = 1;
                            X_0 = 1504 / Z;                 
                            sigma = (13.6 / beta_p) * z * sqrt(realLength / X_0);                            
                            deltaTheta = normrnd(0, sigma);                           
                
                            % update direction and position
                            electronAngle = electronAngle + deltaTheta;
                            electronX = nextElectronX;
                            electronY = nextElectronY;   
                        end
        
                        % delete photon
                        % products already accounted for energy deposition                        
                        energy = 0;
                        energyLoss = 0;
                    end % pair production
        
                    % update deposition map
                    depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss;

                    % update gamma position
                    posX = nextX;
                    posY = nextY;   
                end % energy
            end % cycles
        end % simulation
        
    % ============================================================================================================
    % Output Graphics
    % ============================================================================================================        
    % all results [MeV/n] [Gy/n] need to be multiplied by:
    % particles per decay [n/decay], activity [Bq] [decay/s], and time [s]
    % to obtained derived quantities [MeV] [Gy]
    close(progressBar);
    
    % select color scale
    % this is no longer entirely necessary since the datacursor allows direct
    % reading of the pixel value instead of referencing the colorbar but it
    % looks cool so it's very important
    promptColorScale = "Select color scale" + newline + "Recommended: turbo for clarity, hot for vibrant visuals";
    dlgTitleColorScale = 'Color Scale';
    defaultColorScale = {'turbo'};
    answerColorScale = inputdlg(promptColorScale, dlgTitleColorScale, 1, defaultColorScale);
    colorScale = answerColorScale{1};
    
    % global subtitle setup
    if particleType == 1
        particleName = 'alpha';
    elseif particleType == 2
        particleName = 'beta';
    elseif particleType == 3
        particleName = 'gamma';
    end
    subtitleBlock = {['initial ', particleName, ' energy: ', num2str(initialEnergy), ' MeV'], ...
        ['samples run: ', num2str(numSamples)], ...
        ['target materials: ', materialProps(1).name, ' (density ', num2str(materialProps(1).density), ' [g/cm^3], Z = ', num2str(materialProps(1).Z), '), ', ...
        materialProps(2).name ' (density ', num2str(materialProps(2).density), ' [g/cm^3], Z = ', num2str(materialProps(2).Z), ')']};
    
        % ============================================================================================
        % total energy deposition map
        % ============================================================================================
        if particleType == 3
            figure(Name = "Cumulative Deposition", NumberTitle="off");
        else
            figure(Name = "Deposition", NumberTitle="off");
        end
        % scale to physical quantity
        scaleFactor = 1 / numSamples;
        depositionMapScaled = depositionMap * scaleFactor;
        % display axes in [cm] instead of [px]
        imagesc(xRange, yRange, depositionMapScaled);
        xlabel('cm');
        ylabel('cm');
        axis xy; 
        axis tight;
        axis square;
        % color
        colormap(gca, colorScale);
        colorbar;
        grid on;
        % data cursor 
        dcDeposition = datacursormode;
        dcDeposition.Enable = "on";
        dcDeposition.DisplayStyle = "datatip";
        dcDeposition.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
        % quad plot setup
        figCumulativeDeposition = gca;
        if particleType == 3
            figQuadDeposition = figure(Name = "Cumulative and Component Depositions", NumberTitle = "off");
            figCumulativeDepositionCopy = copyobj(figCumulativeDeposition, figQuadDeposition);
            figure(1);
            title('Cumulative Energy Deposition per Particle [MeV/n]');
        else
            title('Energy Deposition per Particle [MeV/n]');
        end
        % subtitle
        subtitle(subtitleBlock);

        % ============================================================================================
        % gamma interaction component energy deposition maps
        % ============================================================================================  
        if particleType == 3
            % photoelectric component
            figure(Name = "Photoelectric Interaction Deposition", NumberTitle = "off");
            % scale to physical quantity
            depositionMapPhotoelectricScaled = depositionMapPhotoelectric * scaleFactor;
            % plot
            imagesc(xRange, yRange, depositionMapPhotoelectricScaled);    
            xlabel('cm');
            ylabel('cm');
            axis xy; 
            axis tight;
            axis square;
            colormap(gca, colorScale);
            colorbar;
            grid on;
            % copy obj for quad plot
            figPhotoelectricDeposition = gca;
            figPhotoelectricDepositionCopy = copyobj(figPhotoelectricDeposition, figQuadDeposition);
            title('Photoelectric Interactions');
            % titles for individual plot
            figure(3);
            title('Deposition per Particle from Photoelectric Interactions [MeV/n]');
            subtitle(subtitleBlock);
            % data cursor
            dcPhotoelectric = datacursormode;
            dcPhotoelectric.Enable = "on";
            dcPhotoelectric.DisplayStyle = "datatip";
            dcPhotoelectric.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
        
            % Compton component
            figure(Name = "Compton Scattering Deposition", NumberTitle = "off");
            % scale to physical quantity
            depositionMapComptonScaled = depositionMapCompton * scaleFactor;
            % plot
            imagesc(xRange, yRange, depositionMapComptonScaled);    
            xlabel('cm');
            ylabel('cm');    
            axis xy; 
            axis tight;
            axis square;
            colormap(gca, colorScale);
            colorbar;
            grid on;
            % copy obj for quad plot
            figComptonDeposition = gca;
            figComptonDepositionCopy = copyobj(figComptonDeposition, figQuadDeposition);
            title('Compton Scattering');
            % titles for individual plot
            figure(4);
            title('Deposition per Particle from Compton Scattering [MeV/n]');
            subtitle(subtitleBlock);
            % data cursor
            dcCompton = datacursormode;
            dcCompton.Enable = "on";
            dcCompton.DisplayStyle = "datatip";
            dcCompton.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
        
            % pair production component
            figure(Name = "Pair Production Deposition", NumberTitle = "off");
            % scale to physical quantity
            depositionMapPairproScaled = depositionMapPairpro * scaleFactor;
            % plot
            imagesc(xRange, yRange, depositionMapPairproScaled);
            xlabel('cm');
            ylabel('cm');
            axis xy; 
            axis tight;
            axis square;
            colormap(gca, colorScale);
            colorbar;
            grid on;
            % copy obj for quad plot
            figPairproDeposition = gca;
            figPairproDepositionCopy = copyobj(figPairproDeposition, figQuadDeposition);
            title('Pair Production Events');
            % titles for individual plot
            figure(5);
            title('Deposition per Particle from Pair Production Events [MeV/n]');
            subtitle(subtitleBlock);
            % data cursor
            dcPairpro = datacursormode;
            dcPairpro.Enable = "on";
            dcPairpro.DisplayStyle = "datatip";
            dcPairpro.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
        
            % QUADRUPLE PLOT!
            figure(2);
            % plot
            subplot(2, 2, 1, figCumulativeDepositionCopy);
            hold on;
            colorbar;
            subplot(2, 2, 2, figPhotoelectricDepositionCopy);
            colorbar;
            subplot(2, 2, 3, figComptonDepositionCopy);
            colorbar;
            subplot(2, 2, 4, figPairproDepositionCopy);
            colorbar;
            % titles
            sgtitle({"Energy Deposition per Particle [MeV/n]", ...
                ['initial ', particleName, ' energy: ', num2str(initialEnergy), ' MeV'], ...
                ['samples run: ', num2str(numSamples)], ...
                ['target materials: ', materialProps(1).name, ' (density ', num2str(materialProps(1).density), ' [g/cm^3], Z = ', num2str(materialProps(1).Z), '), ', ...
                materialProps(2).name ' (density ', num2str(materialProps(2).density), ' [g/cm^3], Z = ', num2str(materialProps(2).Z), ')']});
            % data cursor
            dcCumDeposition = datacursormode;
            dcCumDeposition.Enable = "on";
            dcCumDeposition.DisplayStyle = "datatip";
            dcCumDeposition.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); datacursormode on;
        end
    
        % ============================================================================================
        % dose map
        % ============================================================================================
        figure(Name = "Dose", NumberTitle = "off");
        % calculate dose
        densityMap1 = (imgFinal == 1) * materialProps(1).density;
        densityMap2 = (imgFinal == 2) * materialProps(2).density;
        massMap = (densityMap1 + densityMap2) * (cmPerPixel^3) / 1000; % g/cm3 * cm3 * kg / 1000 g = kg / 1000
        doseMap = zeros(size(depositionMapScaled));
        validPixels = massMap > 0; % avoid division by zero
        doseMap(validPixels) = (depositionMapScaled(validPixels) * 1.602e-13) ./ massMap(validPixels);
        % plot
        imagesc(xRange, yRange, doseMap);
        xlabel('cm');
        ylabel('cm');
        axis xy; 
        axis tight;
        axis square;
        colormap(gca, colorScale);
        colorbar;
        grid on;
        title('Dose per Particle [Gy/n]');
        subtitle(subtitleBlock);
        % data cursor
        dcDose = datacursormode;
        dcDose.Enable = "on";
        dcDose.DisplayStyle = "datatip";
        dcDose.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 

        % ============================================================================================
        % miscellaneous figures
        % ============================================================================================
        % material map
        figure(Name = "Material Regions", NumberTitle = "off");
        imagesc(xRange, yRange, imgDisplay);
        colormap("gray")
        axis xy;
        axis tight;
        axis square;
        xlabel('cm');
        ylabel('cm');        
        title('Material Regions');
        subtitle({['Black: ', materialProps(1).name, ' (density ', num2str(materialProps(1).density), ' [g/cm^3], Z = ', num2str(materialProps(1).Z), ')'], ...
            ['White: ', materialProps(2).name, ' (density ', num2str(materialProps(2).density), ' [g/cm^3], Z = ', num2str(materialProps(2).Z), ')']})
            % not currently needed but perhaps with more materials it will be
            % datacursor
            dcMaterial = datacursormode;
            dcMaterial.Enable = "on";
            dcMaterial.DisplayStyle = "datatip";
            dcMaterial.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
        
        % imported image
        figure(Name = "Imported Image", NumberTitle = "off");
        imshow(imgCart);
        axis xy;
        axis tight;
        axis square;