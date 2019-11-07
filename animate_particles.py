# -*- coding: utf-8 -*-
# animate_particles.py - Animate HEP events
#
#   For console only rendering:
#   $ blender -noaudio --background -P animate_particles.py -- r_part(FLOAT) duration(INT) renderCamera(STRING)
#
# TODO: - Implement command line arguments
#         - https://blender.stackexchange.com/questions/6817/how-to-pass-command-line-arguments-to-a-blender-python-script

import os
import bpy
import sys # in order to pass command line arguments

# Create array to store arguments from command line
argv = sys.argv
argv = argv[argv.index("--") + 1:]  # get all args after "--"

bpy.context.user_preferences.view.show_splash = False
# Import Drivers, partiles and scence functions:
filename = os.path.join(os.path.basename(bpy.data.filepath), "drivers.py")
exec(compile(open(filename).read(), filename, 'exec'))

# Set animation parameters
r_part = float(argv[0]) # Particle radius
simulated_t = 0.02 # in microsseconds
duration = int(argv[1]) # in seconds
fps = 24
resolution_percent = 100

#configure output
outputPath = "/tmp/blender/"
fileIdentifier = "PhysicalTrajectories_"
##  RenderCameras: ["ForwardCamera", "OverviewCamera", "BarrelCamera"]
renderCamera= str(argv[2]) # "ForwardCamera"

renderAnimation = True # True
saveBlenderFile = False # False

"""
# Create and configure animation driver
n_particles = 100 # Event Multiplicity
driver = genDriver("GaussianGenerator",n_particles,3.0) # Simple genDriver takes two parameters: number of particles and Gaussian width
driver.configure(renderCamera, duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)
"""

# Create and configure animation driver
driver = dataDriver("AlirootFileGenerator","esd-detail.dat") # Simple dataDriver takes one parameters: filename
driver.configure(renderCamera, duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)

### Build scene
init() # Cleanup, addCameras, addALICE_TPC
particles = driver.getParticles()
blender_particles = createSceneParticles(particles) # Create blender objects - one sphere per particle

#Animate scene using driver
animate(blender_particles,particles,driver)
bpy.context.scene.frame_current = 24

## Save blender file
if saveBlenderFile: bpy.ops.wm.save_as_mainfile(filepath=outputPath+fileIdentifier+".blend")

# Render animation
if renderAnimation: driver.render()

#exit()
