U0 SELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 SourceErrorCheck(U8 *path)
{
  I64 mask=0,initial=-1,macro=-1,changed=-1;
  CHash *symbol;
  ExeFile(path);
  symbol=HashFind("BootCount",Fs->hash_table,HTT_GLBL_VAR);
  if(symbol) {
    initial=ExePutS("BootCount;");
    if(initial==39)mask|=1;
  }
  if(!HashFind("bad",Fs->hash_table,HTT_GLBL_VAR))mask|=2;
  macro=ExePutS("BOOT_SEEN;");
  if(macro==7)mask|=4;
  if(symbol) {
    ExePutS("BootCount=41;");
    changed=ExePutS("++BootCount;");
    if(changed==42 && ExePutS("BootCount;")==42)mask|=8;
  }
  SELog(MStrPrint("SOURCE ERROR RESULT %d %d %d %d\n",mask,initial,macro,changed));
  if(mask!=15)throw('SrcErr',TRUE);
  SELog("SOURCE ERROR DONE\n");
}
