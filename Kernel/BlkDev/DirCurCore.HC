U8 *DirCur(CTask *task=NULL,CTask *mem_task=NULL)
{//MAlloc copy of cur dir with drv letter.
  U8 *st;
  if (!task) task=Fs;
  if (!task->cur_dir)
    return NULL;
  st=MAlloc(StrLen(task->cur_dir)+3,mem_task);
  *st=Drv2Let(task->cur_dv);
  st[1]=':';
  StrCpy(st+2,task->cur_dir);
  return st;
}

