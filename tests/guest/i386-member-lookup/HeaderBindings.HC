U0 HBLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 HBAddress(U8 *name)
{
  CHashFun *fun=HashFind(name,Fs->hash_table,HTT_FUN);
  if(fun)return fun->exe_addr;
  return 0;
}
I64 *hb=CAlloc(6*8);
hb[0]=HBAddress("MemberFind");hb[1]=HBAddress("MemberMetaData");hb[2]=HBAddress("MemberMetaFind");
#include "/Compiler/MemberLookup.HH"
hb[3]=HBAddress("MemberFind");hb[4]=HBAddress("MemberMetaData");hb[5]=HBAddress("MemberMetaFind");
U8 *message=MStrPrint("EXPORT header-bindings.bin %X 30\n",hb);HBLog(message);Free(message);
HBLog("HEADER BINDINGS DONE\n");Sleep(1000);
