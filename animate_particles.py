# -*- coding: utf-8 -*-
# particulas.py - Protótipo de animação de partículas
# Para utilizar este script chame o blender com a opção -P e o nome do arquivo
#
#   For console only rendering:
#   $ blender -noaudio --background -P animate_particles.py
#
# TODO: - Implement command line arguments
#         - https://blender.stackexchange.com/questions/6817/how-to-pass-command-line-arguments-to-a-blender-python-script

import bpy
bpy.context.user_preferences.view.show_splash = False
bcs = bpy.context.scene
bcsr = bcs.render
import math
import os
import random
# Import Particle class
filename = os.path.join(os.path.basename(bpy.data.filepath), "particle.py")
exec(compile(open(filename).read(), filename, 'exec'))
# Import scene functions
filename = os.path.join(os.path.basename(bpy.data.filepath), "scene_functions.py")
exec(compile(open(filename).read(), filename, 'exec'))


# Set animation parameters
renderCamera = "ForwardCamera" # Set rendering Camera: "ForwardCamera" "OverviewCamera" "BarrelCamera"
n_particles = 500 # Event Multiplicity
r_part = 0.05 # Particle radius
t_video=15 # total video duration in seconds
t_simulado=0.015 # tempo simulado em microssegundos. 0.01 é o tempo para percorrer 3m na velocidade da luz
fps = 24 # frames per second
N_frames=t_video*fps # Total number of frames
delta_t=t_simulado/N_frames # time elapsed per frame
bcs.frame_start = 0
bcs.frame_end = N_frames
init()

#configure output
fileIdentifier="_GaussianMomentum-PhysicalTrajectories_"
configureOutput(fileIdentifier,resolution_percent=100)
renderAnimation=False

addCameras() # Add cameras
addALICE_TPC() # ALICE TPC
particles = createNparticlesPropGaussian(n_particles) # Create particles
blender_particles = create(particles) # Create blender objects - one sphere per particle
animate(blender_particles,particles)  #Animate Scene using particle propagator
bpy.context.scene.frame_current = 24

## Todo:
##  - Add option to keep particle trails

## Save blender file
#bpy.ops.wm.save_as_mainfile(filepath="/home/pezzi/particles_"+str(n_particles)+".blend")

# Render animation
bpy.context.scene.camera = bpy.data.objects[renderCamera]
bpy.ops.render.render(animation=renderAnimation)

#exit()
