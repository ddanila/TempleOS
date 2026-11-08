#ifndef I386_AOT_RELEASE_INCLUDED
#define I386_AOT_RELEASE_INCLUDED
U0 I386AOTDel(CAOT *aot)
{
  CAOTImportExport *ie,*next;
  CAOTHeapGlbl *hg,*hg_next;
  if (!aot) return;
  for (ie=aot->next_ie;ie!=&aot->next_ie;ie=next) {
    next=ie->next; Free(ie->str); Free(ie->src_link); Free(ie);
  }
  for (hg=aot->heap_glbls;hg;hg=hg_next) {
    hg_next=hg->next; LinkedLstDel(hg->references); Free(hg->str); Free(hg);
  }
  LinkedLstDel(aot->abss); Free(aot->buf); Free(aot);
}
#endif
