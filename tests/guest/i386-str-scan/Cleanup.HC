I64 ss_cleanup_delta;
I64 StringScanContract()
{
  I64 i,caught=0,base=Fs->data_heap->used_u8s,mask=0;
  CCmpCtrl *first=Fs->next_cc,*last=Fs->last_cc;
  for(i=0;i<10;i++) {
    try { StrScan("42","%d"); }
    catch {
      if(Fs->except_ch=='Scan')caught++;
      Fs->catch_except=TRUE;
    }
  }
  if(caught==10)mask|=1;
  ss_cleanup_delta=Fs->data_heap->used_u8s-base;
  if(!ss_cleanup_delta)mask|=2;
  if(Fs->next_cc==first&&Fs->last_cc==last)mask|=4;
  return mask;
}
