#ifndef COMPILER_LEX_STATE_INCLUDED
#define COMPILER_LEX_STATE_INCLUDED
#include "/Compiler/LexFiles.HH"
public extern U0 LexPrepareSnapshot(CCmpCtrl *cc);
public extern U0 LexSnapshotCopy(CCmpCtrl *cc,CLexFile *snapshot);
public extern U0 LexSnapshotAttach(CCmpCtrl *cc,CLexFile *snapshot);
public extern CLexFile *LexSnapshotDetach(CCmpCtrl *cc);
public extern CLexFile *LexSnapshotRestore(CCmpCtrl *cc);
#endif
