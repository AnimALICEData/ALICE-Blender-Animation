# -*- coding: utf-8 -*-
# particulas.py - Protótipo de animação de partículas
# Para utilizar este script chame o blender com a opção -P e o nome do arquivo
#
#   $ blender -P ./particulas.py

import bpy
import math

bpy.context.user_preferences.view.show_splash = False

t_video=10 # duração da animação em segundos
t_simulado=86400*365*5 # tempo próprio da simulação em segundos
fps = 24 # quadros por segundo
N_quadros=t_video*fps # calculando numero de quadros totais
delta_t=t_simulado/N_quadros # tempo passado por quadro

r_part = 0.1
particulas=[] #lista que armazena as partículas da cena

def criaNparticulas_origem(N_particulas):  # Cria partículas na origem e adiciona em uma lista
    #Inicia limpando a cena - ATENÇÃO - apaga todos os objetos!!
    for objeto in bpy.data.objects:
        bpy.data.objects.remove(objeto)
    #loop sobre as partículas
    for i in range(0, N_particulas):
        bpy.ops.mesh.primitive_uv_sphere_add()
        part = bpy.context.object
        part.name = "part"+str(i)
        part.location=((0,0,0))
        part.delta_scale=(r_part,r_part,r_part)
        particulas.append(part)


def run():
    bpy.context.scene.render.fps=fps
    bpy.context.scene.frame_start = 0
    bpy.context.scene.frame_end = N_quadros
    for f in range(1, N_quadros):
        t=delta_t*f
        bpy.context.scene.frame_current = f
        for i in range(0, len(particulas)):
            bpy.context.scene.objects.active=particulas[i]
            particulas[i].location=(0.01*f,0.05*i,0.0000005*i*i*f*f) # Dummy positions
            particulas[i].keyframe_insert(data_path='location')


criaNparticulas_origem(30)
run()
