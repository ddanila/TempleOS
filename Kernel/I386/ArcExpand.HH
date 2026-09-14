#ifndef I386_ARC_EXPAND_INCLUDED
#define I386_ARC_EXPAND_INCLUDED
#include "/Kernel/I386/Arc.HH"
//Existing initialized control, valid dictionary/stack and well-formed compressed codes.
//Reads only the declared input bits; no allocation, termination byte or archive validation.
//Internal code reader leaves src_pos unchanged and reports short/invalid fields as -1.
public extern I64 I386ArcReadCode(CArcCtrl *c);
public extern Bool I386ArcExpandBuf(CArcCtrl *c);
#endif
