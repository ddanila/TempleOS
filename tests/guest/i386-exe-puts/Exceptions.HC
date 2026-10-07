I64 JRContract()
{
  I64 mask=0;
  if(ExePutS("throw('Break',TRUE);","Break.HC")==0)mask|=1;
  if(ExePutS("throw('Compiler',TRUE);","Compiler.HC")==0)mask|=2;
  try {ExePutS("throw('EUUser',TRUE);","User.HC");}
  catch {
    if(Fs->except_ch=='EUUser')mask|=4;
    Fs->catch_except=TRUE;
  }
  return mask;
}
