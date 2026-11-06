U8 *pe_output;
I64 pe_size;
U0 PECall(Bool catch_it)
{
  I64 i;
  Fs->except_ch='PE';
  for(i=0;i<8;i++)Fs->except_callers[i]=i+1;
  PutExcept(catch_it);
}
I64 PutExceptContract()
{
  CDoc *old=Fs->put_doc,*doc=DocNew;
  I64 mask=0,i,ch=Fs->except_ch,callers[8];
  Bool saved_catch=Fs->catch_except,raw=Raw(OFF),inner=FALSE,outer=FALSE;
  for(i=0;i<8;i++)callers[i]=Fs->except_callers[i];
  Fs->put_doc=doc;
  Fs->except_ch='PE';
  for(i=0;i<8;i++)Fs->except_callers[i]=i+1;
  Fs->catch_except=FALSE;
  PutExcept;
  if(Fs->catch_except)mask|=1;
  PECall(FALSE);
  if(!Fs->catch_except)mask|=2;
  try { throw('PE',TRUE); }
  catch { PECall(TRUE);inner=TRUE; }
  if(inner)mask|=4;
  try {
    try { throw('PE',TRUE); }
    catch { PECall(FALSE); }
    inner=FALSE;
  } catch { outer=TRUE;Fs->catch_except=TRUE; }
  if(outer && inner)mask|=8;
  if(Fs->except_ch=='PE')mask|=16;
  pe_output=DocSave(doc,&pe_size);
  Fs->put_doc=old;DocDel(doc);Raw(raw);
  Fs->except_ch=ch;Fs->catch_except=saved_catch;
  for(i=0;i<8;i++)Fs->except_callers[i]=callers[i];
  return mask;
}
