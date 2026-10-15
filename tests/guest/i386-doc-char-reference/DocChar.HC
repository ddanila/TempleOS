I64 DCContract(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,want='A';
  CDoc *put=DocPut,*d=DocNew("Chars.DD");
  U8 *line,*expected="ABC";
  DocPrint(d,"ABC\nDEF\n");DocTop(d);DocRecalc(d);
  switch(mode) {
    case 0:break;
    case 1:EdCursorRight(d);want='B';break;
    case 2:EdCursorRight(d);EdCursorLeft(d);break;
    case 3:EdCharDel(d);expected="BC";want='B';break;
    case 4:EdCharIns('X',0,d);expected="XABC";break;
    case 5:EdLineDown(d);want='D';break;
    case 6:EdLineDown(d);EdLineUp(d);break;
    case 7:EdLineDel(d);expected="DEF";want='D';break;
  }
  if(EdCurU8(d)==want)m|=1;
  line=DocScanLine(d,d->head.next);
  if(line&&!StrCmp(line,expected))m|=2;
  Free(line);
  if(!Bt(&d->locked_flags,DOClf_LOCKED)&&!d->owning_task)m|=4;
  if(DocPut==put)m|=8;
  DocDel(d);
  if(Fs->data_heap->used_u8s==before)m|=16;
  return m;
}
I64 DCForm(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,a=0,b=0,res,has;
  I64 want=11,ch=CH_SPACE;
  CDoc *d=DocNew("FormChars.DD");
  CDocEntry *first=DocPrint(d,"$$MU,\"One\",LE=11,RE=12$$\n"),*second;
  Bool unlocked;
  second=DocPrint(d,"$$MU,\"Two\",LE=22,RE=23$$\n");
  d->flags|=DOCF_FORM;DocTop(d);DocRecalc(d);
  if(mode==1){ch=10;want=12;}
  if(mode==2){EdLineDown(d);want=22;}
  if(d->cur_entry==first&&mode!=2||d->cur_entry==second&&mode==2)m|=1;
  FlushMsgs;EdCharIns(ch,0,d);
  unlocked=!Bt(&d->locked_flags,DOClf_LOCKED)&&!d->owning_task;
  if(ScanMsg(&a,&b,1<<MSG_KEY_DOWN)==MSG_KEY_DOWN&&a==CH_ESC&&!b)m|=2;
  res=DocEntryRun(d,d->cur_entry,TRUE,&has);
  if(res==want&&has)m|=4;
  if(ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD&&a==want&&!b)m|=8;
  if(unlocked&&d->cmd_U8==CH_SPACE)m|=16;
  DocUnlock(d);DocDel(d);FlushMsgs;
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
