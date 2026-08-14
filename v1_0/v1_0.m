% ====================================================================================================================================
% ====================================================================================================================================
%
%% DESCRIPTION
%
% ====================================================================================================================================
% ====================================================================================================================================

% v1_0
% start: 2026 08 14, 16:30 EST
% completion: 2026 08 14, 19:18 EST

% goals:
    % particle struct
    % new loop
        % call functions
        % add product particles

% ====================================================================================================================================
% ====================================================================================================================================
%
%% TABLE OF CONTENTS
%
% ====================================================================================================================================
% ====================================================================================================================================
    
    % ============================================================================================================
    %
    % SATELLITES
    %
    % ============================================================================================================
    
        % ============================================================================================
        % Alpha
        % ============================================================================================
        %
        % calculateAlphaLUTs(E_space, materialStruct) = dEdx
        % simulateAlpha.m
        
        % ============================================================================================
        % Beta
        % ============================================================================================
        %
        % calculateBetaLUTs(E_space, materialStruct) = dEdx
        % simulateBeta.m
        
        % ============================================================================================
        % Gamma
        % ============================================================================================
        %
        % calculateGammaLUTs(E_space, materialStruct, epsilon) = [photo, compton, pairpro, sigma, mu]
        % comptonScatterAngle(epsilonSingle) = scatterAngle
        % pairproFraction(photonEnergy, Z) = epsilonPairpro
        % simulateGamma.m
        
        % ============================================================================================
        % Figure
        % ============================================================================================
        %
        % getStats(data) = statLine
    
    % ============================================================================================================
    %
    % SCRIPT
    %
    % ============================================================================================================
    
        % ============================================================================================
        % Setup
        % ============================================================================================
        % 
        % import & process 2D map
        % physical grid properties
        % set simulation parameters
    
        % ============================================================================================
        % Precalculate
        % ============================================================================================
        % 
        % particle registry
        % look-up tables

        % ============================================================================================
        % Simulate
        % ============================================================================================
        % 
        % call satellites
        % add products to registry

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
%% SCRIPT
%
% ====================================================================================================================================
% ====================================================================================================================================

    
    % ============================================================================================================
    %% Setup
    % ============================================================================================================
    % clear
    clear; 
    clc; 
    close all;
    
        % ============================================================================================
        %% import & process 2D map
        % ============================================================================================
        % read file
        [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tiff', 'Image Files (*.png, *.jpg, *.jpeg, *.bmp, *.tiff)'});
        if isequal(file,0) 
            error("user canceled file selection!"); 
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

        % region name
        promptRegionName = "Input region name";
        dlgTitleRegionName = 'Name';
        defaultRegionName = {'Target'};
        answerRegionName = inputdlg(promptRegionName, dlgTitleRegionName, 1, defaultRegionName);
        filenameRegionName = answerRegionName{1};
        
        % resize to 1000x1000
        promptSize = {'Enter linear resolution of the simulation grid [px]'};
        dlgTitleSize = 'Size';
        defaultSize = {'1000'};
        answerSize = inputdlg(promptSize, dlgTitleSize, 1, defaultSize);
        gridSize = str2double(answerSize{1});
            if gridSize < 1
                error("user input invalid grid size!")
            end
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
        %% physical grid properties
        % ============================================================================================
        % prompt to define actual size [cm]
        promptScale = {'Enter physical width of the simulation grid [cm]'};
        dlgTitleScale = 'Scale';
        defaultScale = {'10.0'};
        answerScale = inputdlg(promptScale, dlgTitleScale, 1, defaultScale);
        gridWidthCm = str2double(answerScale{1});
            if gridWidthCm <= 0
                error("user input invalid physical grid size!")
            end
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
        title(filenameRegionName);
        subtitle({'Region 1: Black', 'Region 2: White'});
        
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
                if materialProps(regionID).density < 0
                    error("user input negative density!")
                end
            materialProps(regionID).Z = str2double(answerMat{3});
                if materialProps(regionID).Z < 1
                    error("user input invalid Z!")
                end
        end
        
        % close imgDisplay
        close(gcf);
    
        % ============================================================================================
        %% set simulation parameters
        % ============================================================================================
        % prompt for particle type, energy, and sample count
        particleTypeText = "Particle type" + newline + "(1=Alpha, 2=Beta, 3=Gamma)";
        sampleCountText = "Sample count linear density [n/px]" + newline ...
            + "Recommended: 100 for alphas, 500 for betas, 1000 for gammas";
            % + "This scales with the square of the simulation grid linear resolution!" + newline ...
            %
            % recommended sample counts are based on randomness: 
            % alphas do not scatter (yet), so they have the lowest noise
            % betas do scatter, so they have lots of noise
            % gammas scatter, have three possible interactions, and produce
            % secondary particles. extremely noisy
        promptParams = {particleTypeText, 'Particle energy [MeV]:', sampleCountText};
        dlgTitleParams = 'Particle Configuration';
        defaultParams = {'3', '1.33', '1000'}; % cobalt-60 decay
        answerParams = inputdlg(promptParams, dlgTitleParams, 1, defaultParams);
        particleType = str2double(answerParams{1});
            if particleType ~= 1 && particleType ~= 2 && particleType ~= 3
                error("user input invalid particle ID!")
            end
        initialEnergy = str2double(answerParams{2});
            if initialEnergy < 0
                error("user input negative energy!")
            end
        samplesPerPixel = str2double(answerParams{3});
            if samplesPerPixel <= 0
                error("user input invalid sample count!")
            end
        numSamples = samplesPerPixel * gridSize; % i said it scales with the square but i don't think that's actually necessary until we get to a custom source
    
    % ============================================================================================================
    %% Precalculate
    % ============================================================================================================        
    % constants
    c = 29979245800; % duh [cm/s]
    m_e = 0.511; % electron rest mass [MeV/c^2]

    % steps
    stepLength = 1; % step length per cycle in pixels
    realLength = stepLength * cmPerPixel;

    % create empty energy deposition maps
    depositionMap = zeros(gridSize, gridSize);
    depositionMapPhotoelectric = zeros(gridSize, gridSize);
    depositionMapCompton = zeros(gridSize, gridSize);
    depositionMapPairpro = zeros(gridSize, gridSize);

    % create particle registry
    particleRegistry = struct();
    for i = 1:numSamples
        particleRegistry(i).type = particleType;
        particleRegistry(i).order = 1;
        particleRegistry(i).energy = initialEnergy; 
        particleRegistry(i).x = 1;
        particleRegistry(i).y = randi(gridSize);
        particleRegistry(i).theta = 0;
    end

        % ============================================================================================
        %% look-up tables
        % ============================================================================================
        E_space = linspace(0.01, initialEnergy, 100000); 
        epsilon = E_space ./ m_e;
    
        % alpha LUTs
        if particleType == 1
            LUT_Alpha1 = calculateAlphaLUTs(E_space, materialProps(1));
            LUT_Alpha2 = calculateAlphaLUTs(E_space, materialProps(2));
    
        % beta LUTs and secondary photon LUTs
        elseif particleType == 2
            LUT_Beta1 = calculateBetaLUTs(E_space, materialProps(1)); 
            LUT_Beta2 = calculateBetaLUTs(E_space, materialProps(2));
    
            [LUT_BremsPhoto1, ...
                LUT_BremsCompton1, ...
                LUT_BremsPairpro1, ...
                LUT_BremsSigma1, ...
                LUT_BremsMu1] ...
                = calculateGammaLUTs(E_space, materialProps(1), epsilon); 
            [LUT_BremsPhoto2, ...
                LUT_BremsCompton2, ...
                LUT_BremsPairpro2, ...
                LUT_BremsSigma2, ...
                LUT_BremsMu2] ...
                = calculateGammaLUTs(E_space, materialProps(2), epsilon);
    
        % gamma LUTs and secondary lepton LUTs
        elseif particleType == 3
            [LUT_GammaPhoto1, ...
                LUT_GammaCompton1, ...
                LUT_GammaPairpro1, ...
                LUT_GammaSigma1, ...
                LUT_GammaMu1] ...
                = calculateGammaLUTs(E_space, materialProps(1), epsilon); 
            [LUT_GammaPhoto2, ...
                LUT_GammaCompton2, ...
                LUT_GammaPairpro2, ...
                LUT_GammaSigma2, ...
                LUT_GammaMu2] ...
                = calculateGammaLUTs(E_space, materialProps(2), epsilon); 
    
            % pair production threshold
            if initialEnergy > 1.022
                secondaryLeptonE_space = linspace(0.01, initialEnergy - 1.022, 100000);
                LUT_Lepton1 = calculateBetaLUTs(secondaryLeptonE_space, materialProps(1)); 
                LUT_Lepton2 = calculateBetaLUTs(secondaryLeptonE_space, materialProps(2));
    
                [LUT_BremsPhoto1, ...
                    LUT_BremsCompton1, ...
                    LUT_BremsPairpro1, ...
                    LUT_BremsSigma1, ...
                    LUT_BremsMu1] ...
                    = calculateGammaLUTs(secondaryLeptonE_space, materialProps(1), epsilon); 
                [LUT_BremsPhoto2, ...
                    LUT_BremsCompton2, ...
                    LUT_BremsPairpro2, ...
                    LUT_BremsSigma2, ...
                    LUT_BremsMu2] ...
                    = calculateGammaLUTs(secondaryLeptonE_space, materialProps(2), epsilon);
            end
        end
    % ============================================================================================================
    %% Simulate
    % ============================================================================================================   
    % progress bar
    progressBar = waitbar(0);

    % loop
    currentSample = 1;
    totalSamples = size(particleRegistry, 2);
    while currentSample < totalSamples
        % progress bar update
        progressPercent = round(100 * currentSample/totalSamples, 1);
        waitbar(currentSample/totalSamples, progressBar, sprintf('Sample %d out of %d\n%.1f%%', currentSample, totalSamples, progressPercent));

        % get particle values
        sampleType = particleRegistry(currentSample).type;
        sampleOrder = particleRegistry(currentSample).order;
        sampleEnergy = particleRegistry(currentSample).energy;
        sampleX = particleRegistry(currentSample).x;
        sampleY = particleRegistry(currentSample).y;
        sampleTheta = particleRegistry(currentSample).theta;

        % empty values
        createdSecondary = 0;
        pairproduced = false;
        secondaryEnergy = 0;
        secondaryX = 0;
        secondaryY = 0;
        secondaryTheta = 0;
        secondaryTheta2 = 0;

        % ============================================================================================
        %% call satellites
        % ============================================================================================
        % alpha
        if sampleType == 1
            depositionMap = ...
                simulateAlpha(sampleEnergy, sampleX, sampleY, sampleTheta, ...
                LUT_Alpha1, LUT_Alpha2, ...
                gridSize, realLength, E_space, imgFinal, depositionMap);
        % beta
        elseif sampleType == 2 && sampleOrder == 1
            [createdSecondary, secondaryEnergy, secondaryX, secondaryY, secondaryTheta, ...
            depositionMap, ~] = ...
                simulateBeta(sampleType, sampleOrder, sampleEnergy, sampleX, sampleY, sampleTheta, ...
                LUT_Beta1, LUT_Beta2, ...
                gridSize, realLength, materialProps, E_space, imgFinal, depositionMap, depositionMapPairpro);
        % secondary electron
        elseif sampleType == 2 && sampleOrder > 1 
            [createdSecondary, secondaryEnergy, secondaryX, secondaryY, secondaryTheta, ...
            depositionMap, depositionMapPairpro] = ...
                simulateBeta(sampleType, sampleOrder, sampleEnergy, sampleX, sampleY, sampleTheta, ...
                LUT_Lepton1, LUT_Lepton2, ...
                gridSize, realLength, materialProps, secondaryLeptonE_space, imgFinal, depositionMap, depositionMapPairpro);
        % positron
        elseif sampleType == 4 
            [createdSecondary, secondaryEnergy, secondaryX, secondaryY, secondaryTheta, ...
            depositionMap, depositionMapPairpro] = ...
                simulateBeta(sampleType, sampleOrder, sampleEnergy, sampleX, sampleY, sampleTheta, ...
                LUT_Lepton1, LUT_Lepton2, ...
                gridSize, realLength, materialProps, secondaryLeptonE_space, imgFinal, depositionMap, depositionMapPairpro);
        % gamma
        elseif sampleType == 3 && sampleOrder == 1
            [pairproduced, electronEnergy, positronEnergy, secondaryX, secondaryY, electronTheta, positronTheta, ...
            depositionMap, depositionMapPhotoelectric, depositionMapCompton] = ...
                simulateGamma(sampleEnergy, sampleX, sampleY, sampleTheta, ...
                LUT_GammaPhoto1, LUT_GammaCompton1, LUT_GammaPairpro1, LUT_GammaSigma1, LUT_GammaMu1, ...
                LUT_GammaPhoto2, LUT_GammaCompton2, LUT_GammaPairpro2, LUT_GammaSigma2, LUT_GammaMu2, ...
                gridSize, cmPerPixel, materialProps, E_space, epsilon, imgFinal, depositionMap, depositionMapPhotoelectric, depositionMapCompton);
        % secondary photon
        elseif sampleType == 3 && sampleOrder > 1
            [pairproduced, electronEnergy, positronEnergy, secondaryX, secondaryY, electronTheta, positronTheta, ...
            depositionMap, depositionMapPhotoelectric, depositionMapCompton] = ...
                simulateGamma(sampleEnergy, sampleX, sampleY, sampleTheta, ...
                LUT_BremsPhoto1, LUT_BremsCompton1, LUT_BremsPairpro1, LUT_BremsSigma1, LUT_BremsMu1, ...
                LUT_BremsPhoto2, LUT_BremsCompton2, LUT_BremsPairpro2, LUT_BremsSigma2, LUT_BremsMu2, ...
                gridSize, cmPerPixel, materialProps, E_space, epsilon, imgFinal, depositionMap, depositionMapPhotoelectric, depositionMapCompton);
        end

        % ============================================================================================
        %% add products to registry
        % ============================================================================================
        % create Bremsstrahlung      
        if createdSecondary == 1
            % blank!
        % create annihilation photons
        elseif createdSecondary == 2
            % photon 1
            particleRegistry(totalSamples + 1).type = 3;
            particleRegistry(totalSamples + 1).order = sampleOrder + 1;
            particleRegistry(totalSamples + 1).energy = secondaryEnergy;
            particleRegistry(totalSamples + 1).x = secondaryX;
            particleRegistry(totalSamples + 1).y = secondaryY;
            particleRegistry(totalSamples + 1).theta = secondaryTheta;

            % photon 2
            particleRegistry(totalSamples + 2).type = 3;
            particleRegistry(totalSamples + 2).order = sampleOrder + 1;
            particleRegistry(totalSamples + 2).energy = secondaryEnergy;
            particleRegistry(totalSamples + 2).x = secondaryX;
            particleRegistry(totalSamples + 2).y = secondaryY;
            particleRegistry(totalSamples + 2).theta = secondaryTheta + pi;

            % update sample count
            totalSamples = totalSamples + 2;
        % create electron-positron pair
        elseif pairproduced == true
            % electron
            particleRegistry(totalSamples + 1).type = 2;
            particleRegistry(totalSamples + 1).order = sampleOrder + 1;
            particleRegistry(totalSamples + 1).energy = electronEnergy;
            particleRegistry(totalSamples + 1).x = secondaryX;
            particleRegistry(totalSamples + 1).y = secondaryY;
            particleRegistry(totalSamples + 1).theta = electronTheta;

            % positron
            particleRegistry(totalSamples + 2).type = 4;
            particleRegistry(totalSamples + 2).order = sampleOrder + 1;
            particleRegistry(totalSamples + 2).energy = positronEnergy;
            particleRegistry(totalSamples + 2).x = secondaryX;
            particleRegistry(totalSamples + 2).y = secondaryY;
            particleRegistry(totalSamples + 2).theta = positronTheta;

            % update sample count
            totalSamples = totalSamples + 2;
        end

        % move counter
        currentSample = currentSample + 1;
    end
        
    % ============================================================================================================
    %% Output Graphics
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
    
    % format numbers
    % not sure if this actually works
    format shortEng
    
    % global subtitle setup
    if particleType == 1
        particleName = 'alpha';
    elseif particleType == 2
        particleName = 'beta';
    elseif particleType == 3
        particleName = 'gamma';
    end
    subtitleBlock = {['initial ', particleName, ' energy: ', num2str(initialEnergy), ' MeV'], ...
        ['particles simulated: ', num2str(numSamples)], ...
        ['target materials: ', materialProps(1).name, ' (density ', num2str(materialProps(1).density), ' [g/cm^3], Z = ', num2str(materialProps(1).Z), '), ', ...
        materialProps(2).name ' (density ', num2str(materialProps(2).density), ' [g/cm^3], Z = ', num2str(materialProps(2).Z), ')']};
    
        % ============================================================================================
        %% total energy deposition map
        % ============================================================================================
        if particleType == 3
            figure(Name = "Cumulative Deposition");
        else
            figure(Name = "Deposition");
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
            figQuadDeposition = figure(Name = "Cumulative and Component Depositions");
            figCumulativeDepositionCopy = copyobj(figCumulativeDeposition, figQuadDeposition);
            figure(1);
            title('Cumulative Energy Deposition per Particle [MeV/n]');
        else
            title('Energy Deposition per Particle [MeV/n]');
        end
        % subtitle
        depositionStatLine = getStats(depositionMapScaled);
        subtitle(cat(2, subtitleBlock, depositionStatLine));
        % for export
        finalCumulativeDeposition = gcf;

        % ============================================================================================
        %% gamma interaction component energy deposition maps
        % ============================================================================================  
        if particleType == 3
            % photoelectric component
            figure(Name = "Photoelectric Interaction Deposition");
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
            % titles for individual plot
            figure(3);
            title('Deposition per Particle from Photoelectric Interactions [MeV/n]');
            photoelectricStatLine = getStats(depositionMapPhotoelectricScaled);
            subtitle(cat(2, subtitleBlock, photoelectricStatLine));
            % data cursor
            dcPhotoelectric = datacursormode;
            dcPhotoelectric.Enable = "on";
            dcPhotoelectric.DisplayStyle = "datatip";
            dcPhotoelectric.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel);             
            % for export
            finalPhotoelectricDeposition = gcf;
        
            % Compton component
            figure(Name = "Compton Scattering Deposition");
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
            % titles for individual plot
            figure(4);
            title('Deposition per Particle from Compton Scattering [MeV/n]');
            comptonStatLine = getStats(depositionMapComptonScaled);        
            subtitle(cat(2, subtitleBlock, comptonStatLine));
            % data cursor
            dcCompton = datacursormode;
            dcCompton.Enable = "on";
            dcCompton.DisplayStyle = "datatip";
            dcCompton.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
            % for export
            finalComptonDeposition = gcf;
        
            % pair production component
            figure(Name = "Pair Production Deposition");
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
            % titles for individual plot
            figure(5);
            title('Deposition per Particle from Pair Production Events [MeV/n]');
            pairproStatLine = getStats(depositionMapPairproScaled);
            subtitle(cat(2, subtitleBlock, pairproStatLine));
            % data cursor
            dcPairpro = datacursormode;
            dcPairpro.Enable = "on";
            dcPairpro.DisplayStyle = "datatip";
            dcPairpro.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
            % for export
            finalPairproDeposition = gcf;
        
            % QUADRUPLE PLOT!
            figure(2);
            % plot
            subplot(2, 2, 1, figCumulativeDepositionCopy);
            title('Cumulative');
            subtitle(depositionStatLine);
            hold on;
            colorbar;
            subplot(2, 2, 2, figPhotoelectricDepositionCopy);
            title('Photoelectric Interactions');
            subtitle(photoelectricStatLine);
            colorbar;
            subplot(2, 2, 3, figComptonDepositionCopy);
            title('Compton Scattering');
            subtitle(comptonStatLine);
            colorbar;
            subplot(2, 2, 4, figPairproDepositionCopy);
            title('Pair Production Events');
            subtitle(pairproStatLine);
            colorbar;
            % titles
            sgtitle(cat(2, {"Energy Deposition per Particle [MeV/n]"}, subtitleBlock));
            % data cursor
            dcCumDeposition = datacursormode;
            dcCumDeposition.Enable = "on";
            dcCumDeposition.DisplayStyle = "datatip";
            dcCumDeposition.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); datacursormode on;
            % for export
            finalQuadPlot = gcf;
        end
    
        % ============================================================================================
        %% dose map
        % ============================================================================================
        figure(Name = "Dose");
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
        doseStatLine = getStats(doseMap);
        subtitle(cat(2, subtitleBlock, doseStatLine));
        % data cursor
        dcDose = datacursormode;
        dcDose.Enable = "on";
        dcDose.DisplayStyle = "datatip";
        dcDose.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
        % for export
        finalDoseMap = gcf;

        % ============================================================================================
        %% miscellaneous figures
        % ============================================================================================
        % material map
        figure(Name = "Material Regions");
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
        % datacursor
        % not currently needed but perhaps with more materials it will be
        dcMaterial = datacursormode;
        dcMaterial.Enable = "on";
        dcMaterial.DisplayStyle = "datatip";
        dcMaterial.UpdateFcn = @(~, info) dataTipText(info, cmPerPixel); 
        % for export
        finalMaterialMap = gcf;
        
        % imported image
        figure(Name = "Imported Image");
        imshow(imgCart);
        axis xy;
        axis tight;
        axis square;
        title(filenameRegionName);
        % for export
        finalImported = gcf;

        % ============================================================================================
        %% export figures to file
        % ============================================================================================
        % particle name
        if particleType == 1
            filenameParticleType = 'Alpha';
        elseif particleType == 2
            filenameParticleType = 'Beta';
        elseif particleType == 3
            filenameParticleType = 'Gamma';
        end

        % material names
        filenameMaterials = [materialProps(1).name, '-', materialProps(2).name];

        % full template
        filenameFullTemplate = [filenameParticleType, ', ', filenameRegionName, ', ', filenameMaterials, ', ', num2str(gridWidthCm), '-cm, ', num2str(gridSize), '-px, ', num2str(initialEnergy), '-MeV, ', num2str(numSamples), '-n, '];
        
        % write all graphs
        if particleType == 3
            % png
            exportgraphics(finalCumulativeDeposition, cat(2, filenameFullTemplate, 'Figure 1---Cumulative Deposition.png'))
            exportgraphics(finalPhotoelectricDeposition, cat(2, filenameFullTemplate, 'Figure 2---Photoelectric Deposition.png'))
            exportgraphics(finalComptonDeposition, cat(2, filenameFullTemplate, 'Figure 3---Compton Deposition.png'))
            exportgraphics(finalPairproDeposition, cat(2, filenameFullTemplate, 'Figure 4---Pair Production Deposition.png'))
            exportgraphics(finalQuadPlot, cat(2, filenameFullTemplate, 'Figure 5---Deposition Quadplot.png'))
            exportgraphics(finalDoseMap, cat(2, filenameFullTemplate, 'Figure 6---Dose.png'))
            exportgraphics(finalMaterialMap, cat(2, filenameFullTemplate, 'Figure 7---Material Regions.png'))
            exportgraphics(finalImported, cat(2, filenameFullTemplate, 'Figure 8---Imported Image.png'))
            % matlab figure
            saveas(finalCumulativeDeposition, cat(2, filenameFullTemplate, 'Figure 1---Cumulative Deposition.fig'))
            saveas(finalPhotoelectricDeposition, cat(2, filenameFullTemplate, 'Figure 2---Photoelectric Deposition.fig'))
            saveas(finalComptonDeposition, cat(2, filenameFullTemplate, 'Figure 3---Compton Deposition.fig'))
            saveas(finalPairproDeposition, cat(2, filenameFullTemplate, 'Figure 4---Pair Production Deposition.fig'))
            saveas(finalQuadPlot, cat(2, filenameFullTemplate, 'Figure 5---Deposition Quadplot.fig'))
            saveas(finalDoseMap, cat(2, filenameFullTemplate, 'Figure 6---Dose.fig'))
            saveas(finalMaterialMap, cat(2, filenameFullTemplate, 'Figure 7---Material Regions.fig'))
            saveas(finalImported, cat(2, filenameFullTemplate, 'Figure 8---Imported Image.fig'))
        else
            % png
            exportgraphics(finalCumulativeDeposition, cat(2, filenameFullTemplate, 'Figure 1---Deposition.png'))
            exportgraphics(finalDoseMap, cat(2, filenameFullTemplate, 'Figure 2---Dose.png'))
            exportgraphics(finalMaterialMap, cat(2, filenameFullTemplate, 'Figure 3---Material Regions.png'))
            exportgraphics(finalImported, cat(2, filenameFullTemplate, 'Figure 4---Imported Image.png'))
            % matlab figure
            saveas(finalCumulativeDeposition, cat(2, filenameFullTemplate, 'Figure 1---Deposition.fig'))
            saveas(finalDoseMap, cat(2, filenameFullTemplate, 'Figure 2---Dose.fig'))
            saveas(finalMaterialMap, cat(2, filenameFullTemplate, 'Figure 3---Material Regions.fig'))
            saveas(finalImported, cat(2, filenameFullTemplate, 'Figure 4---Imported Image.fig'))
        end