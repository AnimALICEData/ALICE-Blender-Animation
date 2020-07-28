# -*- coding: utf-8 -*-
# animate_particles.py - Animate HEP events
#
#   For console only rendering (example):
#   $ blender -noaudio --background -P animate_particles.py -- -cam "OverviewCamera" -datafile "Run139038_Orbit7548473_BunchCross1534_2.dat" \
#   -n_event 2 -pic_pct 30 -output_path "/home"
#

import bpy

import argparse
import sys

# Pass on command line arguments to script:
class ArgumentParserForBlender(argparse.ArgumentParser):
    def _get_argv_after_doubledash(self):
        try:
            idx = sys.argv.index("--")
            return sys.argv[idx+1:] # the list after '--'
        except ValueError as e: # '--' not in the list:
            return []

    # overrides superclass
    def parse_args(self):
        return super().parse_args(args=self._get_argv_after_doubledash())

parser = ArgumentParserForBlender()

parser.add_argument('-cam','--render_cam')
parser.add_argument('-datafile','--datafile')
parser.add_argument('-n_event','--n_event')
parser.add_argument('-pic_pct','--pic_pct')
parser.add_argument('-output_path','--output_path')

args = parser.parse_args()

render_cam = str(args.render_cam)
datafile = str(args.datafile)
n_event = str(args.n_event)
pic_pct = int(args.pic_pct)

outputPath = str(args.output_path)+"/"
fileIdentifier = "PhysicalTrajectories_"


bpy.ops.wm.open_mainfile(filepath=outputPath+fileIdentifier+"AlirootFileGenerator_"+datafile+"_Event_"+n_event+".blend")

bcs = bpy.context.scene

# Set specific output info
output_prefix = "PhysicalTrajectories_1920px_AlirootFileGenerator_"+datafile+"_Event_"+n_event+"_"+render_cam
bcs.render.filepath = outputPath+output_prefix
bcs.camera = bpy.data.objects[render_cam]

# Take picture of animation
bcs.frame_current = int(bcs.frame_end * pic_pct/100)
bpy.ops.render.render()
bpy.data.images['Render Result'].save_render(filepath=bcs.render.filepath+".png")

# Render actual animation
bpy.ops.render.render(animation=True)
