# ALICE Open Data Blender animation

Run animation example:
`blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=1 -camera="BarrelCamera" -datafile="esd-detail.dat"`


In the example above, argument 'radius' has value 0.05, 'duration' has value 10 and so on.

*-radius*:
  particle radius; must be a number; type float

*-duration*:
  animation duration; must be a number; type int

*-camera*:
  defines animation view; must be a string; available options: OverviewCamera, BarrelCamera, ForwardCamera

*-datafile*:
  filename for event data file; must be a string

Implement command line arguments:
https://blender.stackexchange.com/questions/6817/how-to-pass-command-line-arguments-to-a-blender-python-script
