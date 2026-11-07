U0 RRLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 RRExport(U8 *name,U8 *bytes,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,bytes,size);RRLog(s);Free(s);}
U0 RRCheck()
{
  CHash *h=HashFind("RawDr",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
  U0 (*dump)(CTask *task);
  CTask *task;CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  U8 *cache,*image,*name;I64 i,j,col,flags,state[8];U32 run_level;
  Bool raw,suspended;
  if(!h){RRLog("RAW REGISTERS UNAVAILABLE\n");return;}
  if(h->type&HTT_FUN)dump=h(CHashFun *)->exe_addr;else dump=h(CHashExport *)->val;
  if(!dump){RRLog("RAW REGISTERS UNAVAILABLE\n");return;}
  task=CAlloc(sizeof(CTask));
  for(i=0;i<16;i++)*TaskRegAddr(task,i)=0x10203040+i;
  task->rip=0x12345678;
  image=CAlloc(38400);cache=text.raw_scrn_image;
  col=text.raw_col;flags=text.raw_flags;run_level=sys_run_level;
  raw=Raw(OFF);suspended=Suspend(sys_winmgr_task);
  for(j=0;j<2;j++) {
    MemSet(image,0,38400);text.raw_scrn_image=image;text.raw_col=17;text.raw_flags=0;
    if(j)LBts(&sys_run_level,RLf_COMPILER);else LBtr(&sys_run_level,RLf_COMPILER);
    (*dump)(task);
    state[j*4]=text.raw_col;state[j*4+1]=IsRaw;state[j*4+2]=text.raw_flags;
    state[j*4+3]=DocPut==put && DocDisplay==display && DocBorder==border;
    sys_run_level=run_level;text.raw_scrn_image=cache;
    name=MStrPrint("raw-registers-%d.bin",j);RRExport(name,image,38400);Free(name);Sleep(1000);
  }
  text.raw_scrn_image=cache;text.raw_col=col;text.raw_flags=flags;
  Raw(raw);Suspend(sys_winmgr_task,suspended);Free(task);Free(image);
  RRExport("raw-registers-state.bin",state,sizeof(state));
  RRLog("RAW REGISTERS DONE\n");Sleep(1000);
}
