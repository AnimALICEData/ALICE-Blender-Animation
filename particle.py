# -*- coding: utf-8 -*-
# Sample Particle class and function that creates N particles, returning a list of particles

class Particle:
    def __init__(self, index, x = 0, y = 0, z = 0):
        self.iDx=index
        self.x=x
        self.y=y
        self.z=z


def createNparticles(N_particles, x=0, y=0, z=0):  # Create particles at given position and return them in a list
    particles=[]
    #loop sobre as partículas
    for i in range(0, N_particles):
        part = Particle(i,x,y,z)
        particles.append(part)
    return particles;
