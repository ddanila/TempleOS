public extern Bool I386RawBlocks(CDrv *drive,U8 *buffer,I64 block,I64 count,Bool write);
I64 RawBlocksContract()
{
  CDrv *dv=Fs->cur_dv;CDirEntry de;U8 *data,*read,*whole;
  I64 i,size,mask=0,old_flags;
  data=MAlloc(1024);read=MAlloc(1024);
  for(i=0;i<1024;i++)data[i]=(i*13+7)&255;
  if(!FileWrite("C:/raw-block-probe.DATA",data,1024) ||
      !FileFind("C:/raw-block-probe.DATA",&de,FUF_JUST_FILES))goto raw_test_done;
  if(de.size==1024 && I386RawBlocks(dv,read,de.clus,2,FALSE) && !MemCmp(data,read,1024))mask|=1;
  if(!I386RawBlocks(dv,read,dv->drv_offset+dv->size,1,FALSE) &&
      !I386RawBlocks(dv,read,-1,1,FALSE) && !I386RawBlocks(dv,read,de.clus,-1,FALSE))mask|=2;
  if(I386RawBlocks(dv,NULL,de.clus,0,FALSE) && !I386RawBlocks(dv,NULL,de.clus,1,FALSE))mask|=4;
  for(i=0;i<512;i++)data[512+i]=(i*7+31)&255;
  if(I386RawBlocks(dv,data+512,de.clus+1,1,TRUE) &&
      I386RawBlocks(dv,read,de.clus,2,FALSE) && !MemCmp(data,read,1024))mask|=8;
  whole=FileRead("C:/raw-block-probe.DATA",&size);
  if(whole && size==1024 && !MemCmp(whole,data,1024))mask|=16;
  Free(whole);
  if(DrvLock(dv)) {
    if(I386RawBlocks(dv,read,de.clus,1,FALSE) && dv->owning_task==Fs && dv->bd->owning_task==Fs)mask|=32;
    DrvUnlock(dv);
  }
  old_flags=dv->bd->flags;dv->bd->flags|=BDF_READ_ONLY;
  if(!I386RawBlocks(dv,data,de.clus,1,TRUE))mask|=64;
  dv->bd->flags=old_flags;
  Free(de.full_name);
raw_test_done:
  Free(data);Free(read);return mask;
}
