U8 size_base[128];
I64 size_stored,size_directory,size_base_directory;
Bool FileSizeSetup(I64 drive)
{
  U8 *old=DirCur,*root=MStrPrint("%C:/",drive),*base=MStrPrint("%C:/SizeCase",drive);
  U8 *data=MAlloc(2000);
  CDirEntry entry;
  I64 i;
  Bool ok;
  for(i=0;i<2000;i++)data[i]='Q';
  ok=Cd(root) && DirMk("SizeCase") && Cd(base) && DirMk("Sub");
  ok=ok && FileWrite("Plain.DATA",data,513)>0 && FileWrite("Pack.DATA.Z",data,2000)>0;
  FileWrite("Empty.DATA",data,0);
  ok=ok && FileFind("Empty.DATA") && FileWrite("Sub/Leaf.DATA","ABC",3)>0;
  if(FileFind("Pack.DATA.Z",&entry)) {
    size_stored=entry.size;Free(entry.full_name);
  } else ok=FALSE;
  if(FileFind("Sub",&entry)) {
    size_directory=entry.size;Free(entry.full_name);
  } else ok=FALSE;
  if(FileFind(base,&entry)) {
    size_base_directory=entry.size;Free(entry.full_name);
  } else ok=FALSE;
  StrCpy(size_base,base);ok=Cd(old) && ok;
  Free(data);Free(old);Free(root);Free(base);
  return ok && size_stored>0 && size_stored<2000 && size_directory>0;
}
I64 FileSizeCase(I64 mode)
{
  U8 *query,*flags="+s",*cwd=DirCur,*after;
  I64 expected=0,round_to=0,actual,before,mask=0;
  switch(mode) {
    case 0:query=MStrPrint("%s/Plain.DATA",size_base);expected=513;break;
    case 1:query=MStrPrint("%s/Pack.DATA.Z",size_base);expected=size_stored;break;
    case 2:query=MStrPrint("%s/Pack.DATA.Z",size_base);flags="+s+x";expected=2000;break;
    case 3:query=MStrPrint("%s/Pack.DATA.Z",size_base);flags="+s+x";round_to=512;
      expected=(size_stored+511)/512*512;break;
    case 4:query=MStrPrint("%s/Plain.DATA",size_base);round_to=512;expected=1024;break;
    case 5:query=MStrPrint("%s/Empty.DATA",size_base);flags="+s+x";break;
    case 6:query=MStrPrint("%s/Missing.DATA",size_base);break;
    case 7:query=MStrPrint("%s/*",size_base);flags="+r";
      expected=513+size_stored+size_directory+3;break;
    case 8:query=MStrPrint("%s/*",size_base);flags="-r";
      expected=513+size_stored+size_directory+size_base_directory;break;
    case 9:query=MStrPrint("%s/*",size_base);flags="+r+F";
      expected=513+size_stored+3;break;
    case 10:query=MStrPrint("%s/Sub/../Plain.DATA",size_base);expected=513;break;
    case 11:query=MStrPrint("%s/*",size_base);flags="+r+x";round_to=512;
      expected=1024+(size_stored+511)/512*512+(size_directory+511)/512*512+512;break;
    case 12:query=MStrPrint("%s/Plain.DATA",size_base);round_to=0x100000000;expected=0x100000000;break;
    case 13:query=MStrPrint("%s/Sub",size_base);expected=size_directory;break;
    default:Free(cwd);return 0;
  }
  Size(query,flags,round_to); //Warm any persistent device-cache allocations.
  before=Fs->data_heap->used_u8s;
  actual=Size(query,flags,round_to);
  if(actual==expected)mask|=1;
  after=DirCur;if(!StrCmp(cwd,after))mask|=4;Free(after);
  if(Fs->data_heap->used_u8s==before)mask|=2;
  Free(query);Free(cwd);return mask;
}

I64 FileFlagsContract()
{
  U8 bits[16],*list=CAlloc(512),*next=list;
  I64 i,mask=0,before;
  Bool caught=FALSE;
  for(i=0;i<70;i++){StrPrint(next,"F%d",i);next+=StrLen(next)+1;}
  MemSet(bits,0,16);
  before=Fs->data_heap->used_u8s;
  ScanFlags(bits,list,NULL);if(!Bt(bits,0) && !Bt(bits,69))mask|=1;
  ScanFlags(bits,list,"+F0+F69-F0");if(!Bt(bits,0) && Bt(bits,69))mask|=2;
  ScanFlags(bits,list,"ignored+F2 -F69");if(Bt(bits,2) && !Bt(bits,69))mask|=4;
  try {ScanFlags(bits,list,"+F1+NoSuchFlag");}
  catch {caught=Fs->except_ch=='ScanFlag';Fs->catch_except=TRUE;}
  if(caught && Bt(bits,1) && Bt(bits,2))mask|=8;
  caught=FALSE;
  try {ScanFlags(bits,list,"+-");}
  catch {caught=Fs->except_ch=='ScanFlag';Fs->catch_except=TRUE;}
  ScanFlags(bits,list,"+");ScanFlags(bits,list,"-");
  if(caught && Fs->data_heap->used_u8s==before && Bt(bits,1) && Bt(bits,2))mask|=16;
  Free(list);return mask;
}
