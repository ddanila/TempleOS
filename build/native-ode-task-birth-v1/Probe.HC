U0 ODERingReport(U8 *label,CTask *task)
{
  U8 line[160],*p;
  StrPrint(line,"ODE RING %s %X %X %X\n",
      label,&task->next_ode,task->next_ode,task->last_ode);
  for(p=line;*p;p++)OutU8(0xE9,*p);
}

U0 ODERingChild(I64)
{
  ODERingReport("spawn",Fs);
}

U0 ODERingProbe()
{
  ODERingReport("console",Fs);
  TaskWait(Spawn(&ODERingChild));
}
