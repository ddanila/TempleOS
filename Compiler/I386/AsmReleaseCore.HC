#ifndef I386_ASM_RELEASE_INCLUDED
#define I386_ASM_RELEASE_INCLUDED
U0 I386AsmFree(CAOT *aot)
{
  CAOTImportExport *ie,*next;
  for(ie=aot->next_ie;ie!=&aot->next_ie;ie=next) {
    next=ie->next;
    QueRem(ie); Free(ie->str); Free(ie->src_link); Free(ie);
  }
  Free(aot->buf);
  QueRem(aot); Free(aot);
}
#endif
