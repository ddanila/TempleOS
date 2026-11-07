CHash *fh_symbols[5];
U8 *fh_names="PopUpPickDir\0PopUpPickFile\0CopyTree\0DelTree\0Cd2DirEntry\0";
U0 FHSave()
{
  U8 *name=fh_names;I64 i;
  for(i=0;i<5;i++){fh_symbols[i]=HashFind(name,Fs->hash_table,HTT_FUN);name+=StrLen(name)+1;}
}
U0 FHCheck()
{
  U8 *name=fh_names,*cwd,*s;I64 i,mask=0;
  for(i=0;i<5;i++) {
    if(fh_symbols[i] && HashFind(name,Fs->hash_table,HTT_FUN)==fh_symbols[i])mask|=1<<i;
    name+=StrLen(name)+1;
  }
  cwd=DirCur;if(cwd && cwd[0]=='C' && cwd[1]==':')mask|=32;Free(cwd);
  s=MStrPrint("EXPORT file-header-mask.bin %X 8\n",&mask);
  name=s;while(*name)OutU8(0xE9,*name++);Free(s);
  name="FILE HEADER DONE\n";while(*name)OutU8(0xE9,*name++);Sleep(1000);
}
