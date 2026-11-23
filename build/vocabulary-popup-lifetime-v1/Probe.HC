U0 VQOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 VQWatch(CTask *owner)
{
  CTask *definition;
  U8 line[160];
  while(sys_focus_task==owner)Sleep(1);
  definition=sys_focus_task;
  if(acd.num_words<10000 || !acd.word_lst)
    VQOut("FAIL Vocabulary dictionary unavailable\n");
  StrPrint(line,"VOCAB popup task %X %X %X %X\n",definition,
        &definition->task_signature,&definition->task_flags,&definition->display_flags);
  VQOut(line);
  VQOut("VOCAB definition popup\n");
  while(sys_focus_task!=owner)Sleep(1);
  VQOut("VOCAB definition closed\n");
}

U0 VQProbe()
{
  CTask *watch;
  U8 line[100];
  watch=Spawn(&VQWatch,Fs,"Vocabulary test observer");
  StrPrint(line,"VOCAB focus %X %X\n",Fs,&sys_focus_task);
  VQOut(line);
  VQOut("VOCAB opening\n");
  VocabQuiz;
  Kill(watch);
  VQOut("VOCAB returned\n");
}
