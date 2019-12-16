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
export ALIENV_WORK_DIR=/home/tropos/alice/sw
export ALIENV_OS_SPEC=ubuntu1604_x86-64
export ALIENV_ID=AliPhysics/latest-aliroot5-user
# Put blender 2.79b in the PATH env var
export PATH="/home/schnorr/install/blender-2.79-linux-glibc219-x86_64/:$PATH"

##############################
# Usage                      #
##############################
function usage()
{
    echo "$0 <DOWNLOAD> <URL> [DEFAULT_ANIMATION]";
    echo "  where <URL> is a URL to uniquely identify a dataset";
    echo "  where <DOWNLOAD> is true or false, indicate whether the dataset should be downloaded";
    echo "  where <DEFAULT_ANIMATION> is optional, either true or false, to indicate if the default animation should be generated";
    echo "  leaving <DEFAULT_ANIMATION> blank will generate custom animation from data file";
    echo
    echo
    echo "Usage example:"
    echo "./$0 true http://opendata.cern.ch/record/1103/files/assets/alice/2010/LHC10h/000139173/ESD/0004/AliESDs.root false"
    echo
}

##############################
# Parse Parameters           #
##############################
DOWNLOAD=$1
if [ -z $DOWNLOAD ]; then
    echo "Error. Must explicitely inform whether to download the dataset or not."
    usage
    exit
fi

URL=$2

DEFAULT_ANIMATION=$3
if [ -z $DEFAULT_ANIMATION ]; then
    DEFAULT_ANIMATION="false"
fi

##############################
# Download Dataset           #
##############################
if [ "$DOWNLOAD" = "true" ]; then
    if [ -z $URL ]; then
        echo "Error. Must pass the dataset URL."
        usage
        exit
    fi
    echo "Downloading data."
    wget $URL
fi

##############################
# Default synthetic animation#
##############################
if [ "$DEFAULT_ANIMATION" = "true" ]; then
    echo "Preparing default animation."
    ##############################
    # Phase 1: blender animate   #
    ##############################
    pushd ${BLENDER_SCRIPT_DIR}
    blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=2 -camera="OverviewCamera" -datafile="d-esd-detail.dat" -simulated_t=0.02 -fps=5 -resolution=100 -stamp_note="Texto no canto"
    popd
    mkdir --verbose -p ${BLENDER_OUTPUT}
    mv --verbose /tmp/blender ${BLENDER_OUTPUT}
    echo "Done."

##############################
# Animation from file        #
##############################
elif [ "$DEFAULT_ANIMATION" = "false" ]; then

  # Verify if AliESDs.root is here
  ALIESD_ROOT_FILE=$(pwd)/AliESDs.root
  if ! [[ -f "$ALIESD_ROOT_FILE" ]]
  then
      echo "AliESDs.root not found."
      exit
  fi

  # Create directory where animations will be saved
  mkdir --verbose -p ${BLENDER_OUTPUT}

  ##############################
  # Phase 1: aliroot extract   #
  ##############################
  eval $(alienv -w ${ALIENV_WORK_DIR} -a ${ALIENV_OS_SPEC} load ${ALIENV_ID})
  pushd ${ALIROOT_SCRIPT_DIR}
  # Remove existing symbolic link
  rm --verbose AliESDs.root
  # Create a symbolic link to the actual AliESDs.root
  ln --verbose -s ${ALIESD_ROOT_FILE} AliESDs.root
  # Run the extraction tool
  aliroot -q -b "runAnalysis.C(-1)"

  # Check if events_number.dat file exists
  FILE_WITH_NUMBER_OF_EVENTS=events_number.dat
  FILE_WITH_DATA=esd-detail.dat
  if ! [[ -e ${FILE_WITH_NUMBER_OF_EVENTS} ]]; then
      echo "File $FILE_WITH_NUMBER_OF_EVENTS does not exist. Abort."
      exit
  fi

  n_events=$(cat ${FILE_WITH_NUMBER_OF_EVENTS}) # stores number of events in ESD file
  if ! [[ "$n_events" =~ ^[0-9]+$ ]]; then # verifies whether n_events is an integer
      echo "Failed to extract number of events from file."
      exit
  else
      echo "The number of events in the file is ${n_events}."
  fi
  # Erase output txt files
  rm -f ${FILE_WITH_NUMBER_OF_EVENTS}
  rm -f ${FILE_WITH_DATA}

  FIRST_EVENT=0
  LAST_EVENT=$(echo "${n_events}-1" | bc)
  echo "Event identifiers are sequential from ${FIRST_EVENT} to ${LAST_EVENT}."
  
  exit

  for ((i=0; i<n_events; i++)); do

      aliroot -q -b "runAnalysis.C($i)"
      ESD_DETAIL=${ALIROOT_SCRIPT_DIR}/esd-detail.dat
      if ! [[ -f "$ESD_DETAIL" ]]
      then
        echo "ERROR: aliRoot analysis on event $i went wrong."
      fi

      ##############################
      # Phase 2: blender animate   #
      ##############################
      mv --verbose ${ALIROOT_SCRIPT_DIR}/esd-detail.dat ${BLENDER_SCRIPT_DIR}
      pushd ${BLENDER_SCRIPT_DIR}
      for type in "BarrelCamera" "OverviewCamera" "ForwardCamera"; do
        blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=1 -camera=${type} -datafile="${FILE_WITH_DATA}" -n_event=$i -simulated_t=0.02 -fps=5 -resolution=50 -stamp_note="Texto no canto"
        echo "${type} for event $i done."
      done
      popd
      echo "EVENT $i DONE."

    done
  popd

  # Move animation directory to local folder
  mv --verbose /tmp/blender ${BLENDER_OUTPUT}

fi
