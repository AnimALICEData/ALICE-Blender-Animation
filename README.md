# ALICE Open Data Blender animation

## Project Description

This project has the purpose of generating 3D animations of ALICE particle collision events using data obtained from CERN's Open Data Portal. ALICE stands for "A Large Ion Collider Experiment" and it is a particle detector inside the LHC - Large Hadron Collider -, the world's largest and highest-energy particle collider, located beneath the France–Switzerland border. CERN stands for *Organisation européenne pour la recherche nucléaire*, which is French for European Organization for Nuclear Research, and it is the home of LHC. CERN's Open Data Portal is an open online platform that contains data files from particle physics; those include the ESDs - Event Summary Data files -, which hold information about ALICE events and are of great help making the animations look like real representations of such events.

## How it all works

Before diving into how to run this project, it is important to develop some intuition on how the pieces all fit together to make the whole thing work out just right.

The animation of a particle collision event is generated through 3D modeling software, which sets the position of all the particles at any given time - until the animation is over - with the help of their respective mass, charge and initial linear momentum values, plus the value of the magnetic field and the collision vertex, a spot from which we consider all the particles originate.

All this information must be obtained from somewhere - that somewhere is the above-mentioned ESD files, which contain data about several events each. The ESDs come in a *.root* extension and may only be interpreted by ROOT, CERN's official software for particle physics analysis. This is done through C++ code, which is written in order to specifically refer to the ESD desired data, in accordance with the available libraries, and run by ROOT to export this data to textual format. That is why the download of Aliroot, ROOT's version for ALICE events analysis, is required.

The text files containing all the physics data are then read by the Python scripts responsible for generating the animation, completing the procedure.

The whole process is a lot more user-friendly than it may seem at first glance; except for installing a couple of programs - ROOT and Blender -, the only thing left for the user to do is run a line of code from the terminal, which executes a script that automatizes everything from running ROOT to rendering and saving every animation *.mp4* file. The final result is a directory inside of which is a series of animation clips, each one corresponding to a different event in the chosen ESD file.

## Laying the groundwork

This project was developed in Ubuntu 18.04 version of Linux, therefore this is the recommended OS for running it.

ESD files regarding the ALICE experiment can be found on http://opendata.cern.ch/search?page=1&size=20&experiment=ALICE, and they should be somehow referenced along the process, as explained further.

The software used for animating events is Blender, which is free and open source. Blender's 2.79b version should be downloaded for this project, and can be found on https://www.blender.org/download/releases/2-79/

Before starting, you must also clone this repository:
```bash
mkdir -p ~/alice
cd ~/alice
git clone https://git.cta.if.ufrgs.br/ALICE-open-data/alice-blender-animation.git
```

The animation making can be summarized in three basic steps:

1) Installing Aliroot;
2) Getting an ESD file;
3) Running script to process ESD data and generate Blender animations using its results.

In case you are not conCERNed about the data being used for the animation and only wish to generate a standard one, skip to the Default Animation section below. For detailed steps on how to make the animation from ESDs, as described above, read the following sections.

## Step 1 - Installing aliRoot

Here is the sequence of steps for installing Aliroot, CERN's official software for ALICE physics analysis, so you are able to process the relevant information for the project.

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

### Manual Download
Manually download your ESD file and save it in the `alice-blender-animation` directory, which was cloned from the git repository. Make sure you save it on the same path as this `README.md` file and the `workflow_sketch.sh` script, not inside the "aliRoot" or "animate" directories. Also make sure the file is named `AliESDs.root`.

### Automatic Download
Have your ESD be downloaded automatically; just copy the URL for the chosen ESD file (the address you would access to download it) so you can paste it on the command line when you run the script that generates the animation, according to the next section.

## Step 3 - Generating animation

Once you are all set, all there is left to do is run the `workflow_sketch.sh` script through your terminal. This script offers several options regarding parameters such as animation time duration and resolution. For more information, run it as

```bash
./workflow_sketch.sh --help
```

Standard values to all these parameters are set so the minimum code required is simply

```bash
./workflow_sketch.sh
```

If you have chosen the automatic ESD download option above, the code becomes

```bash
./workflow_sketch.sh --url <URL> --download
```

where ``<URL>`` is the copied ESD URL.

After running the script, it may take a long time to generate all the animations, but as soon as it is done, they will be available inside a new directory uniquely identified according to the chosen ESD file. Each clip is also identified by event number. Enjoy!


# Default Animation

For generating a default animation, simply run the script `workflow_sketch.sh` in your terminal as below:

```bash
./workflow_sketch.sh -a
```

After this, a single default animation should be ready. It will be available inside the `blender` directory, in *.mp4* format. Enjoy!
