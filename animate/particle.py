# -*- coding: utf-8 -*-
# Sample Particle class and function that creates N particles, returning a list of particles
import math
import random

# Basic particle class to store bascic information
class Particle:
    def __init__(self, index, x = 0, y = 0, z = 0, charge = 1, mass=0.94):
        self.iDx=index
        self.x=x
        self.y=y
        self.z=z
        self.charge=charge
        self.mass = mass
    def SetType(self):
        p_mass = {"Electron":0.000510999, "Pion":0.13957, "Muon":0.105658, "Proton":0.938272, "Kaon":0.493677}
        self.p_type = "Unknown"
        for p_type in p_mass:
            if p_mass[p_type] == self.mass:
                self.p_type = p_type
    def PrintPosition(self):
        print(str(self.x) + " ; " + str(self.y) + " ; " + str(self.z))
    def GetPosition(self):
        return self.x, self.y, self.z


# Derived class to computes the time evolution particle positions
class ParticlePropagator(Particle):
    def SetMagneticField(self, B = 0.5):
        self.B = B
    def SetProperties(self, Px, Py, Pz):
        self.Px = Px # unit: Gev/c
        self.Py = Py # unit: Gev/c
        self.Pz = Pz # unit: Gev/c
        self.Velocity = 1/math.sqrt(1+self.mass*self.mass/(Px*Px+Py*Py+Pz*Pz)) # unit: []c
        self.LorentzFactor = 1 / math.sqrt( 1 - self.Velocity * self.Velocity )
        self.Vz = 300 * Pz / self.LorentzFactor / self.mass # unit: meters/micro seconds
    def Propagate(self, time):
        Rx = self.Px / (self.charge * self.B) * 3.335641 # unit conversion to meters
        Ry = self.Py / (self.charge * self.B) * 3.335641 # unit conversion to meters
        omega = self.charge * self.B / ( self.LorentzFactor * self.mass ) * 89.876 # Angular frequency (unit: radians/micro seconds)
        Xprop = self.x + Rx * math.sin(omega*time) - Ry * ( math.cos(omega*time) - 1 )
        Yprop = self.y + Ry * math.sin(omega*time) + Rx * ( math.cos(omega*time) - 1 )
        Zprop = self.z + self.Vz * time
        return Xprop, Yprop, Zprop
