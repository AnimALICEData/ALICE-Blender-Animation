# -*- coding: utf-8 -*-

# Import Particle class
filename = os.path.join(os.path.basename(bpy.data.filepath), "particle.py")
exec(compile(open(filename).read(), filename, 'exec'))
# Import scene functions
filename = os.path.join(os.path.basename(bpy.data.filepath), "scene_functions.py")
exec(compile(open(filename).read(), filename, 'exec'))


class animationDriver:
    def __init__(self,name):
        self.name = name
    def configure(self, renderCamera, duration, fps, simulated_t, outputPath, fileIdentifier, resolution_percent=100):
        self.renderCamera=renderCamera
        self.duration=duration  # total video duration in seconds
        self.fps=fps
        self.simulated_t=simulated_t # total simulated time in microseconds. (0.01 -> light travels ~ 3 m)
        self.N_frames=duration*fps
        self.delta_t=self.simulated_t/self.N_frames # time elapsed per frame
        self.outputPath = outputPath
        self.fileIdentifier = fileIdentifier
        self.resolution_percent = resolution_percent
        self.configureOutput()
        bcs = bpy.context.scene
        bcs.frame_start = 0
        bcs.frame_end = self.N_frames

    def render(self):
        bpy.context.scene.camera = bpy.data.objects[self.renderCamera]
        bpy.ops.render.render(animation=True)

    def configureOutput(self):
        # Configure Output
        bcsr = bpy.context.scene.render
        bcsr.fps=self.fps
        bcsr.resolution_percentage = self.resolution_percent
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
        output_prefix=self.fileIdentifier+str(xpixels)+"px_"+self.name+self.renderCamera
        bcsr.filepath = "/tmp/alice_blender/"+output_prefix

class genDriver(animationDriver): # A driver for particle generators
    def __init__(self,name,N_particles, par1):
        self.name = name+"_N"+str(n_particles)+"_"
        self.N_particles = N_particles
        self.par1 = par1
    def getParticles(self, x = 0, y = 0, z = 0):  # Create particles at given position and return them in a list
        particles=[]
        #loop over particles
        for i in range(0, self.N_particles):
            charge =  random.choice([+1,-1])
            mass = random.choice([0.000510999, 0.13957, 0.105658, 0.938272, 0.493677]) # Available mass values
            part = ParticlePropagator(i,x,y,z,charge,mass)
            part.SetType()
            part.SetMagneticField()
            part.SetProperties(random.gauss(0,self.par1),random.gauss(0,self.par1),random.gauss(0,self.par1))
            particles.append(part)
        return particles;

class dataDriver(animationDriver): # A driver for data from files.
    def __init__(self,name,nEvent,datafile):
        self.name = name+"_"+datafile+"_Event_"+nEvent+"_"
        self.datafile = datafile
    def getParticles(self):  # Create particles acording to parameters from file
        # Count number of lines in file = number of particles
        detail_file = open(self.datafile, 'r')
        lines = detail_file.readlines()
        N_particles = len(lines)
        # Create particles list
        particles=[]
        #loop over particles and get information from data file
        for i in range(0, N_particles):
            x = lines[i].split(' ')[0]
            y = lines[i].split(' ')[1]
            z = lines[i].split(' ')[2]
            mass = lines[i].split(' ')[3]
            charge = lines[i].split(' ')[4]
            Px = lines[i].split(' ')[5]
            Py = lines[i].split(' ')[6]
            Pz = lines[i].split(' ')[7]
            part = ParticlePropagator(i,float(x),float(y),float(z),float(charge),float(mass))
            part.SetType()
            part.SetMagneticField(0.5)
            part.SetProperties(float(Px),float(Py),float(Pz))
            particles.append(part)
        detail_file.close()
        return particles;
