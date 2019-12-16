// Run:
//
// $ aliroot -q -b "runAnalysis.C(selected-event)"
//
// 'selected-event' is the desired event number inside the ESD file
// Leaving it blank will select event 0
//

int runAnalysis(int selected_event=0)
{
    ofstream esd_detail, s_event;

    s_event.open ("s-event.dat");
    s_event << selected_event;
    s_event.close();

    esd_detail.open ("esd-detail.dat");
    esd_detail.close();

    // since we will compile a class, tell root where to look for headers
    gROOT->ProcessLine(".include $ROOTSYS/include");
    gROOT->ProcessLine(".include $ALICE_ROOT/include");

    // create the analysis manager
    AliAnalysisManager *mgr = new AliAnalysisManager("testAnalysis");
    AliESDInputHandler *esdH = new AliESDInputHandler();
    mgr->SetInputEventHandler(esdH);

    // compile the class (locally)
    gROOT->LoadMacro("AliAnalysisTaskMyTask.cxx++g");
    // load the addtask macro
    gROOT->LoadMacro("AddMyTask.C");
    // create an instance of your analysis task
    AliAnalysisTaskMyTask *task = AddMyTask();

    if(!mgr->InitAnalysis()) return;
    mgr->SetDebugLevel(2);
    mgr->PrintStatus();
    mgr->SetUseProgressBar(1, 25);

    // if you want to run locally, we need to define some input
    TChain* chain = new TChain("esdTree");
    // add a few files to the chain (change this so that your local files are added)
    chain->Add("AliESDs.root");
    // start the analysis locally, reading the events from the tchain
    mgr->StartAnalysis("local", chain);

    remove("s-event.dat");

    exit();
}
