U0 DTLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 DTSeed(U8 *name)
{
  U8 *cwd=DirCur;
  DirMk(name);Cd(name);DirMk("Nested");DirMk("Empty");
  FileWrite("Alpha.TXT","alpha\n",6);
  FileWrite("Nested/Beta.BIN","\x00\x7F\x80\xFF",4);
  Cd(cwd);Free(cwd);
}
U0 DTCheck(U8 *base)
{
  U8 *old=DirCur,*cwd,*s,*data;I64 size,values[12];
  DirMk(base);Cd(base);DTSeed("Whole");
  values[0]=DelTree("Whole");
  values[1]=IsDir("Whole");
  values[2]=FileFind("Whole/Alpha.TXT",,FUF_JUST_FILES);
  DTSeed("Mask");FileWrite("Mask/Nested/Gamma.TXT","gamma\n",6);
  values[3]=DelTree("Mask/*.TXT");
  values[4]=FileFind("Mask/Alpha.TXT",,FUF_JUST_FILES);
  values[5]=FileFind("Mask/Nested/Gamma.TXT",,FUF_JUST_FILES);
  values[6]=FileFind("Mask/Nested/Beta.BIN",,FUF_JUST_FILES);
  values[7]=IsDir("Mask");values[8]=IsDir("Mask/Nested");values[9]=IsDir("Mask/Empty");
  values[10]=DelTree("Missing");
  cwd=DirCur;values[11]=!StrCmp(cwd,base);Free(cwd);
  data=FileRead("Mask/Nested/Beta.BIN",&size);
  if(!data)throw('TreeRead',TRUE);
  s=MStrPrint("EXPORT survivor.bin %X %X\n",data,size);DTLog(s);Free(s);
  s=MStrPrint("EXPORT counts.bin %X %X\n",values,sizeof(values));DTLog(s);Free(s);
  Cd(old);Free(old);DTLog("DEL TREE DONE\n");Sleep(1000);Free(data);
}
