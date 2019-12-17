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

OPTIONS=hdau:
LONGOPTS=help,download,default,url:,

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
HELP=false
DOWNLOAD=false
DEFAULT=false
URL=-
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
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

# handle non-option arguments
if [[ $# -ne 0 ]]; then
    echo "$0: non-option arguments ($#, $*) are ignored."
fi

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
   -a | --default
     Creates a default animation with blender.

Example:
--------
$0 --url http://opendata.cern.ch/record/1103/files/assets/alice/2010/LHC10h/000139173/ESD/0004/AliESDs.root --download

END
}

if [[ $HELP = "true" ]]; then
    usage
    exit
else
    echo "-------- Parsed parameters --------"
    echo "URL: $URL"
    echo "Download: $DOWNLOAD"
    echo "Default: $DEFAULT"
    echo "-----------------------------------"
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
    blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=2 -camera="OverviewCamera" -datafile="d-esd-detail.dat" -simulated_t=0.02 -fps=5 -resolution=100 -stamp_note="Texto no canto"
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
	  continue
      else
	  echo "Processing ${EVENT_UNIQUE_ID} in blender"
      fi

      ##############################
      # Phase 2: blender animate   #
      ##############################
      pushd ${BLENDER_SCRIPT_DIR}

      LOCAL_FILE_WITH_DATA=${EVENT_UNIQUE_ID}.dat
      cp ${ALIROOT_SCRIPT_DIR}/$FILE_WITH_DATA \
	 ${BLENDER_SCRIPT_DIR}/${LOCAL_FILE_WITH_DATA}

      for type in "BarrelCamera" "OverviewCamera" "ForwardCamera"; do
          echo "Processing ${EVENT_UNIQUE_ID} with $type Camera in blender"

          blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=1 -camera=${type} -datafile="${LOCAL_FILE_WITH_DATA}" -n_event=${EVENT_ID} -simulated_t=0.01 -fps=5 -resolution=50 -stamp_note="${EVENT_UNIQUE_ID}"
          # Move generated file to final location
          mv /tmp/blender/* ${BLENDER_OUTPUT}
          echo "${type} for event ${EVENT_ID} done."
      done

      # Move processed file to final location
      mv $LOCAL_FILE_WITH_DATA ${BLENDER_OUTPUT}

      popd
      echo "EVENT ${EVENT_ID} DONE."

  done
  popd
fi
