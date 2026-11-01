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
Bool FDFile(U8 *name,U8 *data)
{
 U8 *path=MStrPrint("C:/%s",name),*read;I64 size;CDirEntry e;Bool ok;
 ok=TRUE;if(!FD_REOPEN)ok=FileWrite(path,data,StrLen(data))>0;
 read=FileRead(path,&size);ok=ok && read && size==StrLen(data) && !MemCmp(read,data,size);
 Free(read);MemSet(&e,0,sizeof(e));ok=FileFind(path,&e) && ok && e.size==StrLen(data);Free(e.full_name);Free(path);return ok;
}
CBlkDev *fd_bd=BlkDevNextFreeSlot('C',BDT_ATA);
I64 fd_mask=0,fd_i;U8 *fd_line,*fd_filler,*fd_second="second";Bool fd_fill_ok;CDirEntry fd_invalid;
if(FD_ALIAS_SHADOW && FD_REOPEN)fd_second="fourth";
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
     (FD_ALIAS_STREAM && FD_REOPEN || FDFile("twinabcdefghijklmnop2",fd_second)) &&
     FDFile("twinabcdefghijklmnop1","first") &&
     (FD_ALIAS_STREAM && FD_REOPEN || FDFile("twinabcdefghijklmnop2",fd_second)) &&
     (FD_ALIAS_DELETE && FD_REOPEN || FDFile("twinabcdefghijklmnop3","third")))fd_mask|=128;
  if(FD_ALIAS_SHADOW && FDRead("twinab~1.efg",fd_second) &&
     FDFile("TWINAB~1.EFG","fourth") && FDRead("twinabcdefghijklmnop2","fourth"))fd_mask|=256;
  if(FD_ALIAS_DELETE) {
   if(!FD_REOPEN)Del("C:/twinab~2.efg",,,FALSE);
   if(!FileFind("C:/twinabcdefghijklmnop3") && !FileFind("C:/TWINAB~2.EFG"))fd_mask|=512;
  }
  if(FD_ALIAS_STREAM && FDStream(FD_REOPEN))fd_mask|=1024;
 }
}
fd_line=MStrPrint("FAT DISK MASK %d\n",fd_mask);FDReport(fd_line);Free(fd_line);FDReport("DONE fat disk\n");
