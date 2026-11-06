U0 CTLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 CTExport(U8 *name,U8 *path)
{
  I64 size;U8 *data=FileRead(path,&size),*s;
  if(!data)throw('TreeRead',TRUE);
  s=MStrPrint("EXPORT %s %X %X\n",name,data,size);CTLog(s);Free(s);
  // Exported buffers stay live until this test task exits.
}
U0 CTCheck(U8 *base)
{
  U8 *old=DirCur,*s,*cwd;
  I64 values[7];
  DirMk(base);Cd(base);
  DirMk("Src");DirMk("Src/Nested");DirMk("Src/Empty");
  FileWrite("Src/Alpha.TXT","alpha\n",6);
  FileWrite("Src/Nested/Beta.BIN","\x00\x7F\x80\xFF",4);
  values[0]=CopyTree("Src","Dst");
  values[1]=CopyTree("Src","Src");
  values[2]=CopyTree("Src","Src/Forbidden");
  values[3]=IsDir("Dst/Empty");
  values[4]=IsDir("Src/Forbidden");
  cwd=DirCur;values[5]=!StrCmp(cwd,base);Free(cwd);
  values[6]=CopyTree("Src/Empty","EmptyCopy");
  CTExport("source-alpha.bin","Src/Alpha.TXT");
  CTExport("source-beta.bin","Src/Nested/Beta.BIN");
  CTExport("copied-alpha.bin","Dst/Alpha.TXT");
  CTExport("copied-beta.bin","Dst/Nested/Beta.BIN");
  s=MStrPrint("EXPORT counts.bin %X %X\n",values,sizeof(values));CTLog(s);Free(s);
  Cd(old);Free(old);CTLog("COPY TREE DONE\n");Sleep(1000);
}
