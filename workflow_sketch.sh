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

  #############################################
  # Phase 1: aliroot extract number of events #
  #############################################
  eval $(alienv -w ${ALIENV_WORK_DIR} -a ${ALIENV_OS_SPEC} load ${ALIENV_ID})
  pushd ${ALIROOT_SCRIPT_DIR}
  # Remove existing symbolic link
  rm --verbose AliESDs.root
  # Create a symbolic link to the actual AliESDs.root
  ln --verbose -s ${ALIESD_ROOT_FILE} AliESDs.root
  # Run the extraction tool
  aliroot -q -b "runAnalysis.C(-1)"

  #############################################
  # Phase 1: check number of events           #
  #############################################
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

  # Create directory where animations will be saved
  mkdir --verbose -p ${BLENDER_OUTPUT}

  #################################################
  # Phase 1: iteration for every event identifier #
  #################################################
  for EVENT_ID in $(seq ${FIRST_EVENT} ${LAST_EVENT}); do
      echo $EVENT_ID

      ###############################################
      # Phase 1: aliroot extract data from an event #
      ###############################################
      FILE_WITH_DATA="esd_detail-event_${EVENT_ID}.dat"

      aliroot -q -b "runAnalysis.C(${EVENT_ID})"
      if ! [[ -f "$FILE_WITH_DATA" ]]
      then
          echo "WARNING: aliRoot extraction for event ${EVENT_ID} went wrong."
	  echo "We are ignoring this and proceed to next event."
	  continue
      else
	  echo "Extracted $FILE_WITH_DATA contains $(wc -l $FILE_WITH_DATA) lines."
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
  mv --verbose /tmp/blender ${BLENDER_OUTPUT}

fi
