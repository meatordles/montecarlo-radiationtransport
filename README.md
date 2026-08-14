# Monte Carlo radiation transport simulator at home
<img height="360" alt="ax17tc" src="https://github.com/user-attachments/assets/38bb09c6-7411-420f-adf8-8423412d0b81" />

Numerous immeasurably more polished and advanced software created by professionals already exist for serious use. This is an exercise for mental and academic enrichment only.  
# Capabilities
## Basic goals
- simulate alpha, beta, and gamma radiation transport within a customizable region  
- give physically useful graphical output  
## Version 1 objectives
- particles logged individually in a struct vector for easy spawning of secondary particles  
    - particle(type, energy, X, Y, direction)  
- modularization  
    - separate functions for particle interactions to condense main script and to facilitate secondary/tertiary particle tracking  
        - alpha.m  
            - alpha scattering  
        - beta.m  
            - secondary photon spawning  
        - gamma.m  
            - revised secondary electron spawning  
            - revised secondary positron spawning  
                - secondary annihilation photon spawning  
            - boundary crossings within free path length  
    - main script for user prompts, central cycles loop to call particle functions, and figure drawing  
        - v1.m  
- neutron simulator? think about it  

## Version 2 objectives
- GUI  
    - default 3 panel layout  
    - undockable windows  
- unlimited material count  
    - materials selectable with cursor  
    - Z and A calculator  
- expanded particle parameters, visualized and settable with cursor on image  
    - spawn point/zone  
    - spawn direction/emission arc  
- realtime progress display using unscaled deposition map (will keep the fun sample counter and progress bar though)  
    - highlight the most recent samples? may be too expensive to justify the pretty colors  
- dose rate and dose map  
    - activity slider and time slider  

# History and Changelog
## v0 | 2026 07 05
- image import and processing  
- particle parameters
<img height="360" alt="7kfib4" src="https://github.com/user-attachments/assets/b8120899-df16-461c-bcd7-5b3014ad7679" />

<img height="360" alt="Screenshot 2026-07-19 110450" src="https://github.com/user-attachments/assets/fd8d8d61-f9d0-45d2-aba2-5367de8625f7" />

## v0_1 | 2026 07 07
- alpha simulator  
- deposition map  
## v0_2 | 2026 07 17
- beta simulator
<img height="360" alt="image" src="https://github.com/user-attachments/assets/61728471-71dc-43bc-b8d2-d5284aa8c644" />

## v0_3 | 2026 07 19  
Setting the background medium to air causes both energy deposition and dose to vanish.
- gamma simulator
- dose map
<img height="360" alt="image" src="https://github.com/user-attachments/assets/252ac5ce-e3ff-44e0-9677-92f6f94f17c8" />

<img height="360" alt="image" src="https://github.com/user-attachments/assets/edc6ad42-9e16-4f94-aaec-c22a70288624" />

## v0_4 | 2026 07 20 
Not actually functional due to several fatal errors. These were overlooked because the below output was generated in the command window, so the erroneous code was never run.
- added material boundary checks to gamma simulator, fixing gammas instantly vanishing if starting position was in a material that produced a free path length larger than the physical bounds of the simulation
- refined and expanded output graphics
- fixed some typos
- removed many old comments
<img height="180" alt="Gamma, David, Lead-Air, 100-cm, 6 MeV, 1000000-n, 1-Cumulative Deposition" src="https://github.com/user-attachments/assets/6176c54f-7973-4e00-babb-b280be0e5964" />

<img height="180" alt="Gamma, David, Lead-Air, 100-cm, 6 MeV, 1000000-n, 2-Photoelectric Deposition" src="https://github.com/user-attachments/assets/8024062e-cc9b-4192-9a2f-06c291d1d114" />

<img height="180" alt="Gamma, David, Lead-Air, 100-cm, 6 MeV, 1000000-n, 3-Compton Deposition" src="https://github.com/user-attachments/assets/01cd2434-b51e-4ecc-8d46-f5383acd035e" />

<img height="180" alt="Gamma, David, Lead-Air, 100-cm, 6 MeV, 1000000-n, 4-Pair Production Deposition" src="https://github.com/user-attachments/assets/4815c39a-de9e-4451-b2aa-40173cc19a1b" />

<img height="180" alt="Gamma, David, Lead-Air, 100-cm, 6 MeV, 1000000-n, 5-Quad Figure Deposition" src="https://github.com/user-attachments/assets/11d1e07a-5843-4764-ad1a-2f801d486d8e" />

<img height="180" alt="Gamma, David, Lead-Air, 100-cm, 6 MeV, 1000000-n, 6-Dose" src="https://github.com/user-attachments/assets/fe8de4a0-6b1b-40d0-bfb4-15bd792bd768" />

<img height="180" alt="Gamma, David, Lead-Air, 100-cm, 6 MeV, 1000000-n, 7-Regions" src="https://github.com/user-attachments/assets/4893b5a7-749c-47ab-ad14-053d5b2ebaa7" />

## v0_5 | 2026 07 20
Works excellently. Only the particle log structure vector and rearranging of the simulation cycles prevent this from being numbered "v1_0". Also maybe a estimated time to completion for the simulation.
- fixed fatal errors  
- refined input dialogs  
- further refined and expanded output graphics  
    - changed default colormap to "turbo" for better visibility (also it looks like Tame Impala which is actually just one guy did you know that?)  
    - added data cursor to extract values from graphics  
- separated functions into individual files  
- added table of contents  
- added headers and descriptions  
- indented sections according to table of contents
<img height="180" alt="Gamma, David, Lead-Water, 100-cm, 10 MeV, 1000000-n, 1-Cumulative Deposition" src="https://github.com/user-attachments/assets/2f9123c8-85e2-450d-b7f9-c871528dec50" />

<img height="180" alt="Gamma, David, Lead-Water, 100-cm, 10 MeV, 1000000-n, 2-Photoelectric Deposition" src="https://github.com/user-attachments/assets/9d898a57-0d4b-4442-aef4-f98db884b4bb" />

<img height="180" alt="Gamma, David, Lead-Water, 100-cm, 10 MeV, 1000000-n, 3-Compton Deposition" src="https://github.com/user-attachments/assets/e996decc-2678-4d56-8303-5a753c3985bf" />

<img height="180" alt="Gamma, David, Lead-Water, 100-cm, 10 MeV, 1000000-n, 4-Pair Production Deposition" src="https://github.com/user-attachments/assets/bf2920a2-198f-45e4-b114-1c0a54f5e5f6" />

<img height="180" alt="Gamma, David, Lead-Water, 100-cm, 10 MeV, 1000000-n, 5-Deposition Quadplot" src="https://github.com/user-attachments/assets/26c13722-2f2e-44c8-9f0d-668dc5ade160" />

<img height="180" alt="Gamma, David, Lead-Water, 100-cm, 10 MeV, 1000000-n, 6-Dose" src="https://github.com/user-attachments/assets/dc21490d-7549-42db-8b96-bc8329033669" />

<img height="180" alt="Gamma, David, Lead-Water, 100-cm, 10 MeV, 1000000-n, 7-Material Regions" src="https://github.com/user-attachments/assets/7296ecb6-b8cd-4a14-be4a-611b8feca8bd" />

<img height="180" alt="Gamma, David, Lead-Water, 100-cm, 10 MeV, 1000000-n, 8-Imported Image" src="https://github.com/user-attachments/assets/82362d34-3569-4b0e-b565-1b24be616dcb" />

## v0_6 | 2026 08 11
Further refining of UI before full sprint to v1
- added a bunch of error messages
- added autoexport figures
- fixed some NaN issues
<img height="180" alt="Beta, Gem alert!, air-water, 10-cm, 1000-px, 1 42-MeV, 500000-n, Figure 1---Deposition" src="https://github.com/user-attachments/assets/df566d16-d094-45b1-9189-8bfb9d62723d" />

<img height="180" alt="Beta, Gem alert!, air-water, 10-cm, 1000-px, 1 42-MeV, 500000-n, Figure 2---Dose" src="https://github.com/user-attachments/assets/1ef45605-77ce-48c1-92cc-0f076fb9912f" />

<img height="180" alt="Beta, Gem alert!, air-water, 10-cm, 1000-px, 1 42-MeV, 500000-n, Figure 3---Material Regions" src="https://github.com/user-attachments/assets/f27fdd50-9377-4dd0-bd49-226144a25c73" />

<img height="180" alt="Beta, Gem alert!, air-water, 10-cm, 1000-px, 1 42-MeV, 500000-n, Figure 4---Imported Image" src="https://github.com/user-attachments/assets/7c18334b-f478-4f75-8fc9-7b9d543ebfde" />

<img height="180" alt="Screenshot 2026-08-11 214959" src="https://github.com/user-attachments/assets/c0ea2b0a-6b3c-4dc8-bf4e-3bd44d7303ca" />

## v1_0 | 2026 08 14
Goals of version 1 accomplished.
