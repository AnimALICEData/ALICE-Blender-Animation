# -*- coding: utf-8 -*-
# animate_particles.py - Animate HEP events
#
#   For console only rendering:
#   $ blender -noaudio --background -P animate_particles.py
#
# TODO: - Implement command line arguments
#         - https://blender.stackexchange.com/questions/6817/how-to-pass-command-line-arguments-to-a-blender-python-script

import os
import bpy
bpy.context.user_preferences.view.show_splash = False
# Import Drivers, partiles and scence functions:
filename = os.path.join(os.path.basename(bpy.data.filepath), "drivers.py")
exec(compile(open(filename).read(), filename, 'exec'))

# Set animation parameters
r_part = 0.05 # Particle radius
simulated_t = 0.015
duration = 15
fps = 24
resolution_percent = 100

#configure output
outputPath = "/tmp/blender/"
fileIdentifier = "PhysicalTrajectories_"
##  RenderCameras: ["ForwardCamera", "OverviewCamera", "BarrelCamera"]
renderCamera="ForwardCamera"

renderAnimation = True # True
saveBlenderFile = False # False

# Create and configure animation driver
n_particles = 500 # Event Multiplicity
driver = genDriver("GaussianGenerator_N"+str(n_particles)+"_")
driver.configure(renderCamera, duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent)

### Build scene
init() # Cleanup, addCameras, addALICE_TPC
particles = driver.createParticles(n_particles,3.0) # Simple genDriver takes two parameters: number of particles and Gaussian width
blender_particles = createSceneParticles(particles) # Create blender objects - one sphere per particle

#Animate scene using driver
animate(blender_particles,particles,driver)
bpy.context.scene.frame_current = 24

## Save blender file
if saveBlenderFile: bpy.ops.wm.save_as_mainfile(filepath=outputPath+fileIdentifier+".blend")

# Render animation
if renderAnimation: driver.render()

#exit()
