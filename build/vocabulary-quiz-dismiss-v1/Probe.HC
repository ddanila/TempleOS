U0 VQOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 VQWatch(CTask *owner)
{
  while(sys_focus_task==owner)Sleep(1);
  VQOut("VOCAB definition popup\n");
  while(sys_focus_task!=owner)Sleep(1);
  VQOut("VOCAB definition closed\n");
}

U0 VQProbe()
{
  CTask *watch;
  if(acd.num_words<10000 || !acd.word_lst) {
    VQOut("FAIL Vocabulary dictionary unavailable\n");
    return;
  }
  watch=Spawn(&VQWatch,Fs,"Vocabulary test observer");
  VQOut("VOCAB opening\n");
  VocabQuiz;
  Kill(watch);
  VQOut("VOCAB returned\n");
}
