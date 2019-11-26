#!/bin/bash

##############################
# Configurations             #
##############################
# Put aliBuild in the PATH env var
export PATH="/mnt/SSD/schnorr/python/bin:$PATH"
# Directory where runAnalysis.C is placed
export ALIROOT_SCRIPT_DIR=$(pwd)/aliRoot/
# Directory where blender scripts are
export BLENDER_SCRIPT_DIR=$(pwd)/animate/
# Directory where output animations should be placed
export BLENDER_OUTPUT=$(pwd)/output/
# alienv working directory
export ALIENV_WORK_DIR=/mnt/SSD/schnorr/ALICE/sw/
export ALIENV_ID=AliPhysics/latest-aliroot5-user
# Put blender 2.79b in the PATH env var
export PATH="/home/schnorr/install/blender-2.79-linux-glibc219-x86_64/:$PATH"

##############################
# Usage                      #
##############################
function usage()
{
    echo "$0 <URL> <DOWNLOAD>";
    echo "  where <URL> is a URL to uniquely identify a dataset";
    echo "  where <DOWNLOAD> is true or false, indicate whether the dataset should be downloaded";
}

##############################
# Parse Parameters           #
##############################
URL=$1
if [ -z $URL ]; then
    echo "Error. Must pass the dataset URL."
    usage
    exit
fi

DOWNLOAD=$2
if [ -z $DOWNLOAD ]; then
    echo "Error. Must explicitely inform whether to download the dataset or not."
    usage
    exit
fi

##############################
# Download Dataset           #
##############################
if [ "$DOWNLOAD" = "true" ]; then
    echo "Downloading data."
    wget $URL
fi
# Verify if AliESDs.root is here
ALIESD_ROOT_FILE=$(pwd)/AliESDs.root

##############################
# Phase 1: aliroot extract   #
##############################
eval $(alienv -w ${ALIENV_WORK_DIR} -a ubuntu1604_x86-64 load ${ALIENV_ID})
pushd ${ALIROOT_SCRIPT_DIR}
rm --verbose AliESDs.root
ln --verbose -s $ALIESD_ROOT_FILE AliESDs.root
aliroot runAnalysis.C
for type in s m l; do
    ls -lh ${type}-esd-detail.dat
done
popd

##############################
# Phase 2: blender animate   #
##############################
for type in s m l; do
  mv --verbose ${ALIROOT_SCRIPT_DIR}/${type}-esd-detail.dat ${BLENDER_SCRIPT_DIR}
done
pushd ${BLENDER_SCRIPT_DIR}
blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=10 -camera="BarrelCamera" -datafile="d-esd-detail.dat" -simulated_t=0.02 -fps=24 -resolution=100
popd
mkdir --verbose -p ${BLENDER_OUTPUT}
mv --verbose /tmp/blender ${BLENDER_OUTPUT}
echo "Done."
