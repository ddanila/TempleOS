U0 Report(U8 *s) { while(*s) OutU8(0xE9,*s++); }
U0 DumpTask()
{
  CHashClass *c=HashFind("CTask",Fs->hash_table,HTT_CLASS);
  CMemberLst *m;
  U8 *s=MStrPrint("TASK SIZE %d\n",sizeof(CTask));
  Report(s); Free(s);
  s=MStrPrint("TASK AUX %d %d %d %d %d\n",sizeof(CCPU),sizeof(CTaskStk),
    sizeof(CTaskDying),sizeof(CJobCtrl),sizeof(CWinScroll));
  Report(s); Free(s);
  for(m=c->member_lst_and_root;m;m=m->next) {
    s=MStrPrint("TASK FIELD %s %d %d %d %d\n",m->str,m->offset,m->size,m->member_class->ptr_stars_cnt,m->dim.total_cnt);
    Report(s); Free(s);
  }
  Report("DONE task layout\n");
}
DumpTask;
