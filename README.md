# ALICE Open Data Blender animation

## Project Description

This project has the purpose of generating a 3D animation of an ALICE particle collision event, inside the LHC, using data obtained from CERN's Open Data Portal, which makes ESDs - Event Summary Data files, that contain information about such events - open and available for analysis.

ESD files regarding the ALICE experiment can be found on http://opendata.cern.ch/search?page=1&size=20&experiment=ALICE, and they should be processed using the Aliroot software, as indicated in the 'Aliroot' section below.

The software that makes the animation is Blender, which is free and open source. Blender's 2.79b version should be downloaded for this project, and can be found on https://www.blender.org/download/releases/2-79/

Before starting, you must also clone this repository:
```bash
mkdir -p ~/alice
cd ~/alice
git init
git clone https://git.cta.if.ufrgs.br/ALICE-open-data/alice-blender-animation.git
```

The animation making can be summarized in three basic steps:

1) Downloading an ESD file;
2) Installing aliRoot and running macros;
3) Run bash to generate Blender animation using the ESD processing results.

In case you are not conCERNed about the data being used for the animation and only wish to generate a standard one, skip to the Default Animation section below. For detailed steps on how to make the animation from ESDs, as described above, read the following sections.

## Step 1 - Downloading ESD files

ESD files regarding the ALICE experiment can be found on http://opendata.cern.ch/search?page=1&size=20&experiment=ALICE. If you have doubts on which file to pick for a test, you can select any file on this list: http://opendata.cern.ch/record/1102.

You must save your ESD file inside the 'aliRoot' directory, which is obtained by cloning this repository as mentioned above.

## Step 2 - Installing aliRoot

Here is the sequence of steps for installing aliRoot, so you are able to process the relevant information for the project.

1) Install aliBuild. Follow instructions on https://alice-doc.github.io/alice-analysis-tutorial/building/custom.html

2) Initialize AliPhysics

```bash
cd ~/alice
aliBuild init AliPhysics@master
```
3) Verify dependencies (Optional)

```bash
$ aliDoctor AliPhysics
```
4) Build AliPhysics with aliroot5 (this may take a long time)
```bash
aliBuild build AliPhysics --defaults user -z aliroot5
```
5) Enter AliPhysics environment
```bash
alienv enter AliPhysics/latest-aliroot5-user
```
6) Run the macro

```bash
cd ~/alice/alice-blender-animation/aliRoot
aliroot runAnalysis.C
```

With the last step, ESD analysis results will be saved on three text files:

- `s-esd-detail.dat`, for an event with a 'small' number of tracks (between 15 and 30 tracks);

- `m-esd-detail.dat`, for an event with a 'medium' number of tracks (between 100 and 300 tracks);

- `l-esd-detail.dat`, for an event with a 'very large' number of tracks (between 5000 and 50000 tracks).

You must then move those three files into the 'animate' folder, where the Blender scripts are.


## Step 3 - Generating animation

Go inside the 'animate' directory:

```bash
cd ~/alice/alice-blender-animation/animate
```

Run the python script `animate_particles.py` as in the example below:

```bash
blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=10 -camera="BarrelCamera" -datafile="s-esd-detail.dat" -simulated_t=0.02 -fps=24 -resolution=100
```

where everything that follows the double dashes are input arguments for generating the animation. Here is what each argument means:

-radius:

particle radius; must be a number; type float


-duration:

animation duration, in seconds; must be a number; type int


-camera:

defines animation point of view; must be a string; available options: "OverviewCamera", "BarrelCamera", "ForwardCamera"


-datafile:

filename for event data file; must be a string; must be one of your text files: "s-esd-detail.dat", "m-esd-detail.dat", "l-esd-detail.dat"


-simulated_t:

simulated time of event, in microsseconds; must be a number; type float


-fps:

frames per second; must be a number; type int


-resolution:

animation resolution percent; must be a number; type int


After running the script, your Blender animation should be ready! It will be saved in format .mp4 on the address `/tmp/blender`. Enjoy!


# Default Animation

For generating a default animation, simply run the animation python code inside the 'animate' folder, using the `d-esd-detail.dat` file (where 'd' is for 'default') as the input file, as showed below:

```bash
cd ~/alice/alice-blender-animation/animate
blender -noaudio --background -P animate_particles.py -- -radius=0.05 -duration=10 -camera="BarrelCamera" -datafile="d-esd-detail.dat" -simulated_t=0.02 -fps=24 -resolution=100
```
After running the script, your Blender animation should be ready! It will be saved in format .mp4 on the address `/tmp/blender`. Enjoy!
