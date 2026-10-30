I64 dc_drive;
I64 DirCurContract()
{
  U8 *old=DirCur,*root,*first,*second,*wanted,*name,*buffer;
  I64 mask=0;
  name=MStrPrint("%c:/",dc_drive);Cd(name);Free(name);
  root=DirCur;
  wanted=MStrPrint("%c:/",dc_drive);
  if(root && !StrCmp(root,wanted))mask|=1;
  Free(wanted);
  DirMk("CurrentDirContract");Cd("CurrentDirContract");
  first=DirCur;second=DirCur(Fs,Fs);
  wanted=MStrPrint("%c:/CurrentDirContract",dc_drive);
  if(first && !StrCmp(first,wanted))mask|=2;
  if(second && !StrCmp(second,wanted) && first!=second)mask|=4;
  if(first)first[0]='X';
  if(second && !StrCmp(second,wanted))mask|=8;
  buffer=DirCur;
  if(buffer && !StrCmp(buffer,wanted))mask|=16;
  Cd(old);Free(old);Free(root);Free(first);Free(second);Free(wanted);Free(buffer);
  return mask;
}
