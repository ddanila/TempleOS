U0 TDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 TextDemoActions()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*doc=DocNew;
  CDocEntry *entry,*link=0,*button=0;
  I64 action,result,mask=0,a,b;
  Fs->put_doc=doc;
  ExeFile("::/Demo/DolDoc/TextDemo.HC");
  Fs->put_doc=put;
  for(entry=doc->head.next;entry!=doc;entry=entry->next) {
    if(entry->de_flags&DOCEF_LINK)link=entry;
    if(!button && entry->de_flags&DOCEF_LEFT_EXP)button=entry;
  }
  if(link && button)mask|=1;
  if(button) {
    doc->cmd_U8=CH_SPACE;
    action=0;
    result=DocEntryRun(doc,button,TRUE,&action);
    if(action && result==1 && ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD && a==1)mask|=2;
  }
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  DocDel(doc);
  U8 *line=MStrPrint("TEXTDEMO MASK %d\n",mask);
  TDLog(line);Free(line);
}
TextDemoActions;
