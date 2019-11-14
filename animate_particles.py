# -*- coding: utf-8 -*-
# animate_particles.py - Animate HEP events
#
#   For console only rendering (example):
#   $ blender -noaudio --background -P animate_particles.py -- -radius 0.05 -duration 10 -camera OverviewCamera -datafile esd-detail.dat
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
args = parser.parse_args()

bpy.context.user_preferences.view.show_splash = False
# Import Drivers, partiles and scence functions:
filename = os.path.join(os.path.basename(bpy.data.filepath), "drivers.py")
exec(compile(open(filename).read(), filename, 'exec'))

# Set animation parameters
r_part = float(args.r_part) # Particle radius
simulated_t = 0.02 # in microsseconds
duration = int(args.duration) # in seconds
fps = 24
resolution_percent = 100

#configure output
outputPath = "/tmp/blender/"
fileIdentifier = "PhysicalTrajectories_"
##  RenderCameras: ["ForwardCamera", "OverviewCamera", "BarrelCamera"]
renderCamera= args.render_camera

renderAnimation = False #True # True
saveBlenderFile = False # False

"""
# Create and configure animation driver
n_particles = 100 # Event Multiplicity
driver = genDriver("GaussianGenerator",n_particles,3.0) # Simple genDriver takes two parameters: number of particles and Gaussian width
driver.configure(renderCamera, duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)
"""

# Create and configure animation driver
driver = dataDriver("AlirootFileGenerator",args.datafile) # Simple dataDriver takes one parameters: filename
driver.configure(renderCamera, duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)

### Build scene
init() # Cleanup, addCameras, addALICE_TPC
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
