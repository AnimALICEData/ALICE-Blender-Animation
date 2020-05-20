# Import Blender functions
filename = os.path.join(os.path.basename(bpy.data.filepath), "blender_functions.py")
exec(compile(open(filename).read(), filename, 'exec'))

def init(unique_id,camera_type,transp_par,detectors):
    bcs = bpy.context.scene

    # Configure Environment
    bcs.world.light_settings.use_environment_light = False
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
    bpy.data.objects.remove(bpy.data.objects['Lamp'])

    # Basic Objects
    addCameras() # Add cameras

    if camera_type == "OverviewCamera":
        addOverviewLamps()
    else:
        addLamps() # Add Lamps

    if camera_type == "ForwardCamera":
        addALICE_Geometry(True,transp_par,detectors) # ALICE TPC, EMCal, ITS, TRD
    else:
        addALICE_Geometry(False,transp_par,detectors)

def addALICE_Geometry(bright_colors=True, transp_par=1.0, detectors=[1,1,1,1]):

    if bright_colors: # Defining sequence of RGB values to fill 'createMaterial' functions below
        rgb_v = [13,13,25,10] # Colors for "ForwardCamera"
    else:
        rgb_v = [0.5,0.9,1,0.2] # Colors for "OverviewCamera" and "BarrelCamera"


    # ADD ITS
    if detectors[0]:

        # ADD ITS INNER BARREL

        # Material
        createMaterial("innerITS",R=rgb_v[2],G=0,B=rgb_v[2],shadows=False,cast_shadows=False,transparency=True,alpha=transp_par*0.7,emit=0,specular_alpha=0,fresnel_factor=5,fresnel=0.3)

        # Add Inner ITS
        bpy.ops.mesh.primitive_cylinder_add(radius=0.0421, depth=0.271, view_align=False, enter_editmode=False, location=(0, 0, 0))
        inner_TPC = bpy.context.object
        inner_TPC.name = "innerITS"

        # Set Material
        inner_TPC.data.materials.clear()
        inner_TPC.data.materials.append(bpy.data.materials["innerITS"])


        # ADD ITS OUTER BARREL

        # Material
        createMaterial("outerITS",R=rgb_v[3],G=0,B=rgb_v[3],shadows=False,cast_shadows=False,transparency=True,alpha=transp_par*0.4,emit=0.8,specular_alpha=0,fresnel_factor=5,fresnel=0.3)

        # ADD ITS MIDDLE LAYERS

        # Add "hole" to subtract from the middle
        bpy.ops.mesh.primitive_cylinder_add(radius=0.1944, depth=0.9, view_align=False, enter_editmode=False, location=(0, 0, 0)) #smaller cylinder
        middle_ITS_hole = bpy.context.object
        middle_ITS_hole.name = "Hole"

        # Add actual middle layer ITS part
        bpy.ops.mesh.primitive_cylinder_add(radius=0.247, depth=0.843, view_align=False, enter_editmode=False, location=(0, 0, 0)) #bigger cylinder
        middle_ITS = bpy.context.object
        middle_ITS.name = "middleITS"

        # Subtract hole from main TPC part
        subtract(middle_ITS_hole,middle_ITS)

        # Set material
        middle_ITS.data.materials.clear()
        middle_ITS.data.materials.append(bpy.data.materials["outerITS"])


        # ADD ITS OUTER LAYERS

        # Add "hole" to subtract from the middle
        bpy.ops.mesh.primitive_cylinder_add(radius=0.3423, depth=1.5, view_align=False, enter_editmode=False, location=(0, 0, 0)) #smaller cylinder
        outer_ITS_hole = bpy.context.object
        outer_ITS_hole.name = "Hole"

        # Add actual outer layer ITS part
        bpy.ops.mesh.primitive_cylinder_add(radius=0.3949, depth=1.475, view_align=False, enter_editmode=False, location=(0, 0, 0)) #bigger cylinder
        outer_ITS = bpy.context.object
        outer_ITS.name = "outerITS"

        # Subtract hole from main TPC part
        subtract(outer_ITS_hole,outer_ITS)

        # Set material
        outer_ITS.data.materials.clear()
        outer_ITS.data.materials.append(bpy.data.materials["outerITS"])

        # Make ITS middle and outer layers a single object
        joinObjects([middle_ITS,outer_ITS])
        Outer_ITS = bpy.context.object
        Outer_ITS.name = "OuterITS"

    # ADD TPC
    if detectors[1]:

        # Material
        createMaterial("tpc",R=0,G=rgb_v[0],B=0,shadows=False,cast_shadows=False,transparency=True,alpha=transp_par*0.2,emit=0.3,specular_alpha=0,fresnel_factor=5,fresnel=0.3)

        # Add TPC
        bpy.ops.mesh.primitive_cylinder_add(radius=2.461, depth=5.1, view_align=False, enter_editmode=False, location=(0, 0, 0)) #bigger cylinder
        TPC = bpy.context.object
        TPC.name = "TPC"

        # Set material
        TPC.data.materials.clear()
        TPC.data.materials.append(bpy.data.materials["tpc"])

    # ADD ALICE TRD
    if detectors[2]:

        # Material
        createMaterial("TRD",R=rgb_v[3],G=0,B=rgb_v[3],shadows=False,cast_shadows=False,transparency=True,alpha=transp_par*0.15,emit=0.8,specular_alpha=0,fresnel_factor=5,fresnel=0.3)

        # Add "hole" to subtract from the middle
        bpy.ops.mesh.primitive_cylinder_add(radius=2.9, depth=6, vertices=18, view_align=False, enter_editmode=False, location=(0, 0, 0)) #smaller cylinder
        TRD_hole = bpy.context.object
        TRD_hole.name = "Hole"

        # Add actual TRD part
        bpy.ops.mesh.primitive_cylinder_add(radius=3.7, depth=5.1, vertices=18, view_align=False, enter_editmode=False, location=(0, 0, 0)) #bigger cylinder
        TRD = bpy.context.object
        TRD.name = "TRD"

        # Subtract hole from main TRD part
        subtract(TRD_hole,TRD)

        # Set material
        TRD.data.materials.clear()
        TRD.data.materials.append(bpy.data.materials["TRD"])

        # Add 'slices' to subtract from TRD structure
        bpy.ops.mesh.primitive_cube_add(radius=1, location=(2.855942,0.50358,0))
        slice = bpy.context.object
        slice.name = "slice"
        bpy.ops.transform.resize(value=(1,0.03,4))
        bpy.context.object.rotation_euler[2] = 0.174533
        subtract(slice,TRD)

        def rad(theta): # Convert degrees to radians
            return theta * math.pi / 180

        xn = 2.9 * math.cos(rad(10))
        yn = 2.9 * math.sin(rad(10))

        for n in range(1,18):

            dx = -2 * 2.9 * math.sin(rad(10)) * math.sin(rad(n * 20))
            xn += dx

            dy = 2 * 2.9 * math.sin(rad(10)) * math.cos(rad(n * 20))
            yn += dy

            rotat = rad(10 + n*20)

            bpy.ops.mesh.primitive_cube_add(radius=1, location=(xn,yn,0))
            slice = bpy.context.object
            slice.name = "slice"
            bpy.ops.transform.resize(value=(1,0.03,4))
            bpy.context.object.rotation_euler[2] = rotat

            subtract(slice,TRD)

    # ADD EMCal
    if detectors[3]:

        # Material
        createMaterial("emcal",R=rgb_v[1],G=rgb_v[1],B=0,shadows=False,cast_shadows=False,transparency=True,alpha=transp_par*0.05,emit=1.5,specular_alpha=0,fresnel_factor=5,fresnel=0.3)

        # Add cylinder for EMCal
        bpy.ops.mesh.primitive_cylinder_add(radius=4.7, depth=5.1, vertices=19, view_align=False, enter_editmode=False, location=(0, 0, 0))
        EMCal = bpy.context.object
        EMCal.name = "EMCal"

        # Add cylinder to be removed from center
        bpy.ops.mesh.primitive_cylinder_add(radius=4.35, depth=5.2, vertices=19, view_align=False, enter_editmode=False, location=(0, 0, 0))
        emcal_hole = bpy.context.object
        emcal_hole.name = "Hole"

        subtract(emcal_hole,EMCal);

        # Adds rotated cube to be removed from EMCal so that there's a 7.3° angle with top y axis, clockwise
        bpy.ops.mesh.primitive_cube_add(location=(2.85,2.2,0), rotation=(0,0,-0.1274), radius=2.55)
        bpy.ops.transform.resize(value=(1.5,1.5,1.5), constraint_axis=(False,False,True))
        cube1 = bpy.context.object # first quadrant
        subtract(cube1,EMCal)

        # Adds rotated cube to be removed from EMCal so that there's a 9.7° angle with left x axis, anticlockwise
        bpy.ops.mesh.primitive_cube_add(location=(-2.08,-2.95,0), rotation=(0,0,0.1693), radius=2.55)
        bpy.ops.transform.resize(value=(1.5,1.5,1.5), constraint_axis=(False,False,True))
        cube3 = bpy.context.object # third quadrant
        subtract(cube3,EMCal)

        #Adds cube with right angle in fourth quadrant to be removed from EMCal
        bpy.ops.mesh.primitive_cube_add(location=(2.55,-2.55,0), radius=2.55)
        bpy.ops.transform.resize(value=(1.5,1.5,1.5), constraint_axis=(False,False,True))
        cube4 = bpy.context.object # fourth quadrant
        subtract(cube4,EMCal)

        # Set Material
        EMCal.data.materials.clear()
        EMCal.data.materials.append(bpy.data.materials["emcal"])


def addLamps():
    bpy.ops.object.lamp_add(type='POINT', location=(4,1,6))
    bpy.ops.object.lamp_add(type='POINT', location=(-4,-1,-6))

def addOverviewLamps():
    bpy.ops.object.lamp_add(type='POINT', location=(0,0,6))

def addCameras():
    # ForwardCamera
    bpy.ops.object.camera_add(location = (0,0.5,20), rotation = (0, 0, 0))
    bpy.context.object.name = "ForwardCamera"
    camera_forward=bpy.data.objects['ForwardCamera']
    camera_forward.data.type = 'ORTHO'
    camera_forward.data.ortho_scale = 18

    # OverviewCamera
    bpy.ops.object.camera_add(location = (23.27182, 10.3968, 22.754), rotation = (-0.071558, 0.879645, 0.305433))
    bpy.context.object.name = "OverviewCamera"
    bpy.context.object.data.lens = 66.78

    # Barrel Camera
    bpy.ops.object.camera_add(location = (6, 0, 0), rotation = (0, 1.5708, 0))
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

    # Create Materials
    for type in particle_types:
        bpy.data.materials.new(name=type)
        #bpy.context.object.active_material = (1, 0, 0)
        bpy.data.materials[type].emit = 0.05
        bpy.data.materials[type].diffuse_color = particle_colors[type]
        bpy.data.materials[type].use_shadows = False
        bpy.data.materials[type].use_cast_shadows = False

    # Create blender spheres (particles)
    blender_particles=[]
    n_particles=len(particles)
    for particle in particles:
        this_type=particle.p_type
        print("Adding Sphere - Particle " + str(len(blender_particles)+1)+" of "+str(n_particles)+" - "+this_type)
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
                this_type=track.p_type
                print("Adding Curve - Track " + str(len(blender_tracks)+1)+" of "+str(n_particles)+" - "+this_type)

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
    for f in range(1, bcs.frame_end+1):
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
    for f in range(1, bcs.frame_end+1):
        t = driver.delta_t*f
        bcs.frame_current = f
        print("Configuring tracks in frame: "+ str(f) +" of "+ str(bcs.frame_end))
        for point in range(f,bcs.frame_end+1):
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

def take_picture(pic_pct,driver):
    bcs = bpy.context.scene

    bcs.frame_current = int(bcs.frame_end * pic_pct/100)
    bcs.camera = bpy.data.objects[driver.renderCamera]
    bpy.ops.render.render()
    bpy.data.images['Render Result'].save_render(filepath=bcs.render.filepath+".png")
