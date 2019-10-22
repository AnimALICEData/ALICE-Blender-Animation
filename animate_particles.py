# -*- coding: utf-8 -*-
# particulas.py - Protótipo de animação de partículas
# Para utilizar este script chame o blender com a opção -P e o nome do arquivo
#
#   $ blender -P ./animate_particles.py


import bpy
bpy.context.user_preferences.view.show_splash = False

import math
import os

# Import Particle class
filename = os.path.join(os.path.basename(bpy.data.filepath), "particle.py")
exec(compile(open(filename).read(), filename, 'exec'))

t_video=10 # duração da animação em segundos
t_simulado=10
fps = 24 # quadros por segundo
N_quadros=t_video*fps # calculando numero de quadros totais
delta_t=t_simulado/N_quadros # tempo passado por quadro

# Particle radius
r_part = 0.10

# Function that creates Blender Objects from input list of particles.
## Returns a list of blender objects
def create(particles):
    bpy.context.scene.render.fps=fps
    bpy.context.scene.frame_start = 0
    bpy.context.scene.frame_end = N_quadros
    blender_particles=[]
    # Create blender spheres (particles)
    for particle in particles:
        bpy.ops.mesh.primitive_uv_sphere_add()
        this_particle = bpy.context.object
        this_particle.name = "part"+str(particle.iDx)
        this_particle.location=((particle.x,particle.y,particle.z))
        this_particle.delta_scale=(r_part,r_part,r_part)
        blender_particles.append(this_particle)
    return blender_particles

# Function that animates the scene using the particle propagator class
def animate(objects):
    #Animate particles
    for f in range(1, N_quadros):
        t=delta_t*f
        bpy.context.scene.frame_current = f
        for i in range(0, len(objects)):
            bpy.context.scene.objects.active=objects[i]
            objects[i].location=(particles[i].Propagate(t))
            objects[i].keyframe_insert(data_path='location')


# Remove cube
bpy.data.objects.remove(bpy.data.objects['Cube'])

# Create particles
particles = createNparticlesProp(1000)

# Create blender objects
blender_particles = create(particles)

#Animate Scene
animate(blender_particles)

## Todo:
##  - Lamp and cameras in suitable positions
##  - Configure particle and background colors
##  - Configure output format and enconding (FFmpeg & H.264 works fine)
##  - Add option to keep particle trails
##  - Add simple geometry of the ALICE detector
