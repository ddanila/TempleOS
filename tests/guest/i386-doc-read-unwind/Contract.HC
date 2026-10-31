I64 DocReadUnwindContract()
{
  I64 base,i,hits=0,mask=0;
  CDoc *doc;
  doc=DocRead("::/Probe/NoSuchDocument.DD");
  if(doc)DocDel(doc);
  base=Fs->data_heap->used_u8s;
  for(i=0;i<3;i++) {
    try {
      doc=DocRead("::/Probe/NoSuchDocument.DD");
      if(doc)DocDel(doc);
      throw('Probe',TRUE);
    } catch {
      if(Fs->except_ch=='Probe') { Fs->catch_except=TRUE; hits++; }
      else throw;
    }
  }
  if(hits==3)mask|=1;
  if(Fs->data_heap->used_u8s==base)mask|=2;
  return mask;
}
