U0 FDReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool FDRead(U8 *name,U8 *data)
{
 U8 *path=MStrPrint("C:/%s",name),*read;I64 size;Bool ok;
 read=FileRead(path,&size);ok=read && size==StrLen(data) && !MemCmp(read,data,size);
 Free(read);Free(path);return ok;
}
Bool FDStream(Bool reopen)
{
 U8 block[512],*a,*b;I64 as,bs;Bool ok=TRUE;CFile *f;
 MemSet(block,0,sizeof(block));MemCpy(block,"stream",6);
 if(!reopen) {
  f=FOpen("C:/twinab~1.efg","w",1);
  if(f) {ok=FBlkWrite(f,block,0,1);FClose(f);} else ok=FALSE;
 }
 a=FileRead("C:/TWINAB~1.EFG",&as);b=FileRead("C:/twinabcdefghijklmnop2",&bs);
 ok=ok && a && b && as==512 && bs==512 && !MemCmp(a,block,512) && !MemCmp(b,block,512);
 Free(a);Free(b);return ok;
}
Bool FDOverlapRead()
{
 U8 *a,*b,expected[1024];I64 as,bs;Bool ok;
 MemSet(expected,'B',512);MemSet(expected+512,'C',512);
 a=FileRead("C:/TWINAB~1.EFG",&as);b=FileRead("C:/twinabcdefghijklmnop2",&bs);
 ok=a && b && as==1024 && bs==1024 && !MemCmp(a,expected,1024) && !MemCmp(b,expected,1024);
 Free(a);Free(b);return ok;
}
Bool FDMergeRead()
{
 U8 *a,*b,expected[1536];I64 as,bs;Bool ok;
 MemSet(expected,'N',512);MemSet(expected+512,'B',512);MemSet(expected+1024,'C',512);
 a=FileRead("C:/TWINAB~1.EFG",&as);b=FileRead("C:/twinabcdefghijklmnop2",&bs);
 ok=a && b && as==1536 && bs==1536 && !MemCmp(a,expected,1536) && !MemCmp(b,expected,1536);
 Free(a);Free(b);return ok;
}
U8 fd_race_a[512],fd_race_b[512];Bool fd_race_go,fd_race_done[2],fd_race_ok[2];
U0 FDRaceWorker(U8 *arg)
{
 I64 i,n=arg(I64);U8 *path,*data;
 path="C:/twinabcdefghijklmnop2";data=fd_race_a;
 if(n) {path="C:/twinab~1.efg";data=fd_race_b;}
 while(!fd_race_go)Yield;
 for(i=0;i<8;i++) if(FileWrite(path,data,512)<=0)fd_race_ok[n]=FALSE;
 fd_race_done[n]=TRUE;
 while(TRUE)Yield;
}
Bool FDRace(Bool reopen)
{
 CTask *a=NULL,*b=NULL;U8 *one,*two,*line;I64 as,bs,deadline;Bool ok;
 MemSet(fd_race_a,'A',512);MemSet(fd_race_b,'B',512);
 if(!reopen) {
  fd_race_go=FALSE;fd_race_done[0]=FALSE;fd_race_done[1]=FALSE;
  fd_race_ok[0]=TRUE;fd_race_ok[1]=TRUE;
  a=Spawn(&FDRaceWorker,0,"FAT race A",-1,Fs,16384);
  b=Spawn(&FDRaceWorker,1,"FAT race B",-1,Fs,16384);
  fd_race_go=TRUE;deadline=cnts.jiffies+10000;
  while(a && b && (!fd_race_done[0] || !fd_race_done[1]) && cnts.jiffies<deadline)Yield;
  ok=a && b && fd_race_done[0] && fd_race_done[1] && fd_race_ok[0] && fd_race_ok[1];
  if(a)Kill(a);if(b)Kill(b);
  if(!ok)return FALSE;
 }
 one=FileRead("C:/TWINAB~1.EFG",&as);two=FileRead("C:/twinabcdefghijklmnop2",&bs);
 ok=one && two && as==512 && bs==512 && !MemCmp(one,two,512) &&
   (!MemCmp(one,fd_race_a,512) || !MemCmp(one,fd_race_b,512));
 if(ok) {line=MStrPrint("FAT RACE %c\n",*one);FDReport(line);Free(line);}
 Free(one);Free(two);return ok;
}
Bool FDFile(U8 *name,U8 *data)
{
 U8 *path=MStrPrint("C:/%s",name),*read;I64 size;CDirEntry e;Bool ok;
 ok=TRUE;if(!FD_REOPEN)ok=FileWrite(path,data,StrLen(data))>0;
 read=FileRead(path,&size);ok=ok && read && size==StrLen(data) && !MemCmp(read,data,size);
 Free(read);MemSet(&e,0,sizeof(e));ok=FileFind(path,&e) && ok && e.size==StrLen(data);Free(e.full_name);Free(path);return ok;
}
CBlkDev *fd_bd=BlkDevNextFreeSlot('C',BDT_ATA);
I64 fd_mask=0,fd_i;U8 *fd_line,*fd_filler,*fd_second="second";Bool fd_fill_ok;CDirEntry fd_invalid;
CDirEntry fd_entry;U8 fd_new_block[512],fd_overlap[1536];I64 fd_tail,fd_prefix;CDrv *fd_dv;Bool fd_lock;
if(FD_ALIAS_SHADOW && FD_REOPEN)fd_second="fourth";
if(FD_ALIAS_REPLACE && FD_REOPEN)fd_second="newer!";
fd_bd->base0=0x1F0;fd_bd->base1=0x3F6;fd_bd->unit=0;
if(BlkDevAdd(fd_bd,0,FALSE,TRUE)==1 && Let2Drv('C')->fs_type==FSt_FAT32)fd_mask|=1;
if(fd_mask&1) {
 if(FDFile("SHORT.TXT","short"))fd_mask|=2;
 if(FDFile("alphaabcdefghijklmnopqrs","twenty-four"))fd_mask|=4;
 if(FD_EXTENDED) {
  MemSet(&fd_invalid,0,sizeof(fd_invalid));StrCpy(fd_invalid.name,"bad/name");
  if(!DirNew(Let2Drv('C'),"/",&fd_invalid,FALSE))fd_mask|=64;
  if(FDFile("bravobcdefghijklmnopqrstuvwxyz","thirty"))fd_mask|=8;
  fd_fill_ok=TRUE;for(fd_i=0;fd_i<6;fd_i++){fd_filler=MStrPrint("F%02d.TXT",fd_i);if(!FDFile(fd_filler,"fill"))fd_fill_ok=FALSE;Free(fd_filler);}
  if(fd_fill_ok)fd_mask|=32;
  if(FDFile("charlieABCDEFGHIJKLMNOPQRSTUVWXYZ1234","thirty-seven"))fd_mask|=16;
  if(FD_COLLISIONS && FDFile("twinabcdefghijklmnop1","first") &&
     ((FD_ALIAS_STREAM || FD_ALIAS_OVERLAP || FD_ALIAS_MERGE || FD_RACE) && FD_REOPEN || FDFile("twinabcdefghijklmnop2",fd_second)) &&
     FDFile("twinabcdefghijklmnop1","first") &&
     ((FD_ALIAS_STREAM || FD_ALIAS_OVERLAP || FD_ALIAS_MERGE || FD_RACE) && FD_REOPEN || FDFile("twinabcdefghijklmnop2",fd_second)) &&
     (FD_ALIAS_DELETE && FD_REOPEN || FDFile("twinabcdefghijklmnop3","third")))fd_mask|=128;
  if(FD_ALIAS_SHADOW && FDRead("twinab~1.efg",fd_second) &&
     FDFile("TWINAB~1.EFG","fourth") && FDRead("twinabcdefghijklmnop2","fourth"))fd_mask|=256;
  if(FD_ALIAS_DELETE) {
   if(!FD_REOPEN)Del("C:/twinab~2.efg",,,FALSE);
   if(!FileFind("C:/twinabcdefghijklmnop3") && !FileFind("C:/TWINAB~2.EFG"))fd_mask|=512;
  }
  if(FD_ALIAS_STREAM && FDStream(FD_REOPEN))fd_mask|=1024;
  if(FD_ALIAS_DIRNEW) {
   if((FD_ALIAS_OVERLAP || FD_ALIAS_MERGE) && !FD_REOPEN) {
    MemSet(fd_overlap,'A',512);MemSet(fd_overlap+512,'B',512);MemSet(fd_overlap+1024,'C',512);
    FileWrite("C:/twinabcdefghijklmnop2",fd_overlap,sizeof(fd_overlap));
   }
   fd_fill_ok=FileFind("C:/twinabcdefghijklmnop2",&fd_entry);
   if(fd_fill_ok) {
    if(!FD_REOPEN) {
     StrCpy(fd_entry.name,"TWINAB~1.EFG");
     DirNew(Let2Drv('C'),"/",&fd_entry,FALSE);
     DirNew(Let2Drv('C'),"/",&fd_entry,TRUE);
     if(FD_ALIAS_OVERLAP) {
      fd_entry.clus=ClusNumNext(Let2Drv('C'),fd_entry.clus);
      fd_entry.size=1024;
      DirNew(Let2Drv('C'),"/",&fd_entry,TRUE);
     }
     if(FD_ALIAS_MERGE) {
      fd_dv=Let2Drv('C');fd_tail=ClusNumNext(fd_dv,fd_entry.clus);
      fd_prefix=ClusAlloc(fd_dv,0,1,FALSE);
      fd_line=MStrPrint("FAT MERGE %d %d %d\n",fd_entry.clus,fd_tail,fd_prefix);
      FDReport(fd_line);Free(fd_line);
      MemSet(fd_new_block,'N',512);ClusWrite(fd_dv,fd_new_block,fd_prefix,1);
      fd_lock=DrvLock(fd_dv);
      ClusNumNext(fd_dv,fd_prefix);
      fd_dv->cur_fat_blk[fd_prefix & 127]=fd_tail;
      BlkWrite(fd_dv,fd_dv->cur_fat_blk,fd_dv->fat1+fd_dv->cur_fat_blk_num,1);
      BlkWrite(fd_dv,fd_dv->cur_fat_blk,fd_dv->fat2+fd_dv->cur_fat_blk_num,1);
      if(fd_lock)DrvUnlock(fd_dv);
      fd_entry.clus=fd_prefix;fd_entry.size=1536;
      DirNew(fd_dv,"/",&fd_entry,TRUE);
     }
     if(FD_ALIAS_REPLACE) {
      MemSet(fd_new_block,0,sizeof(fd_new_block));MemCpy(fd_new_block,"newer!",6);
      fd_entry.clus=ClusAlloc(Let2Drv('C'),0,1,FALSE);
      ClusWrite(Let2Drv('C'),fd_new_block,fd_entry.clus,1);
      DirNew(Let2Drv('C'),"/",&fd_entry,TRUE);
     }
    }
    Free(fd_entry.full_name);
   }
   if(FD_ALIAS_REPLACE)fd_second="newer!";
   if(fd_fill_ok && (FD_ALIAS_OVERLAP && FDOverlapRead() || FD_ALIAS_MERGE && FDMergeRead() ||
      !FD_ALIAS_OVERLAP && !FD_ALIAS_MERGE && FDRead("TWINAB~1.EFG",fd_second) &&
      FDRead("twinabcdefghijklmnop2",fd_second)))fd_mask|=2048;
  }
  if(FD_LOCK_RETENTION) {
   if(!FD_REOPEN)FileWrite("C:/LOCK.TXT","lock",4);
   fd_dv=Let2Drv('C');fd_lock=DrvLock(fd_dv);
   Del("C:/LOCK.TXT",,,FALSE);
   fd_fill_ok=Bt(&fd_dv->locked_flags,DVlf_LOCKED) && fd_dv->owning_task==Fs;
   if(fd_fill_ok && !FD_REOPEN) {
    FileWrite("C:/LOCK.TXT","again",5);
    fd_fill_ok=Bt(&fd_dv->locked_flags,DVlf_LOCKED) && fd_dv->owning_task==Fs;
    fd_fill_ok=fd_fill_ok && FDRead("LOCK.TXT","again") &&
      Bt(&fd_dv->locked_flags,DVlf_LOCKED) && fd_dv->owning_task==Fs;
    Del("C:/LOCK.TXT",,,FALSE);
    fd_fill_ok=fd_fill_ok && Bt(&fd_dv->locked_flags,DVlf_LOCKED) && fd_dv->owning_task==Fs;
   }
   if(fd_fill_ok && fd_lock)DrvUnlock(fd_dv);
   if(fd_fill_ok && !FileFind("C:/LOCK.TXT"))fd_mask|=4096;
  }
  if(FD_RACE && FDRace(FD_REOPEN))fd_mask|=8192;
 }
}
fd_line=MStrPrint("FAT DISK MASK %d\n",fd_mask);FDReport(fd_line);Free(fd_line);FDReport("DONE fat disk\n");
