U8 do_text[8192];I64 do_size;
I64 do_returns[4],do_restore[3];
U0 DOLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
CTask *do_owner;
U8 do_meta[4096];
Bool DOCapture(U8 *text)
{
  I64 n;
  if(Fs!=do_owner)return FALSE;
  n=StrLen(text);if(do_size+n>=sizeof(do_text))throw('DOCap',TRUE);
  MemCpy(do_text+do_size,text,n);do_size+=n;do_text[do_size]=0;return FALSE;
}
Bool DOKey(I64 ch,I64)
{
  U8 text[2];text[0]=ch;text[1]=0;
  if(ch)DOCapture(text);return FALSE;
}
U0 DOMetadata(U8 *mask,U8 *name)
{
  CDirEntry *e=FilesFind(mask),*next;
  CDateStruct ds;
  U8 *p=do_meta,*s;
  while(e) {
    Date2Struct(&ds,e->datetime+local_time_offset);
    StrPrint(p,"%s\t%s\t%X\t%X\t%X\t%d\t%d\t%d\t%d\t%d\t%d\n",e->name,e->full_name,e->size,e->clus,e->attr,ds.year,ds.mon,ds.day_of_mon,ds.hour,ds.min,ds.sec);p+=StrLen(p);
    next=e->next;DirEntryDel(e);e=next;
  }
  *p=0;s=MStrPrint("EXPORT %s %X %X\n",name,do_meta,p-do_meta+1);DOLog(s);Free(s);Sleep(300);
}
U0 DOProbe()
{
  U8 *old=DirCur,*s;
  CDoc *old_put=DocPut,*doc=DocNew("DirOutput.DD");
  CKeyDevEntry *hook;
  I64 zone=local_time_offset;
  U8 *base=MStrPrint("%C:/DirOutputProbe",Drv2Let);
  if(!Cd(base))throw('DOCd',TRUE);
  Free(base);
  Fs->put_doc=doc;local_time_offset=0;do_owner=Fs;hook=KeyDevAdd(&DOKey,&DOCapture,0x10000001,FALSE);
  DOMetadata("*","dir-default-meta.bin");do_size=0;do_returns[0]=Dir;do_text[do_size]=0;
  s=MStrPrint("EXPORT dir-default.bin %X %X\n",do_text,do_size+1);DOLog(s);Free(s);Sleep(300);
  DOMetadata("*","dir-full-meta.bin");do_size=0;do_returns[1]=Dir("*",TRUE);
  s=MStrPrint("EXPORT dir-full.bin %X %X\n",do_text,do_size+1);DOLog(s);Free(s);Sleep(300);
  DOMetadata("NO.*","dir-empty-meta.bin");do_size=0;do_returns[2]=Dir("NO.*");
  s=MStrPrint("EXPORT dir-empty.bin %X %X\n",do_text,do_size+1);DOLog(s);Free(s);Sleep(300);
  DOMetadata("*.TXT","dir-mask-meta.bin");do_size=0;do_returns[3]=Dir("*.TXT");
  s=MStrPrint("EXPORT dir-mask.bin %X %X\n",do_text,do_size+1);DOLog(s);Free(s);Sleep(300);
  KeyDevRem(hook);do_owner=NULL;Fs->put_doc=old_put;local_time_offset=zone;DocDel(doc);
  do_restore[0]=Cd(old);s=DirCur;do_restore[0]=do_restore[0] && !StrCmp(s,old);Free(s);Free(old);
  do_restore[1]=DocPut==old_put && local_time_offset==zone;
  do_restore[2]=FileFind("::/DirOutputProbe/ONE.TXT");
  s=MStrPrint("EXPORT dir-restore.bin %X %X\n",do_restore,sizeof(do_restore));DOLog(s);Free(s);
  s=MStrPrint("EXPORT dir-returns.bin %X %X\n",do_returns,sizeof(do_returns));DOLog(s);Free(s);DOLog("DIR OUTPUT DONE\n");
}
