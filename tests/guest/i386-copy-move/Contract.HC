U0 CopyCheck(U8 *name,U8 *expected,I64 bytes,I64 datetime)
{
  CDirEntry de;I64 size;U8 *file;
  if(!FileFind(name,&de,FUF_JUST_FILES)||(!IsDotZ(name)&&de.size!=bytes)||
      (IsDotZ(name)&&!(de.attr&RS_ATTR_COMPRESSED))||de.datetime!=datetime)throw('CopyMeta',TRUE);
  Free(de.full_name);file=FileRead(name,&size);
  if(!file||size!=bytes||MemCmp(file,expected,bytes))throw('CopyData',TRUE);
  Free(file);
}
U0 CopyContract(I64 drive)
{
  U8 *base=MStrPrint("%C:/CopyProbe",drive),*dest=MStrPrint("%s/Dst",base);
  U8 *one=MStrPrint("%s/one.DATA",base),*two=MStrPrint("%s/two.DATA",base);
  U8 *empty=MStrPrint("%s/empty.DATA",base),*name,*query,*data=MAlloc(66313);
  I64 i,datetime=0x123456789ABCDEF0,empty_date,before;CDirEntry de;CFile *f;
  for(i=0;i<66313;i++)data[i]=i*17+i/512;
  if(!DirMk(base)||!DirMk(dest))throw('CopyDirs',TRUE);
  if(!FileWrite(one,data,66313,datetime)||!FileWrite(two,data+7,513,datetime))throw('CPWrite',TRUE);
  f=FOpen(empty,"w");if(!f)throw('CPEmpty',TRUE);FClose(f);
  if(!FileFind(empty,&de,FUF_JUST_FILES)||de.size)throw('CPEmpty2',TRUE);
  empty_date=de.datetime;Free(de.full_name);
  if(Copy(one,one))throw('CopySelf',TRUE);
  CopyCheck(one,data,66313,datetime);
  query=MStrPrint("%s/*.DATA",base);
  if(!Copy(query,dest))throw('CopyMask',TRUE);Free(query);
  name=DirCur;
  if(!Cd(dest)||!Copy(one)||!Cd(name))throw('CPDft',TRUE);Free(name);
  name=MStrPrint("%s/one.DATA",dest);CopyCheck(name,data,66313,datetime);Free(name);
  name=MStrPrint("%s/two.DATA",dest);CopyCheck(name,data+7,513,datetime);Free(name);
  name=MStrPrint("%s/empty.DATA",dest);CopyCheck(name,NULL,0,empty_date);Free(name);
  name=MStrPrint("%s/single.DATA",base);
  if(!CopySingle(one,name))throw('CPSingle',TRUE);CopyCheck(name,data,66313,datetime);Free(name);
  name=MStrPrint("%s/compressed.DATA.Z",base);
  if(!Copy(one,name))throw('CopyZ',TRUE);CopyCheck(name,data,66313,datetime);Free(name);
  name=MStrPrint("%s/moved.DATA",base);
  if(!Move(two,name)||FileFind(two))throw('CopyMove',TRUE);CopyCheck(name,data+7,513,datetime);Free(name);
  name=MStrPrint("%s/missing.DATA",base);
  if(Copy(name,one)||Move(name,one))throw('CPMiss',TRUE);
  before=Fs->data_heap->used_u8s;
  for(i=0;i<5;i++)if(Copy(name,one))throw('CPRepeat',TRUE);
  if(Fs->data_heap->used_u8s!=before)throw('CopyHeap',TRUE);
  Free(name);CopyCheck(one,data,66313,datetime);
  query=MStrPrint("%s/*",dest);if(Del(query,,,FALSE)!=3)throw('CPClean1',TRUE);Free(query);
  Del(dest,FALSE,TRUE,FALSE);if(FileFind(dest))throw('CPClean2',TRUE);
  query=MStrPrint("%s/*",base);if(Del(query,,,FALSE)!=5)throw('CPClean3',TRUE);Free(query);
  Del(base,FALSE,TRUE,FALSE);if(FileFind(base))throw('CPClean4',TRUE);
  Free(data);Free(base);Free(dest);Free(one);Free(two);Free(empty);
}
