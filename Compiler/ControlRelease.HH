#ifndef COMPILER_CONTROL_RELEASE_INCLUDED
#define COMPILER_CONTROL_RELEASE_INCLUDED
#include "/Compiler/LexFiles.HH"
//Exclusive valid control. Owned allocations are distinct; snapshots borrow payloads.
//Code-generation queues and borrowed symbol tables retain their existing lifetimes.
public extern U0 CmpCtrlRelease(CCmpCtrl *cc,CLexFileRelease *owner);
#endif
