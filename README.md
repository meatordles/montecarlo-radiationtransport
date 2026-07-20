# Home-brew Monte Carlo radiation transport simulator
Numerous far more polished and advanced software created by professionals already exist for serious use. This is an exercise for mental and academic enrichment only.
# Goals
## Model 1 goals:  
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

## Model 2 goals:  
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

# History
## v0:
2026 07 05
- image import and processing  
- particle parameters
<img height="360" alt="Screenshot 2026-07-19 110450" src="https://github.com/user-attachments/assets/fd8d8d61-f9d0-45d2-aba2-5367de8625f7" />

## v0_1:
2026 07 07
- alpha simulator  
- deposition map  
## v0_2:
2026 07 17
- beta simulator
<img height="360" alt="image" src="https://github.com/user-attachments/assets/61728471-71dc-43bc-b8d2-d5284aa8c644" />

## v0_3:
2026 07 19  
- gamma simulator
- dose map
<img height="360" alt="image" src="https://github.com/user-attachments/assets/252ac5ce-e3ff-44e0-9677-92f6f94f17c8" />

<img height="360" alt="image" src="https://github.com/user-attachments/assets/edc6ad42-9e16-4f94-aaec-c22a70288624" />
