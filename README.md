# ALICE Open Data Blender animation

## Project Description

This project has the purpose of generating 3D animations of ALICE particle collision events, inside the LHC, using data obtained from CERN's Open Data Portal, which makes ESDs - Event Summary Data files, that contain information about such events - open and available for analysis.

ESD files regarding the ALICE experiment can be found on http://opendata.cern.ch/search?page=1&size=20&experiment=ALICE, and they should be somehow referenced along the process, as explained further.

The software that makes the animation is Blender, which is free and open source. Blender's 2.79b version should be downloaded for this project, and can be found on https://www.blender.org/download/releases/2-79/

Before starting, you must also clone this repository:
```bash
mkdir -p ~/alice
cd ~/alice
git clone https://git.cta.if.ufrgs.br/ALICE-open-data/alice-blender-animation.git
```

The animation making can be summarized in three basic steps:

1) Installing aliRoot;
2) Getting an ESD file;
3) Run script to process ESD data and generate Blender animations using its results.

In case you are not conCERNed about the data being used for the animation and only wish to generate a standard one, skip to the Default Animation section below. For detailed steps on how to make the animation from ESDs, as described above, read the following sections.

## Step 1 - Installing aliRoot

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

## Step 2 - Getting an ESD file

ESD files regarding the ALICE experiment can be found on http://opendata.cern.ch/search?page=1&size=20&experiment=ALICE. If you have doubts on which file to pick for a test, you can select any file on this list: http://opendata.cern.ch/record/1102.

Here, there are two options from which you can choose:

- the first one is to download your ESD file and save it in the `alice-blender-animation` directory, which was cloned from the git repository. Make sure you save it on the same path as this `README.md` file and the `workflow_sketch.sh` script, not inside the "aliRoot" or "animate" directories. Also make sure the file is named `AliESDs.root`.

- the second one is to copy the URL for the ESD file (the address you would access to download it) and paste it on the command line when you run the script that generates the animation, according to the next section.

## Step 3 - Generating animation

Once you are all set, all there is left to do is run the `workflow_sketch.sh` script through your terminal.

If you have already downloaded the ESD file, run it as follows:

```bash
./workflow_sketch.sh --maxparticles <MAXPARTICLES> --duration <DURATION> --resolution <RESOLUTION>
```

where `<MAXPARTICLES>` is the highest number of particles that you wish the events about to be animated have. It means events with more particles than that will not be animated. Keep in mind that it takes extra amount of time to generate animations with too many particles, say, 5000 or more.

`<DURATION>` is the time duration, in seconds, each animation will last.

Finally, `<RESOLUTION>` is the animation resolution percentage, ranging from 0 (you don't want it to be 0) to 100.

Here is a running example:

```bash
./workflow_sketch.sh --maxparticles 2000 --duration 15 --resolution 100
```

If you have copied the ESD's URL in the previous section and wish to download it automatically, run the script as:

```bash
./workflow_sketch.sh --url <URL> --download --maxparticles <MAXPARTICLES> --duration <DURATION> --resolution <RESOLUTION>
```

where `<URL>` is the ESD's URL you have at hand, and all the other arguments are the same as above.

Here is a running example:

```bash
./workflow_sketch.sh --url http://opendata.cern.ch/record/1103/files/assets/alice/2010/LHC10h/000139173/ESD/0004/AliESDs.root --download --maxparticles 2000 --duration 15 --resolution 100
```

After running the script, your Blender animations should be ready! Have in mind that it may take a long time to generate all the animations. For each event inside the ESD file - with fewer particles than you have specified -, there will be three animations saved in .mp4 format, each one corresponding to a different view of the event. They will be available inside the `output` directory. Enjoy!


# Default Animation

For generating a default animation, simply run the script `workflow_sketch.sh` in your terminal as below:

```bash
./workflow_sketch.sh -a
```

After this, a single default animation should be ready. It will be available inside the `output` directory, in mp4 format. Enjoy!
