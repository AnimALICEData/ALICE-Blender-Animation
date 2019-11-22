# Project Description

This project has the purpose of generating a 3D animation of an ALICE particle collision event, inside the LHC, using data obtained from CERN's Open Data Portal, which makes ESDs - Event Summary Data files, that contain information about such events - open and available for analysis.

ESD files regarding the ALICE experiment can be found on http://opendata.cern.ch/search?page=1&size=20&experiment=ALICE, and they should be processed using the Aliroot software, as indicated by the Instructions section below

The software that makes the animation is Blender, which is free and open source. Blender's 2.79b version should be downloaded for this project, and can be found on https://www.blender.org/download/releases/2-79/

The animation making can be summarized in three basic steps:

1) Downloading of an ESD file (for example, any file on this list: http://opendata.cern.ch/record/1102);
2) Processing of ESD file using Aliroot macros (as indicated further);
3) Run code to generate Blender animation using the ESD processing results.

The code for step 3 can be found in the Blender_animation repository: https://git.cta.if.ufrgs.br/ALICE-open-data/alice-blender-animation/tree/ParticleTypes


# Sample macros for processing AliESDs from CERN Open Data Portal

## Requirements

Execute with aliroot5. Place `AliESDs.root` files in reach of the `chain->Add("AliESDs.root");` line on `runAnalysis.C` and execute.


## Instructions

1) Install aliBuild. Follow instructions on https://alice-doc.github.io/alice-analysis-tutorial/building/custom.html

2) Initialize AliPhysics

```bash
mkdir -p ~/alice
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
aliroot runAnalysis.C
```
Results will be saved on three text files: `s-esd-detail.dat`, for an event with a 'small' number of tracks; `m-esd-detail.dat`, for an event with a medium number of tracks; `l-esd-detail.dat`, for an event with a very large number of tracks.

## Credits

The code used here is based on the ALICE analysis tutorial by Redmer A. Bertens.
