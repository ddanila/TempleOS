I64 ed_mode=0,ed_drive=0,ed_forms=0,ed_menus=0;
Bool ed_saved=TRUE;
CDoc *ed_target=NULL;
U0 EDWrite(U8 *name,U8 *buffer,I64 size)
{
  I64 read_size,i;U8 *read;
  FileWrite(name,buffer,size);read=FileRead(name,&read_size);
  if(!read || read_size!=size)ed_saved=FALSE;
  else for(i=0;i<size;i++)if(read[i]!=buffer[i])ed_saved=FALSE;
  Free(read);
}
U0 EDSave(CDoc *doc,I64 index)
{
  I64 size;CDocEntry *entry;
  U8 *buffer=DocSave(doc,&size),*name=MStrPrint("%c:/editor-dialog%d.DD",ed_drive,index);
  U8 *text=StrNew(""),*old;
  EDWrite(name,buffer,size);Free(name);Free(buffer);
  for(entry=doc->head.next;entry!=doc;entry=entry->next)
    if(entry->tag) {
      old=text;text=MStrPrint("%s%d:%s\n",old,entry->type_u8,entry->tag);Free(old);
    }
  name=MStrPrint("%c:/editor-dialog%d.TXT",ed_drive,index);
  EDWrite(name,text,StrLen(text));Free(name);Free(text);
}
U0 EDDriver(CTask *caller)
{
  CDoc *doc;CDocEntry *entry,*chosen;
  CTask *popup;
  while(TRUE) {
    doc=caller->display_doc;
    if(!ed_forms && doc && doc!=ed_target && doc->desc=='Form' &&
        doc->win_task==caller && Bt(&caller->task_flags,TASKf_AWAITING_MSG)) {
      DocLock(doc);ed_forms++;
      if(ed_mode==0)EDSave(doc,0);
      if(ed_mode==2)EDSave(doc,1);
      if(ed_mode<2)
        for(entry=doc->head.next;entry!=doc;entry=entry->next)
          if(entry->type_u8==DOCT_DATA)DocDataFmt(doc,entry,3);
      DocUnlock(doc);
      if(ed_mode==1 || ed_mode==2)PostMsg(caller,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
      else PostMsg(caller,MSG_KEY_DOWN,CH_ESC,0);
      if(ed_mode<3)return;
    }
    popup=caller->popup_task;
    if(ed_forms && popup && TaskValidate(popup) &&
        Bt(&popup->task_flags,TASKf_AWAITING_MSG)) {
      doc=popup->display_doc;
      if(doc && doc->desc=='Menu' && doc->win_task==popup) {
        DocLock(doc);chosen=NULL;
        for(entry=doc->head.next;entry!=doc;entry=entry->next)
          if(entry->type_u8==DOCT_BTTN && entry->de_flags&DOCEF_LEFT_EXP &&
              entry->left_exp==2)chosen=entry;
        if(chosen) {
          ed_menus++;
          if(ed_mode==3)EDSave(doc,2);
          doc->cur_entry=chosen;doc->cur_col=0;DocUnlock(doc);
          if(ed_mode==4)PostMsg(popup,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
          else PostMsg(popup,MSG_KEY_DOWN,CH_ESC,0);
          return;
        }
        DocUnlock(doc);
      }
    }
    Yield;
  }
}
I64 EDCheck(I64 mode)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*doc=DocNew("Dialog.DD");
  CTask *popup=Fs->popup_task,*driver=NULL;
  I64 result=0,expected=3,ok;
  U8 *line,*want="cat one";
  ed_mode=mode;ed_forms=ed_menus=0;ed_saved=TRUE;ed_target=doc;
  doc->flags|=DOCF_PLAIN_TEXT;DocLoad(doc,"cat one\ncat two\ncat three",25);
  doc->flags&=~DOCF_PLAIN_TEXT;DocTop(doc);
  MemSet(doc->find_replace,0,sizeof(CEdFindText));
  StrCpy(doc->find_replace->find_text,"cat");StrCpy(doc->find_replace->replace_text,"DOG");
  doc->find_replace->replace=TRUE;doc->find_replace->scan_fwd=TRUE;
  doc->find_replace->match_case=TRUE;doc->find_replace->pmt=mode!=5;
  if(mode<2)DocGoToLine(doc,2);
  if(mode!=5)driver=Spawn(&EDDriver,Fs,"Editor dialog input",-1,Fs,16384);
  if(mode<2)EdGoToLine(doc);else result=EdFindReplace(doc);
  if(driver)while(TaskValidate(driver))Yield;
  if(mode<2) {
    expected=2;if(mode==1)expected=1;
    ok=doc->cur_entry!=doc && doc->cur_entry->y==expected && !doc->cur_col;
  } else {
    if(mode==2)expected=-1;if(mode==4)expected=0;
    if(mode==3 || mode==5)want="DOG one";
    line=DocScanLine(doc,doc->head.next);
    ok=result==expected && line && !StrCmp(line,want);Free(line);
  }
  if(mode==5)ok=ok&&!ed_forms&&!ed_menus;
  else ok=ok&&ed_forms==1;
  if(mode==3 || mode==4)ok=ok&&ed_menus==1;
  else ok=ok&&!ed_menus;
  ok=ok&&ed_saved&&DocPut==put&&DocDisplay==display&&DocBorder==border&&Fs->popup_task==popup;
  DocDel(doc);ed_target=NULL;return ok;
}
