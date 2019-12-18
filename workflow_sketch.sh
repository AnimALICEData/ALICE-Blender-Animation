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
# alienv working directory
export ALIENV_WORK_DIR=/mnt/SSD/schnorr/ALICE/sw/
export ALIENV_OS_SPEC=ubuntu1604_x86-64
export ALIENV_ID=AliPhysics/latest-aliroot5-user
# Put blender 2.79b in the PATH env var
export PATH="/home/schnorr/install/blender-2.79-linux-glibc219-x86_64/:$PATH"

##############################
# Command-line options       #
##############################
# See the following link to understand the code below
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=c:hdau:m:t:r:
LONGOPTS=camera:,resolution:,duration:,maxparticles:,help,download,default,url:

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

##############################
# Parse Parameters           #
##############################
CAMERA=Barrel
DURATION=10
RESOLUTION=100
MAX_PARTICLES=0
HELP=false
DOWNLOAD=false
DEFAULT=false
URL=
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
      -h|--help)
          HELP=true
          shift
          break
          ;;
      -d|--download)
            DOWNLOAD=true
            shift
            ;;
      -a|--default)
            DEFAULT=true
            shift
            ;;
      -u|--url)
          URL="$2"
            shift 2
            ;;
      -m|--maxparticles)
          MAX_PARTICLES="$2"
          shift 2
          ;;
      -t|--duration)
          DURATION="$2"
          shift 2
          ;;
      -r|--resolution)
          RESOLUTION="$2"
          shift 2
          ;;
      -c|--camera)
	  CAMERA="$2"
	  shift 2
	  ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error $*"
            exit 3
            ;;
    esac
done

##############################
# Usage                      #
##############################
function usage()
{
    # Using a here doc with standard out.
    cat <<-END
Usage:
------
   -h | --help
     Display this help
   -d | --download
     Download the AliESDs.root file using the provided URL
   -u | --url URL
     Provide the URL to uniquely identify a AliESDs.root dataset.
     This should be in the format provided by http://opendata.cern.ch.
     See example below.
   -m | --maxparticles VALUE
     Get only events for which its number of particles is smaller than VALUE.
   -t | --duration VALUE
     Set the animation duration in seconds.
   -r | --resolution VALUE
     Set the animation resolution percentage.
   -c | --camera VALUE
     Which camera to use for the animation, where VALUE
     is a comma-separated list (without spaces)
     Options: Barrel,Forward,Overview (defaults to Barrel)
   -a | --default
     Creates a default animation with blender.

Example:
--------
$0 --url http://opendata.cern.ch/record/1103/files/assets/alice/2010/LHC10h/000139173/ESD/0004/AliESDs.root --download

END
}

# Fix CAMERA to be accepted by the for loop
if [[ $CAMERA != "" ]]; then
    CAMERA=$(echo $CAMERA | sed -e 's#,#Camera #g' -e 's#$#Camera#')
fi

if [[ $HELP = "true" ]]; then
    usage
    exit
else
    echo "-------- Parsed parameters --------"
    echo "URL: $URL"
    echo "Download: $DOWNLOAD"
    echo "Default: $DEFAULT"
    echo "Max particles: ${MAX_PARTICLES}"
    echo "Camera: $CAMERA"
    echo "-----------------------------------"
fi

if [[ $URL = "" ]]; then
    echo "URL parameter is obligatory."
    exit
    usage
fi

# handle non-option arguments
if [[ $# -ne 0 ]]; then
    echo "$0: non-option arguments ($#, $*) are ignored."
    echo "Remove them manually as indicated between parenthesis."
    exit
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
if [ "$DEFAULT" = "true" ]; then
    echo "Preparing default animation."
    ##############################
    # Phase 1: blender animate   #
    ##############################
    pushd ${BLENDER_SCRIPT_DIR}
    blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=${DURATION} -camera="OverviewCamera" -datafile="d-esd-detail.dat" -simulated_t=0.03 -fps=24 -resolution=${RESOLUTION} -stamp_note="Default animation"
    popd
    BLENDER_OUTPUT=.
    mkdir --verbose -p ${BLENDER_OUTPUT}
    mv --verbose /tmp/blender ${BLENDER_OUTPUT}
    echo "Done."

##############################
# Animation from file        #
##############################
elif [ "$DEFAULT" = "false" ]; then

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
  aliroot runAnalysis.C

  #################################################
  # Phase 1: iteration for every event identifier #
  #################################################

  # Create directory where animations will be saved
  BLENDER_OUTPUT=$(pwd)/$UNIQUEID
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
	  rm $FILE_WITH_DATA
          continue
      fi

      ##############################
      # Phase 2: blender animate   #
      ##############################

      LOCAL_FILE_WITH_DATA=${EVENT_UNIQUE_ID}.dat
      cp ${ALIROOT_SCRIPT_DIR}/$FILE_WITH_DATA \
       ${BLENDER_SCRIPT_DIR}/${LOCAL_FILE_WITH_DATA}

      NUMBER_OF_PARTICLES=$(wc -l ${BLENDER_SCRIPT_DIR}/$LOCAL_FILE_WITH_DATA | \
                        awk '{ print $1 }')
      echo "File $LOCAL_FILE_WITH_DATA has $NUMBER_OF_PARTICLES particles"
      if [[ $NUMBER_OF_PARTICLES -lt $MAX_PARTICLES ]]; then
        echo "Processing ${EVENT_UNIQUE_ID} ($NUMBER_OF_PARTICLES) in blender"

        pushd ${BLENDER_SCRIPT_DIR}

        for type in $CAMERA; do
              echo "Processing ${EVENT_UNIQUE_ID} with $type Camera in blender"

              blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=${DURATION} -camera=${type} -datafile="${LOCAL_FILE_WITH_DATA}" -n_event=${EVENT_ID} -simulated_t=0.03 -fps=24 -resolution=${RESOLUTION} -stamp_note="${EVENT_UNIQUE_ID}"
              # Move generated file to final location
              mv /tmp/blender/* ${BLENDER_OUTPUT}
              echo "${type} for event ${EVENT_UNIQUE_ID} done."
        done

        # Move processed file to final location
        mv $LOCAL_FILE_WITH_DATA ${BLENDER_OUTPUT}

        popd
        echo "EVENT ${EVENT_UNIQUE_ID} DONE with FILE $LOCAL_FILE_WITH_DATA."
      else
          echo "Too many particles (maximum accepted is $MAX_PARTICLES). Continue."
	  rm $FILE_WITH_DATA
        continue
      fi
  done
  popd
fi
