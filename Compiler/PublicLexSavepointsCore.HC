#include "/Compiler/LexState.HC"
U0 LexPush(CCmpCtrl *cc)
{//Create token-stream save point. Preserve the existing allocation/failure order.
  CLexFile *snapshot;
  LexPrepareSnapshot(cc);
  snapshot=MAllocIdent(cc->lex_include_stk);
  LexSnapshotAttach(cc,snapshot);
}
U0 LexPopRestore(CCmpCtrl *cc)
{//Caller must not cross an include-file boundary while restoring a save point.
  Free(LexSnapshotRestore(cc));
}
U0 LexPopNoRestore(CCmpCtrl *cc)
{
  Free(LexSnapshotDetach(cc));
}

