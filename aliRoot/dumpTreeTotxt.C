// Exemplo obtido de https://stackoverflow.com/questions/28970124/cern-root-exporting-data-to-plain-text
#include <iostream>
#include "TFile.h"
#include "TTree.h"
#include <fstream>
using namespace std;

void dumpTreeTotxt(){
  TFile *f=new TFile("AliESDs.root"); // opens the root file
  TTree *tr=(TTree*)f->Get("esdTree"); // creates the TTree object
  //tr->Scan(); // prints the content on the screen

  float a,b,c; // create variables of the same type as the branches you want to access

  tr->SetBranchAddress("AliESDRun",&a); // for all the TTree branches you need this
//  tr->SetBranchAddress("AliESDHeader",&b);
  //tr->SetBranchAddress("nserr",&c);

  ofstream myfile;
  myfile.open ("example.txt");
  //myfile << "TS ns nserr\n";

  for (int i=0;i<tr->GetEntries();i++){
    // loop over the tree

    cout   << "Event: " << i <<  endl; //print to the screen
    myfile << "Event: " << i <<  endl; //write to file
    tr->GetEntry(i);
  }
  myfile.close();
}
