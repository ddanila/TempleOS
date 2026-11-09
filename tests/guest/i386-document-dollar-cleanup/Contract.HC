I64 DocumentDollarCleanup(U8 drive,Bool include_errors=TRUE)
{
  U8 *good=MStrPrint("#include \"%c:/DocDollarCase/Size.HC\"\n",drive),
     *bad=MStrPrint("#include \"%c:/DocDollarCase/Bad.HC\"\n",drive);
  CCmpCtrl *outer=Fs->last_cc;CDoc *old_doc=Fs->put_doc,*doc;
  I64 i,before,code_before,mask=0,irq=GetRFlags;Bool ok=TRUE,heap_ok=TRUE;
  if(ExePutS(good,"Warm.HC")!=4)goto cleanup_done;
  before=Fs->data_heap->used_u8s;
  for(i=0;i<3;i++)if(ExePutS(good,"Repeat.HC")!=4)ok=FALSE;
  if(ok)mask|=1;
  if(Fs->data_heap->used_u8s==before)mask|=2;
  if(Fs->last_cc==outer)mask|=4;
  if(include_errors) {
    before=Fs->data_heap->used_u8s;code_before=Fs->code_heap->used_u8s;
    ok=TRUE;
    for(i=0;i<3;i++) {
      doc=DocNew;Fs->put_doc=doc;
      if(ExePutS(bad,"Bad.HC")!=0 || Fs->last_cc!=outer)ok=FALSE;
      Fs->put_doc=old_doc;DocDel(doc);TaskWait(adam_task);
      if(Fs->data_heap->used_u8s!=before || Fs->code_heap->used_u8s!=code_before)heap_ok=FALSE;
      if((GetRFlags&0x200)!=(irq&0x200))heap_ok=FALSE;
    }
    if(ok)mask|=8;
    if(heap_ok)mask|=32;
    if(ExePutS(good,"After.HC")==4 && Fs->last_cc==outer)mask|=16;
    if(Fs->data_heap->used_u8s==before && Fs->code_heap->used_u8s==code_before &&
        Fs->put_doc==old_doc && (GetRFlags&0x200)==(irq&0x200))mask|=64;
  }
cleanup_done:
  Free(good);Free(bad);return mask;
}
