U0 VQOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 VQWatch(CTask *owner)
{
  while(sys_focus_task==owner)Sleep(1);
  VQOut("VOCAB definition popup\n");
  while(sys_focus_task!=owner)Sleep(1);
  VQOut("VOCAB definition closed\n");
}

CTask *vocab_watch=Spawn(&VQWatch,Fs,"Vocabulary test observer");
Seed(1);
VQOut("VOCAB opening\n");
