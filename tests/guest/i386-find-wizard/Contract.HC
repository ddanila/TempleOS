I64 fw_case=0,fw_forms=0,fw_picker=0,fw_identity=0;
Bool fw_done=FALSE;
U8 *fw_root=NULL;
U0 FWLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 FWDriver(CTask *caller)
{
  CDoc *d;CDocEntry *e;CDirEntry *de;CTask *p;I64 fields,checks;U8 *s;
  while(!fw_done) {
    d=caller->display_doc;
    if(!fw_forms && d && d->desc=='Form' && d->win_task==caller &&
        Bt(&caller->task_flags,TASKf_AWAITING_MSG)) {
      DocLock(d);fw_forms++;fields=checks=0;
      for(e=d->head.next;e!=d;e=e->next) {
        if(e->type_u8==DOCT_DATA) {
          if(!fields) {
            if(e->aux_str && !StrCmp(e->aux_str,"FIND        :%s"))fw_identity|=1;
            DocDataFmt(d,e,"n\"eedle");
          } else if(fields==1)DocDataFmt(d,e,"unused");
          else if(fields==2)DocDataFmt(d,e,"*.TXT");
          fields++;
        }
        if(e->type_u8==DOCT_CHECK_BOX) {
          checks++;
          if(StrFind("RECURSE",e->tag) && e->de_flags&DOCEF_CHECKED_COLLAPSED)fw_identity|=2;
          if(StrFind("MATCH CASE",e->tag) || StrFind("WHOLE LABELS",e->tag))DocDataFmt(d,e,TRUE);
        }
      }
      if(fields==3 && checks==4)fw_identity|=4;
      DocUnlock(d);PostMsg(caller,MSG_KEY_DOWN,CH_ESC,0);
    }
    p=caller->popup_task;
    if(!fw_picker && p && TaskValidate(p) && p==sys_focus_task) {
      d=p->display_doc;
      if(d && d->desc=='FileMan' && d->win_task==p) {
        e=d->cur_entry;
        if(e!=d && (e->type_u8==DOCT_TREE || e->type_u8==DOCT_MENU_VAL)) {
          de=e->user_data;
          if(de && !StrCmp(de->full_name,fw_root)) {
            fw_picker=1;s=MStrPrint("FIND WIZARD PICKER %d\n",fw_case);FWLog(s);Free(s);
          }
        }
      }
    }
    Yield;
  }
}
U0 FWCheck(U8 *root)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*d=DocNew("WizardCaller.DD"),*arg=DocNew("ExplicitArg.DD");
  CTask *popup=Fs->popup_task,*driver,*t,*result=NULL,*focus=sys_focus_task;
  CEdFindText arg_saved,saved;U8 *old=DirCur,*cwd,*text,*s;I64 masks[2],size,deadline;
  fw_root=root;Cd(root);MemCpy(&arg_saved,arg->find_replace,sizeof(CEdFindText));
  for(fw_case=0;fw_case<2;fw_case++) {
    MemSet(d->find_replace,0,sizeof(CEdFindText));StrCpy(d->find_replace->find_text,"old");
    MemCpy(&saved,d->find_replace,sizeof(CEdFindText));StrCpy(saved.find_text,"n\"eedle");
    StrCpy(saved.replace_text,"unused");saved.match_case=saved.whole_labels=TRUE;
    Fs->put_doc=d;fw_forms=fw_picker=fw_identity=0;fw_done=FALSE;
    driver=Spawn(&FWDriver,Fs,"Wizard observer",-1,Fs,16384);
    //FindWiz uses DocPut, not this explicitly supplied document.
    DocPutKey(arg,CH_CTRLF,SCF_CTRL|SCF_SHIFT);fw_done=TRUE;
    while(TaskValidate(driver))Yield;
    masks[fw_case]=0;
    if(fw_forms==1 && fw_picker==1 && fw_identity==7)masks[fw_case]|=1;
    if(!MemCmp(d->find_replace,&saved,sizeof(CEdFindText)))masks[fw_case]|=2;
    if(!MemCmp(arg->find_replace,&arg_saved,sizeof(CEdFindText)))masks[fw_case]|=4;
    if(DocPut==d && DocDisplay==display && DocBorder==border && Fs->popup_task==popup)masks[fw_case]|=8;
    if(!Bt(&arg->locked_flags,DOClf_LOCKED))masks[fw_case]|=16;
    cwd=DirCur;if(!StrCmp(cwd,root))masks[fw_case]|=32;Free(cwd);
    s=MStrPrint("FIND WIZARD RETURN %d MASK %d\n",fw_case,masks[fw_case]);FWLog(s);Free(s);
    if(fw_case==1) {
      deadline=cnts.jiffies+30000;
      while(!result && cnts.jiffies<deadline) {
        t=Fs->next_task;
        while(t!=Fs) {
          if(t!=driver && t->put_doc && Bt(&t->task_flags,TASKf_CMD_LINE_PMT)) {
            text=DocSave(t->put_doc,&size);
            if(StrFind("PL:",text) && StrFind(root,text) && StrFind("n\"eedle",text))result=t;
            Free(text);
          }
          t=t->next_task;
        }
        Yield;
      }
      if(!result)throw('WizTask',TRUE);
      WinFocus(result);
      text=DocSave(result->put_doc,&size);
      s=MStrPrint("EXPORT wizard-results.DD %X %X\n",text,size);FWLog(s);Free(s);
      FWLog("FIND WIZARD RESULTS READY\n");Sleep(1000);Free(text);
      while(TaskValidate(result))Yield;
      FWLog("FIND WIZARD RESULTS CLOSED\n");
    }
    Fs->put_doc=put;
  }
  DocDel(arg);DocDel(d);Cd(old);Free(old);
  if(TaskValidate(focus))WinFocus(focus);
  s=MStrPrint("EXPORT wizard-masks.bin %X %X\n",masks,sizeof(masks));FWLog(s);Free(s);
  FWLog("FIND WIZARD DONE\n");Sleep(1000);
}
