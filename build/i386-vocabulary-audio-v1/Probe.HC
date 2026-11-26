U0 VQOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 VQWatch(CTask *owner)
{
  I64 i;
  for(i=0;i<2;i++) {
    while(sys_focus_task==owner)Sleep(1);
  VQOut("VOCAB definition popup\n");
  while(sys_focus_task!=owner)Sleep(1);
    VQOut("VOCAB definition closed\n");
  }
}

U0 VQExport()
{
  I64 size;
  U8 *source=DocSave(DocPut,&size);
  U8 *line=MStrPrint("EXPORT vocabulary.DD %X %X\n",source,size);
  VQOut(line);
  Free(line);
  //Guest QMP copies the document bytes while this buffer remains live.
  Sleep(3000);
  Free(source);
}
CTask *vocab_watch=Spawn(&VQWatch,Fs,"Vocabulary test observer");
Seed(1);
VQOut("VOCAB opening\n");
