% v0_4
% start: 2026 07 19, 21:58 EST
% completed: 2026 07 20, 01:06 EST

% goals:
    % alpha
        % fix fixed posY range
    % gamma (most important)
        % add boundary check to fix pathing in low density materials
            % begin new free path length (memoryless property)
    % figure corrections
        % units
        % progress bar percent (useless but fun)

clear; 
clc; 
close all;

% ============================================================================================================
% import & process 2D map
% ============================================================================================================
% read file
[file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tiff', 'Image Files (*.png, *.jpg, *.jpeg, *.bmp, *.tiff)'});
if isequal(file,0) 
    error('User canceled file selection'); 
end
imgRaw = imread(fullfile(path, file));

% convert to Cartesian
imgRaw = flip(imgRaw, 1);

% convert to grayscale
if size(imgRaw, 3) == 3
    imgGray = im2gray(imgRaw);
else
    imgGray = imgRaw;
end

% resize to 1000x1000
promptSize = {'Enter linear resolution of the simulation grid [px]:'};
dlgTitleSize = 'Size';
defaultSize = {'1000'};
answerSize = inputdlg(promptSize, dlgTitleSize, 1, defaultSize);
gridSize = str2double(answerSize{1});
imgResize = imresize(imgGray, [gridSize, gridSize]);

% create regions
level = graythresh(imgResize);
imgDisplay = imbinarize(imgResize, level);
imgFinal = imgDisplay + 1;
%numRegions = unique(world);
    % not necessary for imbinarize() since there are only two
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

% prompt to define actual size [cm]
promptScale = {'Enter physical width of the simulation grid [cm]:'};
dlgTitleScale = 'Scale';
defaultScale = {'10.0'};
answerScale = inputdlg(promptScale, dlgTitleScale, 1, defaultScale);
gridWidthCm = str2double(answerScale{1});
cmPerPixel = gridWidthCm / gridSize;

% prompt to input material properties for each region
imshow(imgDisplay);
axis xy;
axis tight;
axis square;
title({'Region 1: Black', 'Region 2: White'});

materialProps = struct();
for r = 1:length(numRegions)
    regionID = numRegions(r);
    promptMat = {sprintf('Enter material name for Region %d:', regionID), ...
        sprintf('Enter density for Region %d [g/cm^3]:', regionID), ...
        sprintf('Enter effective Z (Atomic Number) for Region %d:', regionID)};
    dlgTitleMat = sprintf('Material Configuration: Region %d', regionID);
    defaultMat = {'1.0', '7.4'}; % water
    answerMat = inputdlg(promptMat, dlgTitleMat, 1, defaultMat);
    materialProps(regiodID).name = answerMat{1};
    materialProps(regionID).density = str2double(answerMat{2});
    materialProps(regionID).Z = str2double(answerMat{3});
end

% close imgDisplay
close(gcf);

% ============================================================================================================
% set particle parameters
% ============================================================================================================
% prompt to select particle type (alpha, beta, gamma)
% prompt to input particle energy [MeV]
% prompt to input sample count 
% calculate scaling factor of physical results and simulation
particleTypeText = "Particle type" + newline + "(1=Alpha, 2=Beta, 3=Gamma)";
sampleCountText = "Sample count linear density [n/px]" + newline ...
    + "This scales with the square of the simulation grid linear resolution!" ...
    + newline + "Recommended: 100 for alphas, 500 for betas, 1000 for gammas";
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
% simulate
% ============================================================================================================
stepLength = 1; % step length per cycle in pixels
realLength = stepLength * cmPerPixel;
depositionMap = zeros(gridSize, gridSize);

c = 29979245800; % duh [cm/s]
m_e = 0.511; % electron rest mass [MeV/c^2]

% fun little thing i thought of while waiting for beta with n = 1e6
progressBar = waitbar(0);

% ============================================================================================
% alpha
% ============================================================================================
if particleType == 1
    % calculate lookup-tables for energy loss for optimization
    E_space = linspace(0.01, initialEnergy, 10000); 
    LUT_Alpha1 = calculateAlpha(E_space, materialProps(1)); 
    LUT_Alpha2 = calculateAlpha(E_space, materialProps(2)); 

    for i = 1:numSamples
        progressPercent = round(100 * i/numSamples, 1);
        waitbar(i/numSamples, progressBar, sprintf('Sample %d out of %d\n%.1f%%', i, numSamples, progressPercent));

        posX = 1;
        posY = randi(gridSize); % random spread on left end of image
        theta = 0; % straight right
        energy = initialEnergy;
                  
        while energy > 0
            % update position
            nextX = posX + stepLength * cos(theta);
            nextY = posY + stepLength * sin(theta);
            % simulation boundary check
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

            % energy loss for real
            if energyLoss > energy
                energyLoss = energy;
                energy = 0; % no negative energy
            else
                energy = energy - energyLoss;
            end

            % update deposition map
            depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss;    
            % update position for real, ignore scattering
            posX = nextX;
            posY = nextY;                
        end
    end

% ============================================================================================
% beta
% ============================================================================================
elseif particleType == 2
    E_space = linspace(0.01, initialEnergy, 10000); 
    LUT_Beta1 = calculateBeta(E_space, materialProps(1)); 
    LUT_Beta2 = calculateBeta(E_space, materialProps(2));

    for i = 1:numSamples
        progressPercent = round(100 * i/numSamples, 1);
        waitbar(i/numSamples, progressBar, sprintf('Sample %d out of %d\n%.1f%%', i, numSamples, progressPercent));

        posX = 1;
        posY = randi(gridSize);
        theta = 0;
        energy = initialEnergy;

        while energy > 0                
            nextX = posX + stepLength * cos(theta);
            nextY = posY + stepLength * sin(theta);                
            if nextX < 1 || nextX > gridSize || nextY < 1 || nextY > gridSize
                break;
            end            

            currentMaterial = imgFinal(round(nextY), round(nextX)); 

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

            % could do secondary Bremsstrahlung gammas and secondary pair
            % production betas and tertiary gammas and so on, but that 
            % should be saved for v2 with a graphical interface and better 
            % organized functions

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
            theta = theta + deltaTheta;

            depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss;    
            posX = nextX;
            posY = nextY;   
        end
    end
        
% ============================================================================================
% gamma
% ============================================================================================
elseif particleType == 3
    % more maps for fun
    depositionMapPhotoelectric = zeros(gridSize, gridSize);
    depositionMapCompton = zeros(gridSize, gridSize);
    depositionMapPairpro = zeros(gridSize, gridSize);

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

    % for secondary particles
    if initialEnergy > 1.022
        secondaryBetaE_space = linspace(0.01, initialEnergy - 1.022, 10000);
        LUT_Beta1 = calculateBeta(secondaryBetaE_space, materialProps(1)); 
        LUT_Beta2 = calculateBeta(secondaryBetaE_space, materialProps(2));
    end

    % main loop
    for i = 1:numSamples
        progressPercent = round(100 * i/numSamples, 1);
        waitbar(i/numSamples, progressBar, sprintf('Sample %d out of %d\n%.1f%%', i, numSamples, progressPercent));

        posX = 1;
        posY = randi(gridSize);
        theta = 0;
        energy = initialEnergy;

        while energy > 0
            % only load linear attentuation in case free path length is
            % interrupted and material changes
            startingMaterial = imgFinal(round(posY), round(posX));
            [~, idx] = min(abs(E_space - energy));
            if startingMaterial == 1
                linearAttCoeff = LUT_GammaMu1(idx);
            elseif startingMaterial == 2
                linearAttCoeff = LUT_GammaMu2(idx);
            end             
            freePathLength = -log(1 - rand()) / linearAttCoeff;
            freePathPixels = freePathLength / cmPerPixel;            

            % advance along free path
            checkNeedsCulling = false;
            checkCrossedBoundary = false;
            traveledPixels = 0;
            while traveledPixels < freePathPixels
                nextX = posX + stepLength * cos(theta);
                nextY = posY + stepLength * sin(theta);
                % if left simulation
                if nextX < 1 || nextX > gridSize || nextY < 1 || nextY > gridSize
                    checkNeedsCulling = true;
                    break;
                end                            
                % if entered new material
                currentMaterial = imgFinal(round(nextY), round(nextX));
                if currentMaterial ~= startingMaterial
                    checkCrossedBoundary = true;
                    break
                end
                % if didn't leave simulation or enter new material
                posX = nextX;
                posY = nextY;
                traveledPixels = traveledPixels + stepLength;
            end
            
            if checkNeedsCulling == true
                break; % cull ray
            end       
            if checkCrossedBoundary == true
                posX = nextX;
                posY = nextY;                
                continue
            end

            % could add refraction for lower energy gamma:
            % refractiveIndex1 = 1 + ((Z1 * finestructure) / c);
            % refractiveIndex2 = 1 + ((Z2 * finestructure) / c);
            % incidenceAngle = abs(normalMap(round(boundaryY), round(boundaryX) - theta);
            % refractionAngle = asin((refractiveIndex1/refractiveIndex2) * sin(incidenceAngle));
            % theta = normalMap(round(boundaryY), round(boundaryX) + refractionAngle 
            % but why?

            % now we can load everything else
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
            
            % choose interaction
            gammaInteraction = rand();
            % pair production threshold to account for precision errors
            if energy < 1.022
                sigmaPairpro = 0;
            end
            % interaction probabilities
            threshPhoto = sigmaPhoto / sigmaTotal;
            threshCompton = threshPhoto + (sigmaCompton / sigmaTotal);
            threshPairpro = 1 - (sigmaPairpro / sigmaTotal);
            % I only need two thresholds since it's just dividing 
            % total probability 1 into three sections, but whatever

            % photoelectric interaction
            if gammaInteraction <= threshPhoto
                energyLoss = energy;
                energy = 0;

                % update photoelectric map
                depositionMapPhotoelectric(round(nextY), round(nextX)) ...
                    = depositionMapPhotoelectric(round(nextY), round(nextX)) ...
                    + energyLoss;

            % Compton scattering
            elseif gammaInteraction > threshPhoto && gammaInteraction <= threshCompton
                thisEpsilon = epsilon(idx);
                scatterAngle = comptonScatterAngle(thisEpsilon);
                theta = theta + scatterAngle;
                scatterEnergy = energy / (1 + (thisEpsilon * (1 - cos(scatterAngle))));

                    % test
                    if scatterEnergy < 0
                        error('scatter energy negative')
                    elseif scatterEnergy <= 0
                        error('scatter energy zero')
                    end                  
               
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
                
                % update Compton map
                depositionMapCompton(round(nextY), round(nextX)) ...
                    = depositionMapCompton(round(nextY), round(nextX)) ...
                    + energyLoss;
            
            % pair production            
            elseif gammaInteraction > threshCompton
                % i could just have all energy deposited immediately with
                % no secondary particles but that's no fun
                % energyLoss = energy;
                % energy = 0;
                % 
                % % update photoelectric map
                % doseMapPhotoelectric(round(nextY), round(nextX)) ...
                %     = doseMapPhotoelectric(round(nextY), round(nextX)) ...
                %     + energyLoss;

                % secondary betas
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
                if startingMaterial == 1
                    positronRange = positronKenergy / (LUT_Beta1(idxPositron));
                elseif startingMaterial == 2
                    positronRange = positronKenergy / (LUT_Beta1(idxPositron));
                end
                positronAnnihilationX = nextX + positronRange * cos(positronAngle);
                positronAnnihilationY = nextY + positronRange * sin(positronAngle);
                if positronAnnihilationX >= 0.5 && positronAnnihilationX < gridSize && positronAnnihilationY >= 0.5 && positronAnnihilationY < gridSize
                    depositionMapPairpro(round(positronAnnihilationY), round(positronAnnihilationX)) = depositionMapPairpro(round(positronAnnihilationY), round(positronAnnihilationX)) + positronEnergy;
                    depositionMap(round(positronAnnihilationY), round(positronAnnihilationX)) = depositionMap(round(positronAnnihilationY), round(positronAnnihilationX)) + positronEnergy;
                end
                   
                % electron scattering
                electronX = nextX;
                electronY = nextY;
                while electronKenergy > 0                
                    nextElectronX = electronX + stepLength * cos(electronAngle);
                    nextElectronY = electronY + stepLength * sin(electronAngle);               
                    if nextElectronX < 1 || nextElectronX > gridSize || nextElectronY < 1 || nextElectronY > gridSize
                        break;
                    end          
        
                    currentMaterial = imgFinal(round(nextElectronY), round(nextElectronX)); 
        
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

                    secElectronZ = materialProps(currentMaterial).Z;
                    secElectronRho = materialProps(currentMaterial).density;            
                    beta_p = (electronKenergy * (electronKenergy + 2 * m_e)) / (electronKenergy + m_e);
                    z = 1;
                    X_0 = 1504 / Z; 
        
                    sigma = (13.6 / beta_p) * z * sqrt(realLength / X_0);
                    
                    deltaTheta = normrnd(0, sigma);
                    electronAngle = electronAngle + deltaTheta;
        
                    depositionMapPairpro(round(nextElectronY), round(nextElectronX)) = depositionMapPairpro(round(nextElectronY), round(nextElectronX)) + electronEnergyLoss;    
                    depositionMap(round(nextElectronY), round(nextElectronX)) = depositionMap(round(nextElectronY), round(nextElectronX)) + electronEnergyLoss;
                    electronX = nextElectronX;
                    electronY = nextElectronY;   
                end

                % photon update
                energy = 0;
                energyLoss = 0;
            end

            depositionMap(round(nextY), round(nextX)) = depositionMap(round(nextY), round(nextX)) + energyLoss;
            posX = nextX;
            posY = nextY;   
        end
    end
end
    
% ============================================================================================================
% display results
% ============================================================================================================
% energy deposition map
close(progressBar);

if particleType == 1
    particleName = 'alpha';
elseif particleType == 2
    particleName = 'beta';
elseif particleType == 3
    particleName = 'gamma';
end
subtitleBlock = {['initial ', particleName, ' energy: ', num2str(initialEnergy), ' MeV'], ...
    ['target materials: ', materialProps(1).name, ' and ', materialProps(2).name], ...
    ['samples run: ', num2str(numSamples)]};

if particleType == 3
    figure(Name = "Cumulative Deposition", NumberTitle="off");
else
    figure(Name = "Deposition", NumberTitle="off");
end
scaleFactor = 1 / numSamples;
depositionMapScaled = depositionMap * scaleFactor;
xRange = [0, gridSize * cmPerPixel];
yRange = [0, gridSize * cmPerPixel];
imagesc(xRange, yRange, depositionMapScaled);
xlabel('cm');
ylabel('cm');
axis xy; 
axis tight;
axis square;
colormap(gca, 'hot');
colorbar;
grid on;
if particleType == 3
    title('Cumulative Energy Deposition per Particle [MeV/n]');
else
    title('Energy Deposition per Particle [MeV/n]');
end
figCumulativeDeposition = gca;
if particleType == 3
    figQuadDeposition = figure(Name = "Cumulative and Component Depositions", NumberTitle = "off");
    figCumulativeDepositionCopy = copyobj(figCumulativeDeposition, figQuadDeposition);
end
figure(1);
subtitle(subtitleBlock);

% gamma interactions breakdown
if particleType == 3
    % photoelectric component
    figure(Name = "Photoelectric Interaction Deposition", NumberTitle = "off");
    depositionMapPhotoelectricScaled = depositionMapPhotoelectric * scaleFactor;
    imagesc(xRange, yRange, depositionMapPhotoelectricScaled);    
    xlabel('cm');
    ylabel('cm');
    axis xy; 
    axis tight;
    axis square;
    colormap(gca, 'hot');
    colorbar;
    grid on;
    title('Deposition per Particle from Photoelectric Interactions [MeV/n]');
    figPhotoelectricDeposition = gca;
    figPhotoelectricDepositionCopy = copyobj(figPhotoelectricDeposition, figQuadDeposition);
    subtitle(subtitleBlock);

    % Compton component
    figure(Name = "Compton Scattering Deposition", NumberTitle = "off");
    depositionMapComptonScaled = depositionMapCompton * scaleFactor;
    imagesc(xRange, yRange, depositionMapComptonScaled);    
    xlabel('cm');
    ylabel('cm');    
    axis xy; 
    axis tight;
    axis square;
    colormap(gca, 'hot');
    colorbar;
    grid on;
    title('Deposition per Particle from Compton Scattering [MeV/n]');
    figComptonDeposition = gca;
    figComptonDepositionCopy = copyobj(figComptonDeposition, figQuadDeposition);
    subtitle(subtitleBlock);

    % pair production component
    figure(Name = "Pair Production Deposition", NumberTitle = "off");
    depositionMapPairproScaled = depositionMapPairpro * scaleFactor;
    imagesc(xRange, yRange, depositionMapPairproScaled);
    xlabel('cm');
    ylabel('cm');
    axis xy; 
    axis tight;
    axis square;
    colormap(gca, 'hot');
    colorbar;
    grid on;
    title('Deposition per Particle from Pair Production Events [MeV/n]');
    figPairproDeposition = gca;
    figPairproDepositionCopy = copyobj(figPairproDeposition, figQuadDeposition);
    subtitle(subtitleBlock);

    % QUADRUPLE PLOT!
    figure(2);
    subplot(2, 2, 1, figCumulativeDepositionCopy);
    hold on;
    colorbar;
    subplot(2, 2, 2, figPhotoelectricDepositionCopy);
    colorbar;
    subplot(2, 2, 3, figComptonDepositionCopy);
    colorbar;
    subplot(2, 2, 4, figPairproDepositionCopy);
    colorbar;
    sgtitle(subtitleBlock);
end

% dose map
figure(Name = "Dose", NumberTitle = "off");
densityMap1 = (imgFinal == 1) * materialProps(1).density;
densityMap2 = (imgFinal == 2) * materialProps(2).density;
massMap = (densityMap1 + densityMap2) * (cmPerPixel^3) / 1000; % g/cm3 * cm3 * kg / 1000 g = kg / 1000
doseMap = zeros(size(depositionMapScaled));
validPixels = massMap > 0; % avoid division by zero
doseMap(validPixels) = (depositionMapScaled(validPixels) * 1.602e-13) ./ massMap(validPixels);
imagesc(xRange, yRange, doseMap);
xlabel('cm');
ylabel('cm');
axis xy; 
axis tight;
axis square;
colormap(gca, 'hot');
colorbar;
grid on;

title('Dose per Particle [Gy/n]');
subtitle(subtitleBlock);

figure(Name = "Material Regions", NumberTitle = "off");
imshow(imgDisplay);
title({['Black: ', materialProps(1).name], ['White: ', materialProps(2).name]})
axis xy;
axis tight;
axis square;

% results need to be multiplied by:
% particles per decay [n/decay], activity [Bq] [decay/s], and time [s]
% to obtain real dose [Gy]





% ============================================================================================================
% alpha functions
% ============================================================================================================

% ============================================================================================
% simple Bethe formula per wikipedia
% ============================================================================================
function dEdx = calculateAlpha(E_space, materialStruct)
    rho = materialStruct.density;
    Z = materialStruct.Z;
    
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

% ============================================================================================================
% beta functions
% ============================================================================================================

% ============================================================================================
% Berger-Seltzer for electron stopping power
% ============================================================================================
% ICRU 37
function dEdx = calculateBeta(E_space, materialStruct)
    rho = materialStruct.density;
    Z = materialStruct.Z;
    
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

% ============================================================================================================
% gamma functions
% ============================================================================================================

% ============================================================================================
% cross-section of photoelectric effect, compton scattering, pair production
% ============================================================================================
% https://en.wikipedia.org/wiki/Gamma_ray_cross_section
function [photo, compton, pairpro, sigma, mu] = calculateGamma(E_space, materialStruct, epsilon)
    rho = materialStruct.density;
    Z = materialStruct.Z;

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