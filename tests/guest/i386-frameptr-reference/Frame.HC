Bool FPReady,FPStop;I64 FPFinal;
U0 FPEnd(){I64 *p=FramePtr("FPExit");if(p){FPFinal=*p;Free(p);}Exit;}
U0 FPExitWorker(U8 *data){FramePtrAdd("FPExit",data);Fs->task_end_cb=&FPEnd;}
U0 FPWorker(U8 *unused){FPReady=TRUE;while(!FPStop)Sleep(10);}
I64 FPContract()
{
  I64 mask=0;CTask *child;CHashGeneric *entry;
  if(FramePtr("FPTest")==0 && FramePtrDel("FPTest")==0 && FramePtrSet("FPTest",7)==0)mask|=1;
  entry=FramePtrAdd("FPTest",42);
  if(entry && FramePtr("FPTest")==42 && entry->user_data0==42)mask|=2;
  if(FramePtrSet("FPTest",0x123456789ABCDEF0)==42 && FramePtr("FPTest")==0x123456789ABCDEF0)mask|=4;
  if(FramePtrDel("FPTest")==0x123456789ABCDEF0 && FramePtr("FPTest")==0)mask|=8;
  entry=HashGenericAdd("FPGeneric",HTT_FRAME_PTR,12,34,56);
  if(entry && FramePtr("FPGeneric")==12 && entry->user_data1==34 && entry->user_data2==56 && FramePtrDel("FPGeneric")==12)mask|=16;
  FPReady=FPStop=FALSE;child=Spawn(&FPWorker,NULL,"Frame worker",-1,Fs,8192);
  if(child) {
    while(!FPReady)Sleep(10);
    entry=FramePtrAdd("FPChild",77,child);
    if(entry && FramePtr("FPChild",child)==77 && FramePtr("FPChild",Fs)==0)mask|=32;
    if(FramePtrSet("FPChild",88,child)==77 && FramePtrDel("FPChild",child)==88 && !FramePtr("FPChild",child))mask|=64;
    FPStop=TRUE;Sleep(50);
  }
  FPFinal=0;entry=MAlloc(sizeof(I64));*(entry)(I64 *)=91;
  child=Spawn(&FPExitWorker,entry,"Frame exit",-1,Fs,8192);
  if(child){while(!FPFinal)Sleep(10);if(FPFinal==91)mask|=128;}else Free(entry);
  return mask;
}
I64 FPCheck(){I64 v=FPContract;if(v!=255)throw('FramePtr',TRUE);return v;}
