# -*- coding: utf-8 -*-
# animate_particles.py - Animate HEP events
#
#   For console only rendering (example):
#   $ blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=1 -camera="BarrelCamera" -datafile="esd-detail.dat" -n_event=0 -simulated_t=0.02 -fps=24 -resolution=100 -transperency=1.2 -stamp_note="Texto no canto"
#

import os
import bpy

import argparse
import sys

# Pass on command line arguments to script:
class ArgumentParserForBlender(argparse.ArgumentParser):
    def _get_argv_after_doubledash(self):
        try:
            idx = sys.argv.index("--")
            return sys.argv[idx+1:] # the list after '--'
        except ValueError as e: # '--' not in the list:
            return []

    # overrides superclass
    def parse_args(self):
        return super().parse_args(args=self._get_argv_after_doubledash())

parser = ArgumentParserForBlender()

parser.add_argument('-radius','--r_part')
parser.add_argument('-duration','--duration')
parser.add_argument('-camera','--render_camera')
parser.add_argument('-datafile','--datafile')
parser.add_argument('-simulated_t','--simulated_t')
parser.add_argument('-fps','--fps')
parser.add_argument('-resolution','--resolution_percent')
parser.add_argument('-stamp_note','--stamp_note')
parser.add_argument('-n_event','--n_event')
parser.add_argument('-transperency','--transp_par')
args = parser.parse_args()

bpy.context.user_preferences.view.show_splash = False
# Import Drivers, particles and scence functions:
filename = os.path.join(os.path.basename(bpy.data.filepath), "drivers.py")
exec(compile(open(filename).read(), filename, 'exec'))

# Set animation parameters
r_part = float(args.r_part) # Particle radius
n_event = str(args.n_event) # Event number for video name
simulated_t = float(args.simulated_t) # in microsseconds
duration = int(args.duration) # in seconds
fps = int(args.fps)
resolution_percent = int(args.resolution_percent)
transp_par = float(args.transp_par)

#configure output
outputPath = "/tmp/blender/"
fileIdentifier = "PhysicalTrajectories_"
##  RenderCameras: ["ForwardCamera", "OverviewCamera", "BarrelCamera"]
renderCamera= args.render_camera

renderAnimation = True # True
saveBlenderFile = False # False

"""
# Create and configure animation driver
n_particles = 100 # Event Multiplicity
driver = genDriver("GaussianGenerator",n_particles,3.0) # Simple genDriver takes two parameters: number of particles and Gaussian width
driver.configure(renderCamera, duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)
"""

# Create and configure animation driver
driver = dataDriver("AlirootFileGenerator",n_event,args.datafile) # Simple dataDriver takes one parameters: filename
driver.configure(renderCamera, duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)

### Build scene
init(args.stamp_note,renderCamera,transp_par) # Cleanup, addCameras, addALICE_TPC
particles = driver.getParticles()
blender_particles, blender_tracks = createSceneParticles(particles,createTracks = True) # Create blender objects - one sphere per particle

#Animate scene using driver
animate(blender_particles,particles,driver)
animate_tracks(blender_tracks,particles,driver)

bpy.context.scene.frame_current = 24

## Save blender file
if saveBlenderFile: bpy.ops.wm.save_as_mainfile(filepath=outputPath+fileIdentifier+".blend")

# Render animation
if renderAnimation: driver.render()

#exit()
