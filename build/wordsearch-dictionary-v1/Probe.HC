CDoc *ws_previous,*ws_capture;
U0 WSBegin()
{
  ws_previous=DocPut;
  ws_capture=DocNew;
  Fs->put_doc=ws_capture;
  Seed(1);
}
U0 WSEnd()
{
  I64 size;
  U8 *saved=DocSave(ws_capture,&size),line[100],*s;
  Fs->put_doc=ws_previous;
  StrPrint(line,"EXPORT wordsearch.dd %X %X\n",saved,size);
  for(s=line;*s;s++)OutU8(0xE9,*s);
  s="WORD SEARCH captured\n";
  while(*s)OutU8(0xE9,*s++);
}
