U0 FXLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 FXCheck(){U8 *old=dbg.fix_file_line,*s;U8 name[64];I64 mask=0;
dbg.fix_file_line=NULL;
try {StrCpy(name,"C:/Probe/First.HC");FixSet(name,17);
if(!StrCmp(dbg.fix_file_line,"FL:C:/Probe/First.HC,17"))mask|=1;
name[0]='X';if(dbg.fix_file_line[3]=='C')mask|=2;
FixSet("C:/Probe/Last.HC",-3);
if(!StrCmp(dbg.fix_file_line,"FL:C:/Probe/Last.HC,-3"))mask|=4;
if(!Bt(&sys_semas[SEMA_FIX],0))mask|=8;
}catch{}
Free(dbg.fix_file_line);dbg.fix_file_line=old;
s=MStrPrint("EXPORT fix-set-mask.bin %X 8\n",&mask);FXLog(s);Free(s);
FXLog("FIX SET DONE\n");Sleep(1000);}
