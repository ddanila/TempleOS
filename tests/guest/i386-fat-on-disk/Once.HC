U0 FDReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool FDFile(U8 *name,U8 *data)
{
 U8 *path=MStrPrint("C:/%s",name),*read;I64 size;CDirEntry e;Bool ok;
 ok=TRUE;if(!FD_REOPEN)ok=FileWrite(path,data,StrLen(data))>0;
 read=FileRead(path,&size);ok=ok && read && size==StrLen(data) && !MemCmp(read,data,size);
 Free(read);MemSet(&e,0,sizeof(e));ok=FileFind(path,&e) && ok && e.size==StrLen(data);Free(e.full_name);Free(path);return ok;
}
CBlkDev *fd_bd=BlkDevNextFreeSlot('C',BDT_ATA);
I64 fd_mask=0,fd_i;U8 *fd_line,*fd_filler;Bool fd_fill_ok;CDirEntry fd_invalid;
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
 }
}
fd_line=MStrPrint("FAT DISK MASK %d\n",fd_mask);FDReport(fd_line);Free(fd_line);FDReport("DONE fat disk\n");
