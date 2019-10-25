# -*- coding: utf-8 -*-

def init():

    # Configure Environment
    bcs.world.light_settings.use_environment_light = False
    bcs.world.light_settings.environment_energy = 0.1

    # Cleanup
    bpy.data.objects.remove(bpy.data.objects['Cube'])
    bpy.data.objects.remove(bpy.data.objects['Camera'])


def configureOutput(fileIdentifier,resolution_percent=100):
    # Configure Output
    bcsr.fps=fps
    bcsr.resolution_percentage = resolution_percent
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
    output_prefix="N"+str(n_particles)+fileIdentifier+str(xpixels)+"px_"
    bcsr.filepath = "/tmp/blender/"+output_prefix


def addALICE_TPC():
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


def addCameras():
    # ForwardCamera
    bpy.ops.object.camera_add(location=(0,0,20), rotation=(0, 0, 0))
    bpy.context.object.name = "ForwardCamera"
    camera_forward=bpy.data.objects['ForwardCamera']
    camera_forward.data.type = 'ORTHO'
    camera_forward.data.ortho_scale = 10

    # OverviewCamera
    bpy.ops.object.camera_add(location=(6.98591, -19.7115, 23.9696), rotation=(-0.281366, 0.683857, -1.65684))
    bpy.context.object.name = "OverviewCamera"
    bpy.context.object.data.lens = 66.78

    # Barrel Camera
    bpy.ops.object.camera_add(location=(6, 0, 0), rotation=(0, 1.5708, 0))
    #bpy.context.object.rotation_euler[1] = 1.5708
    bpy.context.object.name = "BarrelCamera"


# Function that creates Blender Objects from input list of particles.
## Returns a list of blender objects
def create(particles):
    particle_types = ["Electron","Pion","Muon","Proton","Kaon"]
    clRed = (1, 0, 0)
    clGreen = (0, 1, 0)
    clBlue = (0, 0, 1)
    clMagenta = (0.75, 0, 1)
    clYellow = (1, 1, 0)
    particle_colors = {"Electron":clRed, "Pion":clGreen, "Muon":clBlue, "Proton":clMagenta, "Kaon": clYellow}

    blender_particles=[]

    #Create Materials
    for type in particle_types:
        bpy.data.materials.new(name=type)
        #bpy.context.object.active_material = (1, 0, 0)
        bpy.data.materials[type].diffuse_color = particle_colors[type]
        bpy.data.materials[type].use_shadows = False
        bpy.data.materials[type].use_cast_shadows = False

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
def animate(objects, particles):
    #Animate particles
    for f in range(1, bcs.frame_end):
        t=delta_t*f
        bcs.frame_current = f
        print("Configuring Frame: "+str(f)+" of "+str(bcs.frame_end))
        for i in range(0, len(objects)):
            bcs.objects.active=objects[i]
            objects[i].location=(particles[i].Propagate(t))
            objects[i].keyframe_insert(data_path='location')
