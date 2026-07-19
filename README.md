v0:
  --- image import and processing
  --- particle parameters
v0_1:
  --- alpha simulator
  --- deposition map
v0_2:
  --- beta simulator
v0_3:
  --- gamma simulator

Model 1 goals:
  --- particles logged individually in a struct vector for easy spawning of secondary particles
    --- particle(type, energy, X, Y, direction)
  --- modularization
    --- separate functions for particle interactions to condense main script and to facilitate secondary/tertiary particle tracking
      --- alpha.m
        --- alpha scattering
      --- beta.m
        --- secondary photon spawning
      --- gamma.m
        --- revised secondary electron spawning
        --- revised secondary positron spawning
          --- secondary annihilation photon spawning
        --- boundary crossings within free path length
    --- main script for user prompts, central cycles loop to call particle functions, and figure drawing
      --- v1.m
  --- neutron simulator? think about it

Model 2 goals:
  --- GUI
    --- default 3 panel layout
    --- undockable windows
  --- unlimited material count
    --- materials selectable with cursor
    --- Z and A calculator 
  --- expanded particle parameters, visualized and settable with cursor on image
    --- spawn point/zone
    --- spawn direction/emission arc
  --- realtime progress display using unscaled deposition map (will keep the fun sample counter and progress bar though)
    --- highlight the most recent samples? may be too expensive to justify the pretty colors
  --- dose rate and dose map 
    --- activity slider and time slider
  --- easy figure export
