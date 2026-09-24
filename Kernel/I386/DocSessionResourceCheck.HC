I64 doc_session_resource_hits,doc_session_data_used,doc_session_code_used,
    doc_session_data_reserved,doc_session_code_reserved,
    doc_session_heap_base,doc_session_heap_peak,doc_session_heap_reserved_peak;

U0 DocSessionResourceHit()
{
  doc_session_resource_hits++;
}

U0 DocSessionResourceFill(CDoc *doc,U8 *source)
{
  while(*source) DocPutKey(doc,*source++);
}

I64 DocSessionResourceCheck()
{//Warm once, then require every complete session cycle to return the data heap.
  CDoc *doc=NULL;
  I64 cycle,size,data_used=0,code_used=0;
  U8 *saved;
  doc_session_resource_hits=0;
  for(cycle=0;cycle<=20;cycle++) {
    doc=DocNew("C:/SessionCycle.HC",Fs);
    if(!doc) return -1;
    DocSessionResourceFill(doc,"DocSessionResourceHit;");
    if(!DocWrite(doc)) { DocDel(doc); return -2; }
    DocDel(doc); doc=NULL;
    doc=DocRead("C:/SessionCycle.HC");
    if(!doc) return -3;
    DocPutKey(doc,' ');
    saved=DocSave(doc,&size);
    if(!saved || size!=24 || saved[22]!=' ' || saved[23]!=5) {
      Free(saved); DocDel(doc); return -4;
    }
    Free(saved);
    if(!DocWrite(doc) || !DocExe(doc)) { DocDel(doc); return -5; }
    DocDel(doc); doc=NULL;
    doc=DocNew("C:/SessionFailure.HC",Fs);
    if(!doc) return -6;
    DocSessionResourceFill(doc,"throw('Test');");
    if(DocExe(doc)) { DocDel(doc); return -7; }
    DocDel(doc); doc=NULL;
    if(!cycle) {
      data_used=Fs->data_heap->used_u8s;
      code_used=Fs->code_heap->used_u8s;
      doc_session_data_used=data_used;
      doc_session_code_used=code_used;
      doc_session_data_reserved=Fs->data_heap->alloced_u8s;
      doc_session_code_reserved=Fs->code_heap->alloced_u8s;
      if(Fs->data_heap!=Fs->code_heap || !MemMeasureStart(Fs)) return -50;
    }
    else if(Fs->data_heap->used_u8s!=data_used) return -8-cycle;
    else if(Fs->code_heap->used_u8s!=code_used) return -29-cycle;
  }
  if(!MemMeasureStop(&doc_session_heap_base,&doc_session_heap_peak,
      &doc_session_heap_reserved_peak) ||
      doc_session_heap_peak<=doc_session_heap_base ||
      doc_session_heap_reserved_peak<doc_session_heap_peak) return -51;
  return doc_session_resource_hits;
}
