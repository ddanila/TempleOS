I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0;
  CCmpCtrl *boundary=Fs->last_cc;
  try {ExePrint("throw('%s',TRUE);","EPFail");}
  catch {
    if(Fs->except_ch=='EPFail')mask|=1;
    Fs->catch_except=TRUE;
  }
  if(Fs->last_cc==boundary)mask|=2;
  if(Fs->data_heap->used_u8s==base)mask|=4;
  return mask;
}
