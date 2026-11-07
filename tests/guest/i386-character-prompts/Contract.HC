U0 CPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool CPText(CDoc *doc,U8 *expected)
{
  CDocEntry *e=doc->head.next;
  U8 text[256],*s;
  I64 n=0;
  while(e!=doc) {
    if(e->type_u8==DOCT_TEXT) {
      s=e->tag;while(*s && n<255)text[n++]=*s++;
    } else if(e->type_u8==DOCT_NEW_LINE && n<255)text[n++]='\n';
    e=e->next;
  }
  text[n]=0;return !StrCmp(text,expected);
}
U0 CPCheck()
{
  I64 v[12],sc=-1,used=Fs->data_heap->used_u8s;
  CDoc *saved=DocPut,*doc=DocNew("CharacterPrompts.DD");
  U8 *s;
  Fs->put_doc=doc;FlushMsgs;
  Msg(MSG_KEY_DOWN,0,0x3B);Msg(MSG_KEY_UP,'x',0xAD);Msg(MSG_KEY_DOWN,'a',0x1E);
  v[0]=GetChar(&sc,FALSE)=='a';v[1]=sc==0x1E;v[2]=CPText(doc,"");
  Msg(MSG_KEY_DOWN,'b',0x30);v[3]=GetChar(&sc)=='b' && sc==0x30;
  v[4]=CPText(doc,"b");DocRst(doc,TRUE);
  Msg(MSG_KEY_DOWN,'x',0x2D);Msg(MSG_KEY_DOWN,'y',0x15);
  v[5]=YorN;v[6]=CPText(doc,"(y or n)? YES\n");DocRst(doc,TRUE);
  Msg(MSG_KEY_DOWN,'N',0x31);v[7]=!AreYouSure;
  v[8]=CPText(doc,"ARE YOU SURE (y or n)? NO\n");DocRst(doc,TRUE);
  Msg(MSG_KEY_DOWN,0,0x3C);Msg(MSG_KEY_DOWN,'z',0x2C);
  v[9]=PressAKey=='z';v[10]=CPText(doc,"PRESS A KEY\n");
  FlushMsgs;Fs->put_doc=saved;DocDel(doc);v[11]=Fs->data_heap->used_u8s==used;
  s=MStrPrint("EXPORT character-prompts.bin %X %X\n",v,sizeof(v));CPLog(s);Free(s);
  CPLog("CHARACTER PROMPTS DONE\n");Sleep(1000);
}
U0 CPHardware()
{
  I64 v[3],sc;
  U8 *s;
  FlushMsgs;CPLog("CHARACTER HARDWARE ready\n");
  v[0]=GetChar(&sc,FALSE);v[1]=sc&127;
  v[2]=!Bt(&Fs->task_flags,TASKf_IDLE);
  s=MStrPrint("EXPORT hardware-character.bin %X %X\n",v,sizeof(v));CPLog(s);Free(s);
  CPLog("CHARACTER HARDWARE DONE\n");Sleep(1000);
}
