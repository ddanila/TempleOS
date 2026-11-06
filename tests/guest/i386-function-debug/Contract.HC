U8 *fd_pc[2];
U0 FDCapture(I64 index) {fd_pc[index]=Caller;}
I64 FDTarget(I64 a)
{
  FDCapture(0);
  a+=7;
  FDCapture(1);
  return a;
}
U0 FDLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
Bool FDLine(CDbgInfo *dbg,I64 line,U8 *pc)
{
  I64 i,start,end;
  if(!dbg || line<dbg->min_line || line>dbg->max_line)return FALSE;
  i=line-dbg->min_line;start=dbg->body[i];
  if(!start)return FALSE;
  end=dbg->body[dbg->max_line+1-dbg->min_line];
  for(i++;i<=dbg->max_line-dbg->min_line;i++)
    if(dbg->body[i]>start) {end=dbg->body[i];break;}
  return start<(pc+0)(U64)<=end;
}
U0 FDCheck()
{
  I64 values[8];U8 *s;CHashFun *f,*before,*after;
  MemSet(values,0,sizeof(values));
  values[0]=FDTarget(35)==42;
  f=HashFind("FDTarget",Fs->hash_table,HTT_FUN);
  if(f) {
    if(f->dbg_info) {
      s=MStrPrint("EXPORT lines.bin %X %X\n",f->dbg_info,
        offset(CDbgInfo.body)+4*(f->dbg_info->max_line-f->dbg_info->min_line+2));FDLog(s);Free(s);
      s=MStrPrint("EXPORT pcs.bin %X %X\n",fd_pc,sizeof(fd_pc));FDLog(s);Free(s);
    }
    values[1]=FDLine(f->dbg_info,5,fd_pc[0]);
    values[2]=FDLine(f->dbg_info,7,fd_pc[1]);
    values[3]=fd_pc[0]!=fd_pc[1];
    if(f->dbg_info && f->dbg_info->min_line<=5 && f->dbg_info->max_line>=7)
      values[7]=0<f->dbg_info->body[5-f->dbg_info->min_line]<
        f->dbg_info->body[7-f->dbg_info->min_line];
  }
  ExePutS("extern I64 FDCompleted(I64 a=35);");
  before=HashFind("FDCompleted",Fs->hash_table,HTT_FUN);
  ExePutS("I64 FDCompleted(I64 a=35){return a+7;}");
  after=HashFind("FDCompleted",Fs->hash_table,HTT_FUN);
  values[4]=before && before==after;
  if(after && after->dbg_info)
    values[5]=after->dbg_info->body[0]==(after->exe_addr+0)(U64);
  values[6]=ExePutS("FDCompleted();")==42;
  s=MStrPrint("EXPORT debug.bin %X %X\n",values,sizeof(values));FDLog(s);Free(s);
  FDLog("FUNCTION DEBUG DONE\n");Sleep(1000);
}
