U0 PrsI386DataRange(CCmpCtrl *cc,I64 start,I64 size)
{//Retain data boundaries independently of named exports.
  CAOTImportExport *ie;
  if (!(cc->flags&CCF_TARGET_I386) || !(cc->flags&CCF_AOT_COMPILE) || !size) return;
  ie=CAlloc(sizeof(CAOTImportExport));
  ie->type=IET_I386_DATA; ie->rip=start; ie->flags=size;
  QueIns(ie,cc->aot->last_ie);
}
