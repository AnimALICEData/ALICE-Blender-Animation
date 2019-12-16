/* Copyright(c) 1998-1999, ALICE Experiment at CERN, All rights reserved. */
/* See cxx source for full Copyright notice */
/* $Id$ */

#ifndef AliAnalysisTaskMyTask_H
#define AliAnalysisTaskMyTask_H
#include <sstream>

#include "AliAnalysisTaskSE.h"

class AliAnalysisTaskMyTask : public AliAnalysisTaskSE
{
    public:
                                AliAnalysisTaskMyTask();
                                AliAnalysisTaskMyTask(const char *name);
        virtual                 ~AliAnalysisTaskMyTask();

        virtual void            UserCreateOutputObjects();
        virtual void            UserExec(Option_t* option);
        virtual void            Terminate(Option_t* option);

    private:
        AliESDEvent*            fESD;           //! input event
        TList*                  fOutputList;    //! output list
        TH1F*                   fHistPt;        //! dummy histogram
	TH1F*			fHistMass;      //! my particle histogram!! :D
        TH1F*                   fHistEvents; // Number of events

        AliAnalysisTaskMyTask(const AliAnalysisTaskMyTask&); // not implemented
        AliAnalysisTaskMyTask& operator=(const AliAnalysisTaskMyTask&); // not implemented

        ClassDef(AliAnalysisTaskMyTask, 1);
};

#endif
