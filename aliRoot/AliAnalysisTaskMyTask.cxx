/**************************************************************************
 * Copyright(c) 1998-1999, ALICE Experiment at CERN, All rights reserved. *
 *                                                                        *
 * Author: The ALICE Off-line Project.                                    *
 * Contributors are mentioned in the code where appropriate.              *
 *                                                                        *
 * Permission to use, copy, modify and distribute this software and its   *
 * documentation strictly for non-commercial purposes is hereby granted   *
 * without fee, provided that the above copyright notice appears in all   *
 * copies and that both the copyright notice and this permission notice   *
 * appear in the supporting documentation. The authors make no claims     *
 * about the suitability of this software for any purpose. It is          *
 * provided "as is" without express or implied warranty.                  *
 **************************************************************************/

/* AliAnaysisTaskMyTask
 *
 * empty task which can serve as a starting point for building an analysis
 * as an example, one histogram is filled
 */

#include "TChain.h"
#include "TH1F.h"
#include "TList.h"
#include "AliAnalysisTask.h"
#include "AliAnalysisManager.h"
#include "AliESDEvent.h"
#include "AliESDInputHandler.h"
#include "AliAnalysisTaskMyTask.h"
#include "AliESDtrack.h"
#include "AliESDVertex.h"
#include "AliVertex.h"
#include "Riostream.h"


Int_t esd_event_id = 0; // global variable to store unique event id
Int_t smallEventID = 0; // is equal to esd-event-id until the selected event (one with an appropriate number of tracks) is reached
Int_t mediumEventID = 0; // for events with ~200 tracks
Int_t largeEventID = 0; // for events with many many tracks

class AliAnalysisTaskMyTask;    // your analysis class

using namespace std;            // std namespace: so you can do things like 'cout'

ClassImp(AliAnalysisTaskMyTask) // classimp: necessary for root

AliAnalysisTaskMyTask::AliAnalysisTaskMyTask() : AliAnalysisTaskSE(),
    fESD(0), fOutputList(0), fHistPt(0),    fHistEvents(0), fHistMass(0)
{
    // default constructor, don't allocate memory here!
    // this is used by root for IO purposes, it needs to remain empty
}
//_____________________________________________________________________________
AliAnalysisTaskMyTask::AliAnalysisTaskMyTask(const char* name) : AliAnalysisTaskSE(name),
    fESD(0), fOutputList(0), fHistPt(0),  fHistEvents(0), fHistMass(0)
{
    // constructor
    DefineInput(0, TChain::Class());    // define the input of the analysis: in this case we take a 'chain' of events
                                        // this chain is created by the analysis manager, so no need to worry about it,
                                        // it does its work automatically
    DefineOutput(1, TList::Class());    // define the ouptut of the analysis: in this case it's a list of histograms
                                        // you can add more output objects by calling DefineOutput(2, classname::Class())
                                        // if you add more output objects, make sure to call PostData for all of them, and to
                                        // make changes to your AddTask macro!
}
//_____________________________________________________________________________
AliAnalysisTaskMyTask::~AliAnalysisTaskMyTask()
{
    // destructor
    if(fOutputList) {
        delete fOutputList;     // at the end of your task, it is deleted from memory by calling this function
    }
}
//_____________________________________________________________________________
void AliAnalysisTaskMyTask::UserCreateOutputObjects()
{
    // create output objects
    //
    // this function is called ONCE at the start of your analysis (RUNTIME)
    // here you ceate the histograms that you want to use
    //
    // the histograms are in this case added to a tlist, this list is in the end saved
    // to an output file
    //
    fOutputList = new TList();          // this is a list which will contain all of your histograms
                                        // at the end of the analysis, the contents of this list are written
                                        // to the output file
    fOutputList->SetOwner(kTRUE);       // memory stuff: the list is owner of all objects it contains and will delete them
                                        // if requested (dont worry about this now)

    // example of a histogram
    fHistPt = new TH1F("fHistPt", "fHistPt", 100, 0, 10);       // create your histogra
    fOutputList->Add(fHistPt);          // don't forget to add it to the list! the list will be written to file, so if you want
                                        // your histogram in the output file, add it to the list!

    // my mass histogram
    Double_t fHistMassEdges[12] = {0.0,0.0005,0.0405,0.08,0.12,0.13,0.17,0.48,0.52,0.92,0.96,1.0}; // 11 bins =>> has 11+1 = 12 edges

    fHistMass = new TH1F("fHistMass","Particle Histogram;M_{particle}", 11, fHistMassEdges);
    fOutputList->Add(fHistMass);


    // Histograms for dimuons
    fHistEvents = new TH1F("fHistEvents","fHistEvents;N_{events}",100,0.,10000.);

    fOutputList->Add(fHistEvents);

    PostData(1, fOutputList);           // postdata will notify the analysis manager of changes / updates to the
                                        // fOutputList object. the manager will in the end take care of writing your output to file
                                        // so it needs to know what's in the output
}
//_____________________________________________________________________________
void AliAnalysisTaskMyTask::UserExec(Option_t *)
{
    // user exec
    // this function is called once for each event
    // the manager will take care of reading the events from file, and with the static function InputEvent() you
    // have access to the current event.
    // once you return from the UserExec function, the manager will retrieve the next event from the chain

    Int_t Event=0;
    Int_t TrigEvent=0;
    ofstream s_detail, m_detail, l_detail;
    s_detail.open ("s-esd-detail.dat",std::ofstream::app);
    m_detail.open ("m-esd-detail.dat",std::ofstream::app);
    l_detail.open ("l-esd-detail.dat",std::ofstream::app);


    fESD = dynamic_cast<AliESDEvent*>(InputEvent());    // get an event (called fESD) from the input file

                                                        // there's another event format (ESD) which works in a similar way


    if(!fESD) return;                                   // if the pointer to the event is empty (getting it failed) skip this event
        // example part: i'll show how to loop over the tracks in an event
        // and extract some information from them which we'll store in a histogram

    Int_t iTracks(fESD->GetNumberOfTracks());           // see how many tracks there are in the event

    Double_t Vx = 0.01 * fESD->GetPrimaryVertex()->GetX();	// gets vertexes from individual events, in METERS
    Double_t Vy = 0.01 * fESD->GetPrimaryVertex()->GetY();
    Double_t Vz = 0.01 * fESD->GetPrimaryVertex()->GetZ();
    Double_t MagneticField = 0.1 * fESD->GetMagneticField();	// gets magnetic field, in TESLA


/*

Assumed Units: Mass (GeV/c^2)[CONFIRMED] || Energy (GeV) || Momentum (GeV/c) || Charge (* 1.6*10^-19 C)

*/

    if(smallEventID == esd_event_id) {
	     if(iTracks >= 15 && iTracks <= 30) {smallEventID = -1;}
	     else {smallEventID++;}
    } else {smallEventID = -2;}

    if(mediumEventID == esd_event_id) {
	     if(iTracks >= 100 && iTracks <= 300) {mediumEventID = -1;}
	     else {mediumEventID++;}
    } else {mediumEventID = -2;}

    if(largeEventID == esd_event_id) {
	     if(iTracks >= 5000 && iTracks <= 50000) {largeEventID = -1;}
	     else {largeEventID++;}
    } else {largeEventID = -2;}

    for(Int_t i(0); i < iTracks; i++) {                 // loop over all these tracks

	      if(smallEventID == -1 || mediumEventID == -1 || largeEventID == -1) { // when we get to the selected event, fill histograms and write data

      		AliESDtrack* track = static_cast<AliESDtrack*>(fESD->GetTrack(i));         // get a track (type AliESDtrack) from the event

      		if(!track) continue;                            // if we failed, skip this track

      		Double_t Mass = track->M(); // returns the pion mass, if the particle can't be identified properly
      		Double_t Energy = track->E(); // Returns the energy of the particle given its assumed mass, but assumes the pion mass if the particle can't be identified properly.

      		Double_t Px = track->Px();
      		Double_t Py = track->Py();
      		Double_t Pt = track->Pt(); // transversal momentum, in case we need it
      		Double_t Pz = track->Pz();

      		Double_t Charge = track->Charge();

          if (smallEventID == -1) {
        		// Add VERTEX (x, y, z), MASS, CHARGE and MOMENTUM (x, y, z) to esd-detail.dat file
        		s_detail << Vx << " " << Vy << " " << Vz << " ";
        		s_detail << Mass << " " << Charge << " ";
        		s_detail << Px << " " << Py << " " << Pz << endl;
          }

          if (mediumEventID == -1) {
        		// Add VERTEX (x, y, z), MASS, CHARGE and MOMENTUM (x, y, z) to esd-detail.dat file
        		m_detail << Vx << " " << Vy << " " << Vz << " ";
        		m_detail << Mass << " " << Charge << " ";
        		m_detail << Px << " " << Py << " " << Pz << endl;
          }

          if (largeEventID == -1) {
        		// Add VERTEX (x, y, z), MASS, CHARGE and MOMENTUM (x, y, z) to esd-detail.dat file
        		l_detail << Vx << " " << Vy << " " << Vz << " ";
        		l_detail << Mass << " " << Charge << " ";
        		l_detail << Px << " " << Py << " " << Pz << endl;


        		fHistPt->Fill(Pt);                     // plot the pt value of the track in a histogram

        		fHistMass->Fill(Mass);
          }

      }

    }


    Event++;
    esd_event_id++; // Increment global esd_event_id
    fHistEvents->Fill(Event);
    s_detail.close();
    m_detail.close();
    l_detail.close();

                                                       // continue until all the tracks are processed
    PostData(1, fOutputList);                           // stream the results the analysis of this event to
                                                        // the output manager which will take care of writing
                                                        // it to a file
}
//_____________________________________________________________________________
void AliAnalysisTaskMyTask::Terminate(Option_t *)
{
    // terminate
    // called at the END of the analysis (when all events are processed)
}
//_____________________________________________________________________________
