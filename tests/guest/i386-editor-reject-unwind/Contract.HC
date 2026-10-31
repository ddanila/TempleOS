I64 EditorRejectUnwind(I64 mode)
{
  I64 base=Fs->data_heap->used_u8s,i,hits=0,mask=0;U8 *link;
  if(mode==0)link="BF:NoSuchBook,1:1";
  else if(mode==1)link="MN:MN_LINK_MISSING";
  else link="ZZ:Unknown";
  for(i=0;i<3;i++) {
    try {
      if(Ed(link,EDF_BAIL))throw('BadEd',TRUE);
      throw('Probe',TRUE);
    } catch {
      if(Fs->except_ch=='Probe') {Fs->catch_except=TRUE;hits++;}
      else throw;
    }
  }
  if(hits==3)mask|=1;
  if(Fs->data_heap->used_u8s==base)mask|=2;
  return mask;
}
I64 EditorMissingVerseUnwind()
{
  I64 base=Fs->data_heap->used_u8s,i,hits=0,mask=0;Bool result;
  for(i=0;i<3;i++) {
    try {
      result=Ed("BF:Genesis,999999:1",EDF_BAIL);
      if(result)throw('BadEd',TRUE);
      throw('Probe',TRUE);
    } catch {
      if(Fs->except_ch=='Probe') {Fs->catch_except=TRUE;hits++;}
      else throw;
    }
  }
  if(hits==3)mask|=1;
  if(Fs->data_heap->used_u8s==base)mask|=2;
  return mask;
}
