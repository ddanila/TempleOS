I64 DocumentIncludeCleanup(U8 drive,Bool include_errors=TRUE)
{
  U8 *good=MStrPrint("#include \"%c:/DocIncludeCase/Size.HC\"\n",drive),
     *bad=MStrPrint("#include \"%c:/DocIncludeCase/Bad.HC\"\n",drive);
  CCmpCtrl *outer=Fs->last_cc;I64 i,before,mask=0;Bool ok=TRUE;
  if(ExePutS(good,"Warm.HC")!=4)goto cleanup_done;
  before=Fs->data_heap->used_u8s;
  for(i=0;i<3;i++)if(ExePutS(good,"Repeat.HC")!=4)ok=FALSE;
  if(ok)mask|=1;
  if(Fs->data_heap->used_u8s==before)mask|=2;
  if(Fs->last_cc==outer)mask|=4;
  if(include_errors) {
    if(ExePutS(bad,"Bad.HC")==0 && Fs->last_cc==outer)mask|=8;
    if(ExePutS(good,"After.HC")==4 && Fs->last_cc==outer)mask|=16;
  }
cleanup_done:
  Free(good);Free(bad);return mask;
}
