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

# Progress log file
export PROGRESS_LOG=$(pwd)/progress.log

if [[ -f $PROGRESS_LOG ]]; then
  if grep -q "JOB FINISHED" $PROGRESS_LOG; then
    rm $PROGRESS_LOG
  fi
fi

# Define a timestamp function
timestamp() {
  date +"%y-%m-%d %T $1"
}

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
LONGOPTS=cameras:,mosaic,resolution:,fps:,transparency:,duration:,maxparticles:,\
minparticles:,numberofevents:,minavgpz:,minavgpt:,help,download,sample,url:,its,\
tpc,detailedtpc,trd,emcal,blendersave,picpct:

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
CAMERAS=Overview
MOSAIC=false
DURATION=10
RESOLUTION=100
FPS=24
TRANSPARENCY=1
MAX_PARTICLES=1000
MIN_PARTICLES=0
N_OF_EVENTS=10
MIN_AVG_PZ=0
MIN_AVG_PT=0
HELP=false
DOWNLOAD=false
SAMPLE=false
URL=
ITS=1 # 1 means "build this detector", while 0 means "don't"
TPC=1
DETAILED_TPC=0
TRD=1
EMCAL=1
BLENDERSAVE=1
PICPCT=80
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
      --minavgpt)
          MIN_AVG_PT="$2"
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
      -c|--cameras)
      	  CAMERAS="$2"
      	  shift 2
      	  ;;
      --mosaic)
          MOSAIC=true
          shift
          ;;
      --picpct)
      	  PICPCT="$2"
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
      --detailedtpc)
          DETAILED_TPC=1
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
      --blendersave)
          BLENDERSAVE=1
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
     Set number of events to be animated inside chosen ESD file (defaults to 10)
   --minavgpz VALUE
     Get only events for which its absolute value of average momentum in
     the z direction is greater than or equal to VALUE, in GeV/c. Useful
     for animating events with 'boosts' of particles to the same side.
   --minavgpt VALUE
     Get only events for which its average transversal momentum is
     greater than or equal to VALUE, in GeV/c. Useful for animating
     events with 'boosts' of particles on the xy plane.
   -t | --duration VALUE
     Set the animation duration in seconds.
   -r | --resolution VALUE
     Set the animation resolution percentage, where
     VALUE must be an integer from 1 to 100.
   --fps VALUE
     Set number of frames per second in animation.
   --transparency VALUE
     Set detector transparency as a number greater than zero,
     where zero is full transparency and 1 is standard transparency
   -c | --cameras VALUE
     Which cameras to use for the animation, where VALUE
     is a comma-separated list (without spaces)
     Options: Barrel,Side,Forward,Overview (defaults to Overview)
   --mosaic
     Make animations in all four available cameras and combine them into
     a single 2x2 clip containing all perspectives, totalizing five generated
     .mp4 videos.
   --picpct VALUE
     Percentage of animation to take HD picture, saved along with the clip,
     where VALUE must be an integer
   -a | --sample
     Creates a sample Blender animation of Event 2 from URL
     http://opendata.cern.ch/record/1102/files/assets/alice/2010/LHC10h/000139\
038/ESD/0001/AliESDs.root
   --its
     Removes ITS detector from animation
   --detailedtpc
     Includes more detailed version of TPC in animation
   --tpc
     Removes TPC detector from animation
   --trd
     Removes TRD detector from animation
   --emcal
     Removes EMCal detector from animation
   --blendersave
     Saves Blender file along with animation clip

Example:
--------
$0 --url http://opendata.cern.ch/record/1103/files/assets/alice/2010/LHC10h/000\
139173/ESD/0004/AliESDs.root --download

END
}

# Fix CAMERA to be accepted by the for loop
if [[ $CAMERAS != "" ]]; then
    CAMERAS=$(echo $CAMERAS | sed -e 's#,#Camera #g' -e 's#$#Camera#')
fi

if [[ $MOSAIC == "true" ]]; then
    CAMERAS=$(echo "OverviewCamera BarrelCamera SideCamera ForwardCamera")
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
    echo "Min Average Transversal Momentum: ${MIN_AVG_PT}"
    echo "Cameras: $CAMERAS"
    echo "Mosaic: $MOSAIC"
    echo "Picture Percentage: ${PICPCT}%"
    echo "-----------------------------------"
    echo "------------ Detectors ------------"
    if [[ $ITS = 1 ]]; then
      echo "Building ITS"
    fi
    if [[ $DETAILED_TPC = 1 ]]; then
      echo "Building detailed TPC"
    else
      if [[ $TPC = 1 ]]; then
        echo "Building TPC"
      fi
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

# Get number of frames
FPS_DUR="$FPS $DURATION"
FPS_DUR=$(echo $FPS_DUR | awk '{print $1*$2}')


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

    if ! grep -q "ESD DOWNLOAD DONE" $PROGRESS_LOG; then
      echo "Downloading data."
      wget $URL
      timestamp "ESD DOWNLOAD DONE" >> $PROGRESS_LOG
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

fi

##############################
# Sample synthetic animation#
##############################
if [ "$SAMPLE" = "true" ]; then
    ##############################
    # Phase 1: Blender animate   #
    ##############################
    BLENDER_OUTPUT=$(pwd)/sample
    mkdir --verbose -p ${BLENDER_OUTPUT}

    pushd ${BLENDER_SCRIPT_DIR}
    echo "Preparing sample animation in Blender"

    blender -noaudio --background -P animate_particles.py -- -radius=0.05 \
    -duration=${DURATION} -cameras="${CAMERAS}" -datafile="d-esd-detail.dat" -simulated_t=0.03\
    -fps=${FPS} -resolution=${RESOLUTION} -transparency=${TRANSPARENCY} \
    -stamp_note="opendata.cern.ch_record_1102_alice_2010_LHC10h_000139038_ESD_0001_2" -its=${ITS}\
    -tpc=${TPC} -trd=${TRD} -emcal=${EMCAL} -detailed_tpc=${DETAILED_TPC} \
    -blendersave=${BLENDERSAVE} -picpct=${PICPCT} -tpc_blender_path=${BLENDER_SCRIPT_DIR} \
    -output_path="${BLENDER_OUTPUT}"

    popd
    echo "Done."

##############################
# Animation from file        #
##############################
elif [ "$SAMPLE" = "false" ]; then

  if ! grep -q "DATA ANALYSIS FINISHED" $PROGRESS_LOG; then

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

    fi

    popd
    timestamp "${UNIQUEID} - DATA ANALYSIS FINISHED" >> $PROGRESS_LOG

  else
    if [ "$DOWNLOAD" = "false" ]; then

      pushd ${ALIROOT_SCRIPT_DIR}
      UNIQUEID=$(more uniqueid.txt)
      echo "The unique ID is $UNIQUEID."
      popd

    fi
  fi

  if ! grep -q "${UNIQUEID} - ANIMATION DIRECTORY CREATED" $PROGRESS_LOG ; then

    # Create directory where animations will be saved
    BLENDER_OUTPUT=$(pwd)/$UNIQUEID
    mkdir --verbose -p ${BLENDER_OUTPUT}

    timestamp "${UNIQUEID} - ANIMATION DIRECTORY CREATED" >> $PROGRESS_LOG
  else
    BLENDER_OUTPUT=$(pwd)/$UNIQUEID
  fi

  pushd ${ALIROOT_SCRIPT_DIR} # push back to aliroot directory

  if ! grep -q "${UNIQUEID} - DATA ANALYSIS FILES MOVED to animation directory" $PROGRESS_LOG; then
    #################################################
    # Phase 1: iteration for every event identifier #
    #################################################

    # Get all extracted files
    EXTRACTED_FILES=$(ls -1 esd_detail-event_*.dat | sort --version-sort)

    for FILE_WITH_DATA in $EXTRACTED_FILES; do

        if ! [[ -s $FILE_WITH_DATA ]]; then
            echo "File $FILE_WITH_DATA has zero size. Ignore and continue."
  	        rm $FILE_WITH_DATA
            continue
        fi

        mv ${ALIROOT_SCRIPT_DIR}/$FILE_WITH_DATA \
         ${BLENDER_SCRIPT_DIR}

    done

    timestamp "${UNIQUEID} - DATA ANALYSIS FILES MOVED to animation directory" >> $PROGRESS_LOG

  fi

  popd
  pushd ${BLENDER_SCRIPT_DIR}

  if ! grep -q "${UNIQUEID} - CREATED EVENT COUNTER FILE" $PROGRESS_LOG; then

    # Event counter for animating no more events than the informed amount
    EVENT_COUNTER=0
    echo "$EVENT_COUNTER" > event_counter.txt
    timestamp "${UNIQUEID} - CREATED EVENT COUNTER FILE" >> $PROGRESS_LOG

  fi

  if ! grep -q "${UNIQUEID} - DATA FILES RENAMED according to UNIQUEID" $PROGRESS_LOG; then

    EXTRACTED_FILES=$(ls -1 esd_detail-event_*.dat | sort --version-sort)

    for FILE_WITH_DATA in $EXTRACTED_FILES; do

        EVENT_ID=$(echo $FILE_WITH_DATA | \
                   sed -e "s#esd_detail-event_##" \
                     -e "s#\.dat##")
        EVENT_UNIQUE_ID=${UNIQUEID}_${EVENT_ID}

        LOCAL_FILE_WITH_DATA=${EVENT_UNIQUE_ID}.dat

        mv $FILE_WITH_DATA $LOCAL_FILE_WITH_DATA

    done

    timestamp "${UNIQUEID} - DATA FILES RENAMED according to UNIQUEID" >> $PROGRESS_LOG

  fi

  EXTRACTED_FILES=$(ls -1 ${UNIQUEID}_*.dat | sort --version-sort)

  for LOCAL_FILE_WITH_DATA in $EXTRACTED_FILES; do

    pushd ${BLENDER_SCRIPT_DIR}

    EVENT_ID=$(echo $LOCAL_FILE_WITH_DATA | \
               sed -e "s#${UNIQUEID}_##" \
                 -e "s#\.dat##")
    EVENT_UNIQUE_ID=${UNIQUEID}_${EVENT_ID}

    ##############################
    # Phase 2: blender animate   #
    ##############################

    NUMBER_OF_PARTICLES=$(wc -l $LOCAL_FILE_WITH_DATA | \
                      awk '{ print $1 }')

    AVERAGE_PZ=$(awk 'BEGIN {pzsum=0;n=0} {pzsum+=$8;n++} END {print sqrt(pzsum*pzsum/n/n)}'\
    ${LOCAL_FILE_WITH_DATA})

    AVERAGE_PT=$(awk 'BEGIN {ptsum=0;n=0} {ptsum+=$9;n++} END {print ptsum/n}' \
    ${LOCAL_FILE_WITH_DATA})

    echo "File $LOCAL_FILE_WITH_DATA has $NUMBER_OF_PARTICLES particles."
    echo "Average Z momentum: $AVERAGE_PZ"
    echo "Average transversal momentum $AVERAGE_PT"

    EVENT_COUNTER=$(more event_counter.txt)

    if (( $(echo "$AVERAGE_PT >= $MIN_AVG_PT" |bc -l) )); then
      if (( $(echo "$AVERAGE_PZ >= $MIN_AVG_PZ" |bc -l) )); then
        if [[ $NUMBER_OF_PARTICLES -le $MAX_PARTICLES && $NUMBER_OF_PARTICLES \
-ge $MIN_PARTICLES && $EVENT_COUNTER -lt $N_OF_EVENTS ]]; then

          if ! grep -q "${UNIQUEID} - Event ${EVENT_ID} - SCENE READY." $PROGRESS_LOG; then

            echo "Processing ${EVENT_UNIQUE_ID} ($NUMBER_OF_PARTICLES tracks) in Blender"

            echo "Processing ${EVENT_UNIQUE_ID} in Blender"

            blender -noaudio --background -P animate_particles.py -- -radius=0.05 \
            -duration=${DURATION} -cameras="${CAMERAS}" -datafile="${LOCAL_FILE_WITH_DATA}"\
             -n_event=${EVENT_ID} -simulated_t=0.03 -fps=${FPS} -resolution=${RESOLUTION}\
             -transparency=${TRANSPARENCY} -stamp_note="${EVENT_UNIQUE_ID}" -its=${ITS}\
             -tpc=${TPC} -trd=${TRD} -emcal=${EMCAL} -detailed_tpc=${DETAILED_TPC} \
            -blendersave=${BLENDERSAVE} -picpct=${PICPCT} -tpc_blender_path=${BLENDER_SCRIPT_DIR}\
            -output_path="${BLENDER_OUTPUT}"
            timestamp "${UNIQUEID} - Event ${EVENT_ID} - SCENE READY." >> $PROGRESS_LOG

          fi


          for type in $CAMERAS; do

            if ! grep -q "${UNIQUEID} - Event ${EVENT_ID} - ${type} FINISHED" $PROGRESS_LOG; then
              blender -noaudio --background -P render.py -- -cam ${type} -datafile\
               "${LOCAL_FILE_WITH_DATA}" -n_event ${EVENT_ID} -pic_pct ${PICPCT} -output_path "${BLENDER_OUTPUT}"

              timestamp "${UNIQUEID} - Event ${EVENT_ID} - ${type} FINISHED" >> $PROGRESS_LOG
            fi

          done

          if [ "$MOSAIC" = "true" ]; then

            if ! grep -q "${UNIQUEID} - Event ${EVENT_ID} - MOSAIC FINISHED" $PROGRESS_LOG; then
              pushd ${BLENDER_OUTPUT}

              # Delete existing incomplete .mp4 file
              if [[ -f ${EVENT_UNIQUE_ID}_Mosaic.mp4 ]]; then
                rm ${EVENT_UNIQUE_ID}_Mosaic.mp4
              fi

              # Setting input names for clips in order to make mosaic clip
              INPUT_ONE=$(ls *$EVENT_UNIQUE_ID*${FPS_DUR}.mp4 | awk 'NR==1')
              INPUT_TWO=$(ls *$EVENT_UNIQUE_ID*${FPS_DUR}.mp4 | awk 'NR==2')
              INPUT_THREE=$(ls *$EVENT_UNIQUE_ID*${FPS_DUR}.mp4 | awk 'NR==3')
              INPUT_FOUR=$(ls *$EVENT_UNIQUE_ID*${FPS_DUR}.mp4 | awk 'NR==4')

              ffmpeg -i ${INPUT_FOUR} -i ${INPUT_TWO} -i ${INPUT_THREE} -i ${INPUT_ONE} -filter_complex\
               "[0:v][1:v]hstack=inputs=2[top];[2:v][3:v]hstack=inputs=2[bottom];[top][bottom]vstack=inputs=2[v]"\
               -map "[v]" ${EVENT_UNIQUE_ID}_Mosaic.mp4

              timestamp "${UNIQUEID} - Event ${EVENT_ID} - MOSAIC FINISHED" >> $PROGRESS_LOG

              popd
            fi

          fi

          if ! grep -q "${UNIQUEID} - Event ${EVENT_ID} - TEXT DATA MOVED to final location" $PROGRESS_LOG; then
            # Move processed file to final location
            mv $LOCAL_FILE_WITH_DATA ${BLENDER_OUTPUT}/$LOCAL_FILE_WITH_DATA
            timestamp "${UNIQUEID} - Event ${EVENT_ID} - TEXT DATA MOVED to final location" >> $PROGRESS_LOG
          fi

          echo "EVENT ${EVENT_UNIQUE_ID} DONE with FILE $LOCAL_FILE_WITH_DATA."

          # Increment event counter
          EVENT_COUNTER=$EVENT_COUNTER+1
          rm event_counter.txt
          echo "$EVENT_COUNTER" > event_counter.txt

        else

          if [[ $NUMBER_OF_PARTICLES -lt $MIN_PARTICLES ]]; then
            echo "Too little particles (minimum accepted is $MIN_PARTICLES). Continue."
          elif [[ $NUMBER_OF_PARTICLES -gt $MAX_PARTICLES ]]; then
            echo "Too many particles (maximum accepted is $MAX_PARTICLES). Continue."
          elif [[ $EVENT_COUNTER -ge $N_OF_EVENTS ]]; then
            echo "Numbers of events set to be animated has already been reached. Continue."
          fi

          # Remove non-processed files
          rm $LOCAL_FILE_WITH_DATA

        fi
      else
        echo "Average Z Momentum too low (minimum accepted is $MIN_AVG_PZ). Continue."

        # Remove non-processed files
        rm $LOCAL_FILE_WITH_DATA
      fi
    else
      echo "Average Transversal Momentum too low (minimum accepted is $MIN_AVG_PT). Continue."

      # Remove non-processed files
      rm $LOCAL_FILE_WITH_DATA
    fi

    popd

  done

  # Remove event counter file
  pushd ${BLENDER_SCRIPT_DIR}
  rm event_counter.txt
  popd

fi
timestamp "JOB FINISHED" >> $PROGRESS_LOG
