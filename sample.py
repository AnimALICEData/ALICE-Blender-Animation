# -*- coding: utf-8 -*-

from particle import *

# Creates one particle propagator with default values
a = ParticlePropagator(0)
a.PrintPosition()

# Configure kinematics
a.SetMagneticField(0.5)
a.SetMomentum(-1.0, 2.0, 3.0)

#Print propagation
print(a.Propagate(1))
print(a.Propagate(2))
print(a.Propagate(3))
print(a.Propagate(3)[0]*2) #Acessing a single element of the result
