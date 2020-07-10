# -*- coding: utf-8 -*-
# animate_particles.py - Animate HEP events
#
#   For console only rendering (example):
#   $ blender -noaudio --background -P animate_particles.py -- -radius=1.2 -duration=1 \
#   -datafile="esd-detail.dat" -n_event=0 -simulated_t=0.02 -fps=24 -resolution=100 -transparency=1.2 -stamp_note="Texto no canto"\
#    -its=1 -tpc=0 -trd=1 -detailed_tpc=1 -emcal=0 -blendersave=0 -tpc_blender_path="/home/files/blender"\
#    -output_path="/tmp/blender" -bgshade=0.05
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
parser.add_argument('-datafile','--datafile')
parser.add_argument('-simulated_t','--simulated_t')
parser.add_argument('-fps','--fps')
parser.add_argument('-resolution','--resolution_percent')
parser.add_argument('-stamp_note','--stamp_note')
parser.add_argument('-n_event','--n_event')
parser.add_argument('-transparency','--transp_par')
parser.add_argument('-its','--its')
parser.add_argument('-tpc','--tpc')
parser.add_argument('-trd','--trd')
parser.add_argument('-emcal','--emcal')
parser.add_argument('-blendersave','--blendersave')
parser.add_argument('-bgshade','--bgshade')
parser.add_argument('-tpc_blender_path','--tpc_blender_path')
parser.add_argument('-detailed_tpc','--detailed_tpc')
parser.add_argument('-output_path','--output_path')
args = parser.parse_args()

bpy.context.user_preferences.view.show_splash = False
# Import Drivers, particles and scence functions:
filename = os.path.join(os.path.basename(bpy.data.filepath), "drivers.py")
exec(compile(open(filename).read(), filename, 'exec'))

# Set animation parameters
r_part = float(args.r_part) # Particle radius scale
n_event = str(args.n_event) # Event number for video name
simulated_t = float(args.simulated_t) # in microsseconds
duration = int(args.duration) # in seconds
fps = int(args.fps)
resolution_percent = int(args.resolution_percent)
stamp_note = args.stamp_note
transp_par = float(args.transp_par)
datafile = str(args.datafile)
detectors = [int(args.its),int(args.tpc),int(args.trd),int(args.emcal),int(args.detailed_tpc)] # Array that stores which detectors to build
blendersave = int(args.blendersave) # 1 (save Blender file) or 0 (don't)
bgshade = float(args.bgshade)
tpc_blender_path = str(args.tpc_blender_path) # path to 'animate' directory, where .blend file for detailed TPC is saved

# Configure Output
outputPath = str(args.output_path)+"/"
fileIdentifier = "PhysicalTrajectories_"

saveBlenderFile = blendersave # False

"""
# Create and configure animation driver
n_particles = 100 # Event Multiplicity
driver = genDriver("GaussianGenerator",n_particles,3.0) # Simple genDriver takes two parameters: number of particles and Gaussian width
driver.configure(duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)
"""

# Create and configure animation driver
driver = dataDriver("AlirootFileGenerator",n_event,datafile) # Simple dataDriver
driver.configure(duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)

### Build scene
init(stamp_note,transp_par,detectors,tpc_blender_path,bgshade) # Cleanup, addCameras, addALICE_TPC, Set background
particles = driver.getParticles()
blender_particles, blender_tracks = createSceneParticles(particles,r_part,createTracks = True) # Create blender objects - one sphere per particle

#Animate scene using driver
animate(blender_particles,particles,driver)
animate_tracks(blender_tracks,particles,driver)

bpy.context.scene.frame_current = 24

## Save blender file
if saveBlenderFile: bpy.ops.wm.save_as_mainfile(filepath=outputPath+fileIdentifier+"AlirootFileGenerator_"+datafile+"_Event_"+n_event+".blend")
