I64 FunctionSymbolAdd(I64 a,I64 b=7)
{
  return a+b;
}
U0 FSLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 FSCheck()
{
  CHashFun *f=HashFind("FunctionSymbolAdd",Fs->hash_table,HTT_FUN);
  CDbgInfo *dbg;I64 values[6],mask=0;U8 *s;
  MemSet(values,0,sizeof(values));
  if(f) {
    if(f->type&HTT_FUN)mask|=1;
    if(!StrCmp(f->str,"FunctionSymbolAdd"))mask|=2;
    if(f->arg_cnt==2)mask|=4;
    if(f->return_class && f->return_class->raw_type==RT_I64)mask|=8;
    if(f->exe_addr==&FunctionSymbolAdd)mask|=16;
    if(FunctionSymbolAdd(35)==42)mask|=32;
    if(dbg=f->dbg_info) {
      values[1]=1;
      values[2]=dbg->max_line>=dbg->min_line;
      values[3]=dbg->body[0]!=0;
      values[4]=dbg->body[dbg->max_line+1-dbg->min_line]>dbg->body[0];
    }
  }
  values[0]=mask;values[5]=sizeof(U32);
  s=MStrPrint("EXPORT symbol.bin %X %X\n",values,sizeof(values));FSLog(s);Free(s);
  FSLog("FUNCTION SYMBOL DONE\n");Sleep(1000);
}
