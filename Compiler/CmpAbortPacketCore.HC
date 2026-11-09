//Release one detached packet. Parent/child list ownership belongs to the caller.
U0 CmpAbortPacketDel(CAOT *aot,Bool owns_buffer)
{
  CAOTImportExport *ie,*next;
  CAOTHeapGlbl *hg,*next_hg;
  for(ie=aot->next_ie;ie!=&aot->next_ie;ie=next) {
    next=ie->next; Free(ie->str); Free(ie->src_link); Free(ie);
  }
  for(hg=aot->heap_glbls;hg;hg=next_hg) {
    next_hg=hg->next; LinkedLstDel(hg->references); Free(hg->str); Free(hg);
  }
  LinkedLstDel(aot->abss);
  //Buffer ownership is explicit; target invalid-address markers differ.
  if(owns_buffer) Free(aot->buf);
  Free(aot);
}
