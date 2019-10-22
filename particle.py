# -*- coding: utf-8 -*-
# Sample Particle class and function that creates N particles, returning a list of particles
import math
import random

# Basic particle class to store bascic information
class Particle:
    def __init__(self, index, x = 0, y = 0, z = 0, charge = 1, mass=1):
        self.iDx=index
        self.x=x
        self.y=y
        self.z=z
        self.charge=charge
        self.mass = mass
    def PrintPosition(self):
        print(str(self.x) + " ; " + str(self.y) + " ; " + str(self.z))
    def GetPosition(self):
        return self.x, self.y, self.z

#Function that creates N particles and return them in a list
def createNparticles(N_particles, x = 0, y = 0, z = 0):  # Create particles at given position and return them in a list
    particles=[]
    #loop over particles
    for i in range(0, N_particles):
        part = Particle(i,x,y,z)
        particles.append(part)
    return particles;

# Derived class to computes the time evolution particle positions
class ParticlePropagator(Particle):
    def SetMagneticField(self,B):
        self.B = B
    def SetMomentum(self,Px, Py, Pz):
        self.Px = Px
        self.Py = Py
        self.Pz = Pz
    def Propagate(self, time): # Todo: Add relativistic and magnetic field effects
        Xprop = self.x + time*self.Px/self.mass
        Yprop = self.y + time*self.Py/self.mass
        Zprop = self.z + time*self.Pz/self.mass
        return Xprop, Yprop, Zprop

# Function that creates N particle propagators
#   Momentum values to be obtained from real data
def createNparticlesProp(N_particles, x = 0, y = 0, z = 0):  # Create particles at given position and return them in a list
    particles=[]
    #loop over particles
    for i in range(0, N_particles):
        part = ParticlePropagator(i,x,y,z)
        part.SetMagneticField(0.5)
        part.SetMomentum(random.gauss(0,1),random.gauss(0,1),random.gauss(0,1))
        particles.append(part)
    return particles;
