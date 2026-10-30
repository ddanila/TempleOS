I64 cfs_drive;
I64 CFileStreamContract()
{
  U8 *name,*data,*in,*file;CFile *f;I64 i,size,mask=0;
  name=MStrPrint("%c:/cfile-stream.DATA",cfs_drive);
  data=MAlloc(1536);in=MAlloc(1536);
  for(i=0;i<1536;i++)data[i]=(i*17+i/512)&255;
  f=FOpen(name,"w",3);
  if(f && f->flags&FF_WRITE && f->flags&FF_CONTIGUOUS && f->max_blk==2)mask|=1;
  if(f && FBlkWrite(f,data,FFB_NEXT_BLK,3) && f->fblk_num==3)mask|=2;
  if(f && !FBlkWrite(f,data,3,1) && f->fblk_num==3)mask|=128;
  FClose(f);
  f=FOpen(name,"r");
  if(f && FSize(f)==1536 && f->max_blk==2 && f->fblk_num==0 && !(f->flags&FF_WRITE))mask|=4;
  if(f && FBlkRead(f,in,1,1) && !MemCmp(in,data+512,512) && f->fblk_num==2 &&
      FBlkRead(f,in,FFB_NEXT_BLK,1) && !MemCmp(in,data+1024,512) && f->fblk_num==3)mask|=8;
  if(f && !FBlkRead(f,in,FFB_NEXT_BLK,1) && f->fblk_num==3 &&
      FBlkRead(f,in,0,1) && !MemCmp(in,data,512))mask|=16;
  if(f && !FBlkWrite(f,data,0,1) && FBlkRead(f,in,0,0) && f->fblk_num==1)mask|=256;
  FClose(f);
  f=FOpen(name,"rc");
  if(f && f->flags&FF_CONTIGUOUS && FBlkRead(f,in,2,1) && !MemCmp(in,data+1024,512))mask|=512;
  FClose(f);
  f=FOpen(name,"w+");
  MemSet(data,0xAD,512);
  if(f && FBlkWrite(f,data,0,1))mask|=32;
  FClose(f);file=FileRead(name,&size);
  if(file && size==1536 && !MemCmp(file,data,1536))mask|=64;
  Free(file);FClose(NULL);Free(data);Free(in);Free(name);return mask;
}
