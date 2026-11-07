Bool dy_ready,dy_go,dy_stop,dy_consume;
I64 dy_seen,dy_calls;
U0 DYWorker()
{
  dy_ready=TRUE;
  while(!dy_go)Yield;
  dy_seen=1;
  while(!dy_stop)Yield;
}
Bool DYCallback(CDoc *doc,U8 *data,I64 ch,I64 sc)
{dy_calls++;return dy_consume;}
U0 DYLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DYCheck()
{
  I64 mode,flags,after,samples[5],masks[5];
  CDoc *doc,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *worker;U8 *s;
  for(mode=0;mode<5;mode++) {
    doc=DocNew("YieldProbe.DD");
    dy_ready=dy_go=dy_stop=FALSE;dy_seen=dy_calls=0;dy_consume=mode==2;
    if(mode==1)doc->flags|=DOCF_DONT_SWAP_OUT;
    if(mode==2 || mode==3)doc->user_put_key=&DYCallback;
    if(mode==4)DocLock(doc);
    worker=Spawn(&DYWorker,NULL,"Key yield observer",-1,Fs,16384);
    while(!dy_ready)Yield;
    flags=GetRFlags;SetRFlags(flags&~512);
    dy_go=TRUE;
    DocPutKey(doc,CH_CTRLC,SCF_CTRL|SCF_SHIFT);
    samples[mode]=dy_seen;after=GetRFlags;
    masks[mode]=0;
    if(samples[mode]==(mode==0 || mode==3 || mode==4))masks[mode]|=1;
    if(!(after&512))masks[mode]|=2;
    if(Bt(&doc->locked_flags,DOClf_LOCKED)==(mode==4))masks[mode]|=4;
    if(dy_calls==(mode==2 || mode==3))masks[mode]|=8;
    if(DocPut==put && DocDisplay==display && DocBorder==border)masks[mode]|=16;
    SetRFlags(flags);dy_stop=TRUE;
    while(TaskValidate(worker))Yield;
    if(!TaskValidate(worker))masks[mode]|=32;
    DocUnlock(doc);DocDel(doc);
  }
  s=MStrPrint("EXPORT yield-masks.bin %X %X\n",masks,sizeof(masks));DYLog(s);Free(s);
  s=MStrPrint("EXPORT yield-samples.bin %X %X\n",samples,sizeof(samples));DYLog(s);Free(s);
  DYLog("DOC KEY YIELD DONE\n");Sleep(1000);
}
