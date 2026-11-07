//Public dispatch with real forms/menu; the driver formats fields, then posts
//Esc/ShiftEsc. This does not claim physical shortcut or field-edit coverage.
I64 sk_mode=0,sk_forms=0,sk_menus=0;
Bool sk_done=FALSE,sk_identity=TRUE;
CDoc *sk_target=NULL;
U0 SKLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 SKDriver(CTask *caller)
{
  CDoc *d;CDocEntry *e,*first;CTask *p;I64 fields,checks;U8 *label;
  while(!sk_done) {
    d=caller->display_doc;
    if(!sk_forms && d && d!=sk_target && d->desc=='Form' &&
        d->win_task==caller && Bt(&caller->task_flags,TASKf_AWAITING_MSG)) {
      DocLock(d);sk_forms++;
      fields=checks=0;first=NULL;label="Find        :%s";
      if(sk_mode==4)label="FIND        :%s";
      for(e=d->head.next;e!=d;e=e->next) {
        if(e->type_u8==DOCT_DATA){fields++;if(!first)first=e;}
        if(e->type_u8==DOCT_CHECK_BOX)checks++;
      }
      if(fields!=3 || !first || !first->aux_str || StrCmp(first->aux_str,label))sk_identity=FALSE;
      if(sk_mode==4){if(checks!=4)sk_identity=FALSE;}
      else if(checks!=6)sk_identity=FALSE;
      //Change the first string through the form entry, not the target record.
      if(sk_mode==0 || sk_mode==1 || sk_mode==7 || sk_mode==8)
        for(e=d->head.next;e!=d;e=e->next)
          if(e->type_u8==DOCT_DATA) {DocDataFmt(d,e,"dog");break;}
      DocUnlock(d);
      if(sk_mode==1 || sk_mode==4)PostMsg(caller,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
      else PostMsg(caller,MSG_KEY_DOWN,CH_ESC,0);
    }
    p=caller->popup_task;
    if(sk_forms && !sk_menus && p && TaskValidate(p) &&
        Bt(&p->task_flags,TASKf_AWAITING_MSG)) {
      d=p->display_doc;
      if(d && d->desc=='Menu' && d->win_task==p) {
        DocLock(d);
        for(e=d->head.next;e!=d;e=e->next)
          if(e->type_u8==DOCT_BTTN && e->de_flags&DOCEF_LEFT_EXP && e->left_exp==2) {
            sk_menus++;d->cur_entry=e;d->cur_col=0;break;
          }
        DocUnlock(d);
        if(sk_menus) {
          if(sk_mode==3)PostMsg(p,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
          else PostMsg(p,MSG_KEY_DOWN,CH_ESC,0);
        }
      }
    }
    Yield;
  }
}
I64 SKAction(I64 mode)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*d=DocNew("SearchKeys.DD");
  CTask *popup=Fs->popup_task,*driver;CEdFindText saved;
  I64 m=0,sc=SCF_CTRL,forms=1,menus=0,col=0;U8 *want="cat dog cat dog",*line,*s;
  d->flags|=DOCF_PLAIN_TEXT;DocLoad(d,want,StrLen(want));d->flags&=~DOCF_PLAIN_TEXT;
  d->flags|=DOCF_DONT_SWAP_OUT;DocTop(d);
  MemSet(d->find_replace,0,sizeof(CEdFindText));
  StrCpy(d->find_replace->find_text,"cat");StrCpy(d->find_replace->replace_text,"DOG");
  d->find_replace->pmt=TRUE;d->find_replace->scan_fwd=TRUE;d->find_replace->match_case=TRUE;
  if(mode==2 || mode==3){d->find_replace->replace=TRUE;menus=1;}
  if(mode==2)want="DOG dog DOG dog";
  if(mode==4 || mode==6)sc|=SCF_SHIFT;
  if(mode==5 || mode==6){sc|=SCF_ALT;forms=0;}
  if(mode==7)DocLock(d);
  if(mode==8)sc=0;
  MemCpy(&saved,d->find_replace,sizeof(CEdFindText));
  if(mode==0 || mode==7 || mode==8){StrCpy(saved.find_text,"dog");col=4;}
  sk_mode=mode;sk_forms=sk_menus=0;sk_done=FALSE;sk_identity=TRUE;sk_target=d;
  driver=Spawn(&SKDriver,Fs,"Search form input",-1,Fs,16384);
  StrCpy(keydev.desc,"unset");DocPutKey(d,CH_CTRLF,sc);
  sk_done=TRUE;while(TaskValidate(driver))Yield;
  if(sk_forms==forms && sk_menus==menus && sk_identity)m|=1;
  if(!MemCmp(&saved,d->find_replace,sizeof(CEdFindText)))m|=2;
  line=DocScanLine(d,d->head.next);if(line && !StrCmp(line,want))m|=4;Free(line);
  //Replacement scanning has its own cursor policy, captured separately below.
  if(mode==2 || mode==3 || d->cur_entry==d->head.next && d->cur_col==col)m|=8;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode==7))m|=16;
  if(DocPut==put && DocDisplay==display && DocBorder==border && Fs->popup_task==popup)m|=32;
  if(!StrCmp(keydev.desc,"unset"))m|=64;
  s=MStrPrint("SEARCH KEY CASE %d MASK %d FORMS %d MENUS %d COL %d\n",mode,m,sk_forms,sk_menus,d->cur_col);SKLog(s);Free(s);
  DocUnlock(d);DocDel(d);sk_target=NULL;return m;
}
U0 SKCheck()
{
  I64 i,sc,masks[9],metadata[4];CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *e;CEdFindText saved;U8 *want,*s;
  for(i=0;i<9;i++)masks[i]=SKAction(i);
  for(i=0;i<4;i++) {
    d=DocNew("SearchMetadata.DD");e=d->cur_entry;
    MemCpy(&saved,d->find_replace,sizeof(CEdFindText));
    sc=SCF_CTRL|SCF_KEY_DESC;want="Edit/Find & Replace";
    if(i&1){sc|=SCF_SHIFT;want="Cmd /Search Files";}
    if(i>=2){sc|=SCF_ALT;want="unset";}
    StrCpy(keydev.desc,"unset");DocPutKey(d,CH_CTRLF,sc);metadata[i]=0;
    if(!StrCmp(keydev.desc,want))metadata[i]|=1;
    if(!MemCmp(&saved,d->find_replace,sizeof(CEdFindText)))metadata[i]|=2;
    if(d->cur_entry==e && !d->cur_col && !Bt(&d->locked_flags,DOClf_LOCKED))metadata[i]|=4;
    if(DocPut==put && DocDisplay==display && DocBorder==border)metadata[i]|=8;
    DocDel(d);
  }
  s=MStrPrint("EXPORT search-key-actions.bin %X %X\n",masks,sizeof(masks));SKLog(s);Free(s);
  s=MStrPrint("EXPORT search-key-metadata.bin %X %X\n",metadata,sizeof(metadata));SKLog(s);Free(s);
  SKLog("DOC SEARCH KEYS DONE\n");Sleep(1000);
}
