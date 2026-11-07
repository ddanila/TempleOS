U0 FixSet(U8 *filename,I64 line)
{//Compiler calls this to set file line for Fix
  U8 *st=MStrPrint("FL:%s,%d",filename,line);
  while (LBts(&sys_semas[SEMA_FIX],0))
    Yield;
  Free(dbg.fix_file_line);
  dbg.fix_file_line=AStrNew(st);
  Free(st);
  LBtr(&sys_semas[SEMA_FIX],0);
}

