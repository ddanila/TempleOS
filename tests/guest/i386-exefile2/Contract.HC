I64 ExeFile2Contract()
{
  I64 mask=0,v=0;
  v=ExePutS2("19+23;");
  if(v==42)mask|=1;
  try {ExePutS2("throw('EF2');");}
  catch {if(Fs->except_ch=='EF2')mask|=4;Fs->catch_except=TRUE;}
  if(ExeFile2("::/Probe/EF2Case")==42)mask|=8;
  if(ExeFile2("::/Probe/EF2Case.HC",CCF_CMD_LINE)==42)mask|=16;
  try {ExeFile2("::/Probe/EF2Bad.HC");}
  catch {if(Fs->except_ch=='EF2')mask|=32;Fs->catch_except=TRUE;}
  try {ExePutS2("throw('Compiler',TRUE);");}
  catch {if(Fs->except_ch=='Compiler')mask|=128;Fs->catch_except=TRUE;}
  try {ExePutS2("throw('Break',TRUE);");}
  catch {if(Fs->except_ch=='Break')mask|=256;Fs->catch_except=TRUE;}
  if(ExePutS2("6*7;")==42)mask|=64;
  return mask;
}
