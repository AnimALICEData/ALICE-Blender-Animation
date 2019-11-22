# ALICE Open Data Blender animation

## Project Description

This project has the purpose of generating a 3D animation of an ALICE particle collision event, inside the LHC, using data obtained from CERN's Open Data Portal, which makes ESDs - Event Summary Data files, that contain information about such events - open and available for analysis.

ESD files regarding the ALICE experiment can be found on http://opendata.cern.ch/search?page=1&size=20&experiment=ALICE, and they should be processed using the Aliroot software, as indicated in the AliESD_Example git repository: https://git.cta.if.ufrgs.br/ALICE-open-data/AliESD_Example/tree/Blender_animation

The software that makes the animation is Blender, which is free and open source. Blender's 2.79b version should be downloaded for this project, and can be found on https://www.blender.org/download/releases/2-79/

The animation making can be summarized in three basic steps:

1) Downloading of an ESD file (for example, any file on this list: http://opendata.cern.ch/record/1102);
2) Processing of ESD file using Aliroot macros;
3) Run code to generate Blender animation using the ESD processing results.


## Requirements

* Blender 2.79b

## Run

Run animation example:
`blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=1 -camera="BarrelCamera" -datafile="esd-detail.dat" -simulated_t=0.02 -fps=24 -resolution=100`


In the example above, argument 'radius' has value 0.05, 'duration' has value 10 and so on.

*-radius*:
  particle radius; must be a number; type float

*-duration*:
  animation duration; must be a number; type int

*-camera*:
  defines animation view; must be a string; available options: OverviewCamera, BarrelCamera, ForwardCamera

*-datafile*:
  filename for event data file; must be a string

*-simulated_t*:
  simulated time of event; must be a number; type float

*-fps*:
  frames per second; must be a number; type int

*-resolution*:
  animation resolution percent; must be a number; type int

Implement command line arguments:
https://blender.stackexchange.com/questions/6817/how-to-pass-command-line-arguments-to-a-blender-python-script
