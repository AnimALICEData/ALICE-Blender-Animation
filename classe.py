# -*- coding: utf-8 -*-
# Exemplo de classe de partícula e criação de N elementos em uma lista

class Particula:
    def __init__(self, x = 0, y = 0, z = 0):
        self.x=x
        self.y=y
        self.z=z

def criaNparticulas_origem(N_particulas):  # Cria partículas na origem
    particulas=[]
    for i in range(1, N_particulas):
        part = Particula() # Cria todas na origem
        particulas.append(part)
    return particulas;


def criaNparticulas(N_particulas, x, y, z):  # Cria partículas na posição fornecida
    particulas=[]
    for i in range(1, N_particulas):
        part = Particula(x, y, z)
        particulas.append(part)
    return particulas;


particulas1 = criaNparticulas_origem(10)
particulas2 = criaNparticulas(10, 1, 2, 3)

indice = 0
print("particulas1:")
for particula in particulas1:
    print(str(indice) + "; " + str(particula.x) +" ; "+ str(particula.y) + " ; " +str(particula.z))
    indice+=1

print("particulas2:")
indice = 0
for particula in particulas2:
    print(str(indice) + "; " + str(particula.x) +" ; "+ str(particula.y) + " ; " +str(particula.z))
    indice+=1
