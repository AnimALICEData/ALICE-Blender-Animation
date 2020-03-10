
def init(unique_id):
    bcs = bpy.context.scene

    # Configure Environment
    bcs.world.light_settings.use_environment_light = False # True ??
    bcs.world.light_settings.environment_energy = 0.1

    # Configure Stamp
    bcsr = bpy.context.scene.render
    bcsr.use_stamp = True
    bcsr.use_stamp_time = False
    bcsr.use_stamp_date = False
    bcsr.use_stamp_render_time = False
    bcsr.use_stamp_frame = False
    bcsr.use_stamp_scene = False
    bcsr.use_stamp_camera = False
    bcsr.use_stamp_filename = False
    bcsr.stamp_note_text = unique_id
    bcsr.use_stamp_note = True

    # Cleanup
    bpy.data.objects.remove(bpy.data.objects['Cube'])
    bpy.data.objects.remove(bpy.data.objects['Camera'])
    #bpy.data.objects.remove(bpy.data.objects['Lamp'])

    # Basic Objects
    addCameras() # Add cameras
    addALICE_TPC() # ALICE TPC

def addALICE_TPC():

    print("Adding ALICE TPC")

    # Add big cube to subtract from TPC
    bpy.ops.mesh.primitive_cube_add(location=(5.1,-5.1,0), radius=5.1)
    bpy.context.object.name = "BigCube"

    # ADD OUTER TPC

    # Material
    bpy.data.materials.new(name="outerTPC")
    bpy.data.materials["outerTPC"].diffuse_color = (0, 255, 0) # Green
    bpy.data.materials["outerTPC"].use_shadows = False
    bpy.data.materials["outerTPC"].use_cast_shadows = False
    bpy.data.materials["outerTPC"].use_transparency = True
    bpy.data.materials["outerTPC"].alpha = 0.1
    bpy.data.materials["outerTPC"].specular_alpha = 0
    bpy.data.materials["outerTPC"].raytrace_transparency.fresnel_factor = 5
    bpy.data.materials["outerTPC"].raytrace_transparency.fresnel = 0.3

    # Add "hole" to subtract from the middle
    bpy.ops.mesh.primitive_cylinder_add(radius=1.346, depth=6, view_align=False, enter_editmode=False, location=(0, 0, 0)) #smaller cylinder
    outer_TPC_hole = bpy.context.object
    outer_TPC_hole.name = "Hole"

    # Add actual Outer TPC part
    bpy.ops.mesh.primitive_cylinder_add(radius=2.461, depth=5.1, view_align=False, enter_editmode=False, location=(0, 0, 0)) #bigger cylinder
    outer_TPC = bpy.context.object
    outer_TPC.name = "outerTPC"

    # Subtract hole from main TPC part
    bpy.ops.object.modifier_add(type='BOOLEAN')
    bpy.context.object.modifiers["Boolean"].operation = 'DIFFERENCE'
    bpy.context.object.modifiers["Boolean"].object = bpy.data.objects["Hole"]
    bpy.ops.object.modifier_apply(apply_as='DATA', modifier="Boolean")
    bpy.ops.object.select_all(action='DESELECT')
    bpy.data.objects["Hole"].select = True
    bpy.ops.object.delete()

    # Set material
    outer_TPC.data.materials.clear()
    outer_TPC.data.materials.append(bpy.data.materials["outerTPC"])



    # ADD INNER TPC

    # Material
    bpy.data.materials.new(name="innerTPC")
    bpy.data.materials["innerTPC"].diffuse_color = (0, 102, 255) # Blue
    bpy.data.materials["innerTPC"].use_shadows = False
    bpy.data.materials["innerTPC"].use_cast_shadows = False
    bpy.data.materials["innerTPC"].use_transparency = True
    bpy.data.materials["innerTPC"].alpha = 0.1
    bpy.data.materials["innerTPC"].specular_alpha = 0
    bpy.data.materials["innerTPC"].raytrace_transparency.fresnel_factor = 5
    bpy.data.materials["innerTPC"].raytrace_transparency.fresnel = 0.3

    # Add Inner TPC
    bpy.ops.mesh.primitive_cylinder_add(radius=1.321, depth=5.1, view_align=False, enter_editmode=False, location=(0, 0, 0))
    inner_TPC = bpy.context.object
    inner_TPC.name = "innerTPC"

    # Set Material
    inner_TPC.data.materials.clear()
    inner_TPC.data.materials.append(bpy.data.materials["innerTPC"])



    # Make TPC one single object = inner + outer
    bpy.data.objects["outerTPC"].select = True
    bpy.ops.object.join()
    TPC = bpy.context.object
    TPC.name = "TPC"

    # Make TPC active object again
    bpy.context.scene.objects.active = TPC

    # Delete Big Cube
    bpy.ops.object.select_all(action='DESELECT')
    bpy.data.objects["BigCube"].select = True
    bpy.ops.object.delete()

def addCameras():
    # ForwardCamera
    bpy.ops.object.camera_add(location = (0,0,20), rotation = (0, 0, 0))
    bpy.context.object.name = "ForwardCamera"
    camera_forward=bpy.data.objects['ForwardCamera']
    camera_forward.data.type = 'ORTHO'
    camera_forward.data.ortho_scale = 10

    # OverviewCamera
    bpy.ops.object.camera_add(location = (6.98591, -19.7115, 23.9696), rotation = (-0.281366, 0.683857, -1.65684))
    bpy.context.object.name = "OverviewCamera"
    bpy.context.object.data.lens = 66.78

    # Barrel Camera
    bpy.ops.object.camera_add(location = (6, 0, 0), rotation = (0, 1.5708, 0))
    #bpy.context.object.rotation_euler[1] = 1.5708
    bpy.context.object.name = "BarrelCamera"

# Function that creates Blender Objects from input list of particles.
## Returns a list of blender objects
def createSceneParticles(particles, createTracks = False):
    # Associate particles and colors
    particle_types = ["Electron","Pion","Muon","Proton","Kaon","Unknown"]
    clRed = (1, 0, 0)
    clGreen = (0, 1, 0)
    clBlue = (0, 0, 1)
    clMagenta = (0.75, 0, 1)
    clYellow = (1, 1, 0)
    clWhite = (255, 255, 255)
    particle_colors = {"Electron":clRed, "Pion":clGreen, "Muon":clBlue, "Proton":clMagenta, "Kaon": clYellow, "Unknown": clWhite}

    #Create Materials
    for type in particle_types:
        bpy.data.materials.new(name=type)
        #bpy.context.object.active_material = (1, 0, 0)
        bpy.data.materials[type].diffuse_color = particle_colors[type]
        bpy.data.materials[type].use_shadows = False
        bpy.data.materials[type].use_cast_shadows = False

    # Create blender spheres (particles)
    blender_particles=[]
    n_particles=len(particles)
    for particle in particles:
        this_type=particle.p_type
        print("Adding Sphere - Particle " + str(len(blender_particles))+" of "+str(n_particles-1)+" - "+this_type)
        bpy.ops.mesh.primitive_uv_sphere_add()
        bpy.ops.object.shade_smooth()
        this_particle = bpy.context.object
        this_particle.name = "part"+str(particle.iDx)
        this_particle.location = ((particle.x,particle.y,particle.z))
        this_particle.delta_scale = (r_part,r_part,r_part)
        this_particle.data.materials.clear()
        this_particle.data.materials.append(bpy.data.materials[this_type])
        blender_particles.append(this_particle)

    # Create blender curves (tracks)
    blender_tracks=[]
    if createTracks:
            for track in particles:
                this_type=track.p_type #TO DO: make this not random, but according to file data
                print("Adding Curve - Track " + str(len(blender_tracks))+" of "+str(n_particles-1)+" - "+this_type)

                # create the Curve Datablock
                curveTrack = bpy.data.curves.new('CurveTrack', type='CURVE')
                curveTrack.dimensions = '3D'
                curveTrack.resolution_u = 2

                curveTrack.fill_mode = 'FULL'
                curveTrack.bevel_depth = 0.02
                curveTrack.bevel_resolution = 3


                # map coords to spline
                bcs = bpy.context.scene
                polyline = curveTrack.splines.new('NURBS')
                polyline.points.add(bcs.frame_end) # Add one point per frame
                for i in range(bcs.frame_end):
                    polyline.points[i].co = (particle.x,particle.y,particle.z, 1)

                # create Object
                trackOB = bpy.data.objects.new('Track', curveTrack)
                trackOB.data.materials.clear()
                trackOB.data.materials.append(bpy.data.materials[this_type])
                scn = bpy.context.scene
                scn.objects.link(trackOB)
                blender_tracks.append(trackOB)


    return blender_particles, blender_tracks

# Function that animates the scene using the particle propagator class
def animate(objects, particles, driver):
    bcs = bpy.context.scene

    #Animate particles
    for f in range(1, bcs.frame_end):
        t = driver.delta_t*f
        bcs.frame_current = f
        print("Configuring particles in frame: "+str(f)+" of "+str(bcs.frame_end))
        for i in range(0, len(objects)):
            bcs.objects.active=objects[i]
            objects[i].location=(particles[i].Propagate(t))
            objects[i].keyframe_insert(data_path='location')

# Function that animates particle tracks using the particle propagator class
def animate_tracks(tracks, particles, driver):
    bcs = bpy.context.scene

    #Animate tracks
    for f in range(1, bcs.frame_end):
        t = driver.delta_t*f
        bcs.frame_current = f
        print("Configuring tracks in frame: "+ str(f) +" of "+ str(bcs.frame_end))
        for point in range(f,bcs.frame_end):
            for i in range(0, len(particles)):
                #bcs.objects.active=tracks[i]
                tracks[i].data.splines[0].points[point].keyframe_insert(data_path="co", frame = f)
                x, y, z = particles[i].Propagate(t)
                tracks[i].data.splines[0].points[point].co = (x, y, z, 1)



                ##polyline = curveTrack.splines.new('NURBS')
                ##polyline.points.add(len(coords))
                ##for i, coord in enumerate(coords):
                ##    x,y,z = coord
                ##    polyline.points[i].co = (x, y, z, 1)

                #curve = bpy.data.objects["Track"]
                #curve.data.splines[0].points[1].co


                #point.keyframe_insert(data_path="co", frame = i)
                # https://blender.stackexchange.com/questions/73630/animate-curves-by-changing-spline-data-using-a-python-script
