void runAnalysis()
{
    // Erase output txt files
    ofstream s_detail, m_detail, l_detail;

    s_detail.open ("s-esd-detail.dat");
    s_detail << " " << endl;
    s_detail.close();

    m_detail.open ("m-esd-detail.dat");
    m_detail << " " << endl;
    m_detail.close();

    l_detail.open ("l-esd-detail.dat");
    l_detail << " " << endl;
    l_detail.close();

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
    chain->Add("AliESDs.root"); // Breno put it on the same directory that was cloned from Pezzi's 					// repository: AliESD_Example
    chain->Add("AliESDs2.root");

    //chain->Add("../root_files/AliAOD.Muons2.root");
    //chain->Add("../root_files/AliAOD.Muons3.root");
    //chain->Add("../root_files/AliAOD.Muons4.root");

    // start the analysis locally, reading the events from the tchain
    mgr->StartAnalysis("local", chain);


    exit();
}
