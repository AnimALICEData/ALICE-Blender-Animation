#!/bin/bash

##############################
# Configurations             #
##############################
# Put aliBuild in the PATH env var
export PATH="/mnt/SSD/schnorr/python/bin:$PATH"
# Directory where runAnalysis.C is placed
export ALIROOT_SCRIPT_DIR=$(pwd)/aliRoot/
# Directory where Blender scripts are
export BLENDER_SCRIPT_DIR=$(pwd)/animate/
# alienv working directory
export ALIENV_WORK_DIR=/home/breno/alice/sw
export ALIENV_OS_SPEC=ubuntu1804_x86-64
export ALIENV_ID=AliPhysics/latest-aliroot5-user
# Put Blender 2.79b in the PATH env var
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

OPTIONS=c:hdau:m:n:t:r:
LONGOPTS=camera:,resolution:,fps:,transparency:,duration:,maxparticles:,minparticles:,numberofevents:,minavgpz:,help,download,sample,url:,its,tpc,trd,emcal

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
CAMERA=Overview
DURATION=10
RESOLUTION=100
FPS=24
TRANSPARENCY=1
MAX_PARTICLES=1000
MIN_PARTICLES=0
N_OF_EVENTS=10
MIN_AVG_PZ=0
HELP=false
DOWNLOAD=false
SAMPLE=false
URL=
ITS=1 # 1 means "build this detector", while 0 means "don't"
TPC=1
TRD=1
EMCAL=1
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
      -a|--sample)
            SAMPLE=true
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
      --minparticles)
          MIN_PARTICLES="$2"
          shift 2
          ;;
      -n|--numberofevents)
          N_OF_EVENTS="$2"
          shift 2
          ;;
      --minavgpz)
          MIN_AVG_PZ="$2"
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
      --fps)
          FPS="$2"
          shift 2
          ;;
      --transparency)
          TRANSPARENCY="$2"
          shift 2
          ;;
      -c|--camera)
      	  CAMERA="$2"
      	  shift 2
      	  ;;
      --its)
          ITS=0
          shift
          ;;
      --tpc)
          TPC=0
          shift
          ;;
      --trd)
          TRD=0
          shift
          ;;
      --emcal)
          EMCAL=0
          shift
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
     Get only events for which its number of particles does not
     exceed VALUE.
   --minparticles VALUE
     Get only events for which its number of particles is greater than
     or equal to VALUE.
   -n | --numberofevents VALUE
     Set number of events to be animated inside chosen ESD file.
   --minavgpz VALUE
     Get only events for which its absolute value of average momentum in
     the z direction is greater than or equal to VALUE. Useful for animating
     events with 'boosts' of particles to the same side.
   -t | --duration VALUE
     Set the animation duration in seconds.
   -r | --resolution VALUE
     Set the animation resolution percentage.
   --fps VALUE
     Set number of frames per second in animation.
   --transparency VALUE
     Set detector transparency as a number greater than zero,
     where zero is full transparency and 1 is standard transparency
   -c | --camera VALUE
     Which camera to use for the animation, where VALUE
     is a comma-separated list (without spaces)
     Options: Barrel,Forward,Overview (defaults to Overview)
   -a | --sample
     Creates a sample Blender animation of Event 2 from URL
     http://opendata.cern.ch/record/1102/files/assets/alice/2010/LHC10h/000139038/ESD/0001/AliESDs.root
   --its
     Removes ITS detector from animation
   --tpc
     Removes TPC detector from animation
   --trd
     Removes TRD detector from animation
   --emcal
     Removes EMCal detector from animation

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
    echo "Sample: $SAMPLE"
    echo "Transparency Parameter: $TRANSPARENCY"
    echo "Duration: $DURATION"
    echo "Resolution: $RESOLUTION"
    echo "FPS: $FPS"
    echo "Max particles: ${MAX_PARTICLES}"
    echo "Min particles: ${MIN_PARTICLES}"
    echo "Number of events: ${N_OF_EVENTS}"
    echo "Min Average Z Momentum: ${MIN_AVG_PZ}"
    echo "Camera: $CAMERA"
    echo "-----------------------------------"
    echo "------------ Detectors ------------"
    if [[ $ITS = 1 ]]; then
      echo "Building ITS"
    fi
    if [[ $TPC = 1 ]]; then
      echo "Building TPC"
    fi
    if [[ $TRD = 1 ]]; then
      echo "Building TRD"
    fi
    if [[ $EMCAL = 1 ]]; then
      echo "Building EMCAL"
    fi
    if [[ $TPC = 0 && $TPC = 0 && $TRD = 0 && $EMCAL = 0 ]]; then
      echo "Not building any detectors"
    fi
    echo "-----------------------------------"

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
        echo "Error. Must pass the dataset URL in order to download ESD file."
        usage
        exit
    fi
    echo "Downloading data."
    wget $URL

    ######################################
    # Established Unique ID based on URL #
    ######################################
    UNIQUEID=$(echo $URL | sed \
                         -e "s#http://opendata.cern.ch/##" \
                         -e "s#/AliESDs.root##" \
                         -e "s#files/assets/##" \
                         -e "s#/#_#g")

    echo "The unique ID is $UNIQUEID."

fi

##############################
# Sample synthetic animation#
##############################
if [ "$SAMPLE" = "true" ]; then
    ##############################
    # Phase 1: Blender animate   #
    ##############################
    pushd ${BLENDER_SCRIPT_DIR}
    for type in $CAMERA; do
      echo "Preparing sample animation with $type in Blender"
      blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=${DURATION} -camera=${type} -datafile="d-esd-detail.dat" -simulated_t=0.03 -fps=${FPS} -resolution=${RESOLUTION} -transparency=${TRANSPARENCY} -stamp_note="opendata.cern.ch_record_1102_alice_2010_LHC10h_000139038_ESD_0001_2" -its=${ITS} -tpc=${TPC} -trd=${TRD} -emcal=${EMCAL}
    done
    popd
    BLENDER_OUTPUT=.
    mkdir --verbose -p ${BLENDER_OUTPUT}
    mv --verbose /tmp/blender ${BLENDER_OUTPUT}
    echo "Done."

##############################
# Animation from file        #
##############################
elif [ "$SAMPLE" = "false" ]; then

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
  rm -f --verbose AliESDs.root
  # Create a symbolic link to the actual AliESDs.root
  ln --verbose -s ${ALIESD_ROOT_FILE} AliESDs.root
  # Run the extraction tool
  aliroot runAnalysis.C

  if [ "$DOWNLOAD" = "false" ]; then

    UNIQUEID=$(more uniqueid.txt)
    echo "The unique ID is $UNIQUEID."
    rm uniqueid.txt

  fi

  # Create directory where animations will be saved
  popd
  BLENDER_OUTPUT=$(pwd)/$UNIQUEID
  mkdir --verbose -p ${BLENDER_OUTPUT}
  pushd ${ALIROOT_SCRIPT_DIR} # push back to aliroot directory

  #################################################
  # Phase 1: iteration for every event identifier #
  #################################################

  # Event counter for animating no more events than the informed amount
  EVENT_COUNTER=0

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

      rm $FILE_WITH_DATA

      NUMBER_OF_PARTICLES=$(wc -l ${BLENDER_SCRIPT_DIR}/$LOCAL_FILE_WITH_DATA | \
                        awk '{ print $1 }')

      AVERAGE_PZ=$(awk 'BEGIN {pzsum=0;n=0} {pzsum+=$8;n++} END {print sqrt(pzsum*pzsum/n/n)}' ${BLENDER_SCRIPT_DIR}/${LOCAL_FILE_WITH_DATA})

      echo "File $LOCAL_FILE_WITH_DATA has $NUMBER_OF_PARTICLES particles and average Z momentum $AVERAGE_PZ"

      if (( $(echo "$AVERAGE_PZ >= $MIN_AVG_PZ" |bc -l) )); then
        if [[ $NUMBER_OF_PARTICLES -le $MAX_PARTICLES && $NUMBER_OF_PARTICLES -ge $MIN_PARTICLES && $EVENT_COUNTER -lt $N_OF_EVENTS ]]; then

          # Increment event counter
          EVENT_COUNTER=$EVENT_COUNTER+1

          echo "Processing ${EVENT_UNIQUE_ID} ($NUMBER_OF_PARTICLES tracks) in Blender"

          pushd ${BLENDER_SCRIPT_DIR}

          for type in $CAMERA; do
                echo "Processing ${EVENT_UNIQUE_ID} with $type in Blender"

                blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=${DURATION} -camera=${type} -datafile="${LOCAL_FILE_WITH_DATA}" -n_event=${EVENT_ID} -simulated_t=0.03 -fps=${FPS} -resolution=${RESOLUTION} -transparency=${TRANSPARENCY} -stamp_note="${EVENT_UNIQUE_ID}" -its=${ITS} -tpc=${TPC} -trd=${TRD} -emcal=${EMCAL}
                # Move generated file to final location
                mv /tmp/blender/* ${BLENDER_OUTPUT}
                echo "${type} for event ${EVENT_UNIQUE_ID} done."
          done

          # Move processed file to final location
          mv $LOCAL_FILE_WITH_DATA ${BLENDER_OUTPUT}/$LOCAL_FILE_WITH_DATA

          popd
          echo "EVENT ${EVENT_UNIQUE_ID} DONE with FILE $LOCAL_FILE_WITH_DATA."
        else

          if [[ $NUMBER_OF_PARTICLES -lt $MIN_PARTICLES ]]; then
            echo "Too little particles (minimum accepted is $MIN_PARTICLES). Continue."
          elif [[ $NUMBER_OF_PARTICLES -gt $MAX_PARTICLES ]]; then
            echo "Too many particles (maximum accepted is $MAX_PARTICLES). Continue."
          elif [[ $EVENT_COUNTER -ge $N_OF_EVENTS ]]; then
            echo "Numbers of events set to be animated has already been reached. Continue."
          fi

          # Remove non-processed files
          pushd ${BLENDER_SCRIPT_DIR}
          rm $LOCAL_FILE_WITH_DATA
          popd

          continue
        fi
      else
        echo "Average Z Momentum too low (minimum accepted is $MIN_AVG_PZ). Continue."

        # Remove non-processed files
        pushd ${BLENDER_SCRIPT_DIR}
        rm $LOCAL_FILE_WITH_DATA
        popd
      fi
  done
  popd

fi
