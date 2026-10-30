I64 BirthWait(CTask **_task,I64 task_num=-1)
{//Wait for task valid and not task_num.
  while (!TaskValidate(*_task)||(*_task)->task_num==task_num)
    Yield;
  return (*_task)->task_num;
}

U0 DeathWait(CTask **_task,Bool send_exit=FALSE)
{//Wait for task death.
  if (send_exit && TaskValidate(*_task)) {
    TaskWait(*_task,TRUE);
    XTalk(*_task,"Exit;\n");
  }
  while (TaskValidate(*_task))
    Yield;
}

