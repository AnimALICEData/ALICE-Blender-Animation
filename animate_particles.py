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

import math
import os
import random

# Import Particle class
filename = os.path.join(os.path.basename(bpy.data.filepath), "particle.py")
exec(compile(open(filename).read(), filename, 'exec'))

t_video=15 # total video duration in seconds
t_simulado=0.015 # tempo em microssegundos ~ tempo para percorrer 3m na velocidade da luz
fps = 24 # frames per second
N_frames=t_video*fps # Total number of frames
delta_t=t_simulado/N_frames # time elapsed per frame

particle_types = ["Electron","Pion","Muon","Proton","Kaon"]
clRed = (1, 0, 0)
clGreen = (0, 1, 0)
clBlue = (0, 0, 1)
clMagenta = (0.75, 0, 1)
clYellow = (1, 1, 0)
particle_colors = {"Electron":clRed, "Pion":clGreen, "Muon":clBlue, "Proton":clMagenta, "Kaon": clYellow}

# Particle radius
r_part = 0.05

# Event Multiplicity
n_particles = 200

# Configure Environment
bcs = bpy.context.scene
bcs.world.light_settings.use_environment_light = False
bcs.world.light_settings.environment_energy = 0.1


# Configure Output
bcsr = bcs.render
bcsr.resolution_percentage = 50
bcsr.image_settings.file_format = 'FFMPEG'
bcsr.ffmpeg.format = "MPEG4"
bcsr.ffmpeg.codec = "H264"
bcsr.ffmpeg.use_max_b_frames = False
bcsr.ffmpeg.video_bitrate = 6000
bcsr.ffmpeg.maxrate = 9000
bcsr.ffmpeg.minrate = 0
bcsr.ffmpeg.buffersize = 224 * 8
bcsr.ffmpeg.packetsize = 2048
bcsr.ffmpeg.muxrate = 10080000

xpixels = int(bcsr.resolution_percentage * bcsr.resolution_x / 100)
output_prefix="N"+str(n_particles)+"_Gaussian_"+str(xpixels)+"px_"
bcsr.filepath = "/tmp/blender/"+output_prefix
#bcsr.threads_mode = 'FIXED'
#bcsr.threads = 16


# Function that creates Blender Objects from input list of particles.
## Returns a list of blender objects
def create(particles):
    bcsr.fps=fps
    bcs.frame_start = 0
    bcs.frame_end = N_frames
    blender_particles=[]

    #Create Materials
    for type in particle_types:
        bpy.data.materials.new(name=type)
        #bpy.context.object.active_material = (1, 0, 0)
        bpy.data.materials[type].diffuse_color = particle_colors[type]

    # Create blender spheres (particles)
    for particle in particles:
        this_type=random.choice(particle_types)
        print("Adding Sphere - Particle " + str(len(blender_particles))+" of "+str(n_particles-1)+" - "+this_type)
        bpy.ops.mesh.primitive_uv_sphere_add()
        this_particle = bpy.context.object
        this_particle.name = "part"+str(particle.iDx)
        this_particle.location=((particle.x,particle.y,particle.z))
        this_particle.delta_scale=(r_part,r_part,r_part)
        this_particle.data.materials.clear()
        this_particle.data.materials.append(bpy.data.materials[this_type])
        blender_particles.append(this_particle)
    return blender_particles

# Function that animates the scene using the particle propagator class
def animate(objects):
    #Animate particles
    for f in range(1, N_frames):
        t=delta_t*f
        bcs.frame_current = f
        print("Configuring Frame: "+str(f)+" of "+str(N_frames))
        for i in range(0, len(objects)):
            bcs.objects.active=objects[i]
            objects[i].location=(particles[i].Propagate(t))
            objects[i].keyframe_insert(data_path='location')


# Remove cube
bpy.data.objects.remove(bpy.data.objects['Cube'])

camera_forward=bpy.data.objects['Camera']
camera_forward.name = 'ForwardCamera'
camera_forward.location=(0,0,20)
camera_forward.rotation_euler[0] = 0
camera_forward.rotation_euler[2] = 0
camera_forward.data.type = 'ORTHO'
camera_forward.data.ortho_scale = 10



bpy.ops.object.camera_add(location=(6, 0, 0), rotation=(0, 1.5708, 0))
#bpy.context.object.rotation_euler[1] = 1.5708
bpy.context.object.name = "BarrelCamera"

# Select scene camera
bpy.context.scene.camera = bpy.data.objects["ForwardCamera"]

# Create particles
particles = createNparticlesPropGaussian(n_particles)

# Create blender objects
blender_particles = create(particles)

# ALICE TPC
print("Adding ALICE TPC")
bpy.data.materials.new(name="TPC")
bpy.data.materials["TPC"].diffuse_color = (0, 0.635632, 0.8)
bpy.data.materials["TPC"].use_shadows = False
bpy.data.materials["TPC"].use_cast_shadows = False
bpy.data.materials["TPC"].use_transparency = True
bpy.data.materials["TPC"].alpha = 1
bpy.data.materials["TPC"].specular_alpha = 0
bpy.data.materials["TPC"].raytrace_transparency.fresnel_factor = 5
bpy.data.materials["TPC"].raytrace_transparency.fresnel = 0.3


bpy.ops.mesh.primitive_cylinder_add(radius=2.5, depth=5, view_align=False, enter_editmode=False, location=(0, 0, 0))
TPC = bpy.context.object
TPC.name = "TPC"
TPC.data.materials.clear()
TPC.data.materials.append(bpy.data.materials["TPC"])



#Animate Scene
animate(blender_particles)
bpy.context.scene.frame_current = 20

## Todo:
##  - Add option to keep particle trails
##  - Add simple geometry of the ALICE detector

## Save blender file
#bpy.ops.wm.save_as_mainfile(filepath="/home/pezzi/particles_"+str(n_particles)+".blend")

# Render animation
#bpy.ops.render.render(animation=True)

#exit()
