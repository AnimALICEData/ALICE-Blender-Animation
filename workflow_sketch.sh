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

######################################
# Established Unique ID based on URL #
######################################
UNIQUEID=$(echo $URL | sed \
			   -e "s#http://opendata.cern.ch/##" \
			   -e "s#/AliESDs.root##" \
			   -e "s#files/assets/##" \
			   -e "s#/#_#g")
echo "The unique ID is $UNIQUEID."

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

  ############################
  # Phase 1: aliroot extract #
  ############################
  eval $(alienv -w ${ALIENV_WORK_DIR} -a ${ALIENV_OS_SPEC} load ${ALIENV_ID})
  pushd ${ALIROOT_SCRIPT_DIR}
  # Remove existing symbolic link
  rm --verbose AliESDs.root
  # Create a symbolic link to the actual AliESDs.root
  ln --verbose -s ${ALIESD_ROOT_FILE} AliESDs.root
  # Run the extraction tool
  aliroot -q -b "runAnalysis.C"

  #################################################
  # Phase 1: iteration for every event identifier #
  #################################################

  # Create directory where animations will be saved
  mkdir --verbose -p ${BLENDER_OUTPUT}

  # Get all extracted files
  EXTRACTED_FILES=$(ls -1 esd_detail-event_*.dat | sort --version-sort)
  for FILE_WITH_DATA in $EXTRACTED_FILES; do
      EVENT_ID=$(echo $FILE_WITH_DATA | \
		     sed -e "s#esd_detail-event_##" \
			 -e "s#\.dat##")
      EVENT_UNIQUE_ID=${UNIQUEID}_${EVENT_ID}

      if ! [[ -s $FILE_WITH_DATA ]]; then
	  echo "File $FILE_WITH_DATA has zero size. Ignore and continue."
	  continue
      else
	  echo "Processing ${EVENT_UNIQUE_ID} in blender"
      fi

      ##############################
      # Phase 2: blender animate   #
      ##############################
      mv --verbose ${ALIROOT_SCRIPT_DIR}/${FILE_WITH_DATA} ${BLENDER_SCRIPT_DIR}
      pushd ${BLENDER_SCRIPT_DIR}
      for type in "BarrelCamera" "OverviewCamera" "ForwardCamera"; do
        blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=1 -camera=${type} -datafile="${FILE_WITH_DATA}" -n_event=${EVENT_ID} -simulated_t=0.02 -fps=5 -resolution=50 -stamp_note="Texto no canto"
        echo "${type} for event ${EVENT_ID} done."
      done
      popd
      echo "EVENT ${EVENT_ID} DONE."

  done
  popd

  # Move animation directory to local folder
  #mv --verbose /tmp/blender ${BLENDER_OUTPUT}

fi
