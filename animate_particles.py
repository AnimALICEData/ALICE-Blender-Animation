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

t_video=20 # duração da animação em segundos
t_simulado=86400*365*5 # tempo próprio da simulação em segundos
fps = 24 # quadros por segundo
N_quadros=t_video*fps # calculando numero de quadros totais
delta_t=t_simulado/N_quadros # tempo passado por quadro

# Particle radius
r_part = 0.05


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


def animate(objects):
    #Animate particles
    for f in range(1, N_quadros):
        t=delta_t*f
        bpy.context.scene.frame_current = f
        for i in range(0, len(objects)):
            bpy.context.scene.objects.active=objects[i]
            objects[i].location=(0.01*f,0.05*i,0.0000005*i*i*f*f) # Dummy positions
            objects[i].keyframe_insert(data_path='location')


#Remove cube
bpy.data.objects.remove(bpy.data.objects['Cube'])

# Create particles
particles = createNparticles(30)
# Todo: Add lamp and camera in suitable positions

# Create blender objects
blender_particles = create(particles)

#Animate Scene
animate(blender_particles)
