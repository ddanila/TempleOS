I64 FramePtr(U8 *name,CTask *task=NULL)
{//Find entry in task->hash_table, Return user_data.
  CHashGeneric *tmph;
  if (!task) task=Fs;
  if (tmph=HashFind(name,task->hash_table,HTT_FRAME_PTR))
    return tmph->user_data0;
  else
    return 0;
}

CHashGeneric *FramePtrAdd(U8 *name,I64 val=0,CTask *task=NULL)
{//Add named value to task->hash_table.
  return HashGenericAdd(name,HTT_FRAME_PTR,val,0,0,task);
}

I64 FramePtrSet(U8 *name,I64 val,CTask *task=NULL)
{//Find hash entry in task->hash_table. Change user_data0.
  CHashGeneric *tmph;
  if (!task) task=Fs;
  if (tmph=HashFind(name,task->hash_table,HTT_FRAME_PTR))
    return LXchgI64(&tmph->user_data0,val);
  else
    return 0;
}

I64 FramePtrDel(U8 *name,CTask *task=NULL)
{//Remove entry and delete.
  CHashGeneric *tmph;
  I64 res=0;
  if (!task) task=Fs;
  if (tmph=HashFind(name,task->hash_table,HTT_FRAME_PTR)) {
    res=tmph->user_data0;
    HashRemDel(tmph,task->hash_table);
  }
  return res;
}
