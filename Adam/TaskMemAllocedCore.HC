public I64 TaskMemAlloced(CTask *task=NULL,Bool override_validate=FALSE)
{//Count of bytes alloced to a task, used+unused.
  I64 res;
  if (!task) task=Fs;
  if (override_validate || TaskValidate(task)) {
    res=task->code_heap->alloced_u8s;
    if (task->code_heap!=task->data_heap)
      res+=task->data_heap->alloced_u8s;
    return res;
  } else
    return 0;
}
