U0 ACUILog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool acui_native;
CTask *acui_focus;
U8 *acui_report;
I64 acui_report_size;
U0 ACUIAppend(U8 *s,I64 size)
{
  if(size<0 || acui_report_size+size>65536)throw('UIReport',TRUE);
  MemCpy(acui_report+acui_report_size,s,size);acui_report_size+=size;
}
U0 ACUILine(U8 *s){ACUIAppend(s,StrLen(s));ACUIAppend("\n",1);}
U0 ACUIExport(U8 *name)
{
  U8 *line;
  if(acui_native) {
    line=MStrPrint("C:/%s",name);
    if(!FileWrite(line,acui_report,acui_report_size))throw('UIWrite',TRUE);
    Free(line);
  }
  line=MStrPrint("EXPORT %s %X %X\n",name,acui_report,acui_report_size);
  ACUILog(line);Free(line);
}
public U0 ACUIStart(Bool native=FALSE)
{
  acui_native=native;
  if(native)ACInit("C:/ACUIProject.HC");else ACInit("T:/ACUIProject.HC");
  if(!TaskValidate(ac.task) || acd.num_words!=95293)throw('UIInit',TRUE);
  ACUILog("ACUI initialized\n");
}
U0 ACUIPrefixReport()
{
  U8 *line,*body;
  I64 i,size;
  CDoc *doc=DocDisplay(ac.task);
  if(!doc)throw('UIDoc',TRUE);
  acui_report=MAlloc(65536);acui_report_size=0;
  line=MStrPrint("SOURCE %d DICTIONARY %d\nWORD %s LENGTH %d COUNT %d\nRECT %d %d %d %d\n",
    ac.num_words,acd.num_words,ac.cur_word,ac.partial_len,ac.num_fillins,
    ac.task->win_left,ac.task->win_right,ac.task->win_top,ac.task->win_bottom);
  ACUIAppend(line,StrLen(line));Free(line);
  for(i=0;i<ac.num_fillins;i++) {
    line=MStrPrint("MATCH %s HITS %d\n",ac.fillin_matches[i]->str,ac.fillin_hits[i]);
    ACUIAppend(line,StrLen(line));Free(line);
  }
  body=DocSave(doc,&size);
  line=MStrPrint("DOCUMENT %d\n",size);ACUIAppend(line,StrLen(line));Free(line);
  ACUIAppend(body,size);Free(body);
  ACUIExport("ACUIPrefix.DATA");
}
U8 *ACUIInputLine()
{
  CDoc *doc=DocPut(acui_focus);
  CDocEntry *entry;
  U8 *line;
  Bool unlock;
  if(!doc)return NULL;
  unlock=DocLock(doc);
  entry=doc->cur_entry;
  if(entry==doc)entry=entry->last;
  while(entry->last!=doc && (entry->type_u8==DOCT_NEW_LINE || entry->type_u8==DOCT_SOFT_NEW_LINE))entry=entry->last;
  while(entry->last!=doc && entry->last->type_u8!=DOCT_NEW_LINE)entry=entry->last;
  line=DocScanLine(doc,entry);
  if(unlock)DocUnlock(doc);
  return line;
}
U0 ACUIFenceStatus(U8 *stage)
{
  U8 *line=MStrPrint("ACUI fence %s idle %d wake %d now %d frames %d\n",stage,
    Bt(&ac.task->task_flags,TASKf_IDLE),ac.task->wake_jiffy,cnts.jiffies,winmgr.updates);
  ACUILog(line);Free(line);
}
U0 ACUIWatch(I64 unused)
{
  U8 *line,*word,*status,*before,*after;
  I64 ticks=0,frame,before_size,after_size,left,right,top,bottom;
  Bool stable;
  while(!ac.cur_word || StrCmp(ac.cur_word,"ACUI")) {
    if(!(ticks++%300)) {
      word=ac.cur_word;if(!word)word="<null>";
      status=MStrPrint("ACUI waiting word %s count %d focus %d\n",word,ac.num_fillins,sys_focus_task==acui_focus);
      ACUILog(status);Free(status);
    }
    Sleep(10);
  }
  //Observe the application's post-refresh sleep and a completed WinMgr frame.
  //The word pointer is assigned before scanning/printing, so it is not a fence.
  while(TRUE) {
    while(!Bt(&ac.task->task_flags,TASKf_IDLE) || ac.task->wake_jiffy<=cnts.jiffies) {
      if(!(ticks++%100))ACUIFenceStatus("sleep");
      Sleep(10);
    }
    before=DocSave(DocDisplay(ac.task),&before_size);
    left=ac.task->win_left;right=ac.task->win_right;
    top=ac.task->win_top;bottom=ac.task->win_bottom;
    frame=winmgr.updates;
    while(winmgr.updates==frame) {
      if(!(ticks++%100))ACUIFenceStatus("frame");
      Sleep(1);
    }
    after=DocSave(DocDisplay(ac.task),&after_size);
    stable=before_size==after_size && !MemCmp(before,after,before_size) &&
      ac.task->win_left==left && ac.task->win_right==right &&
      ac.task->win_top==top && ac.task->win_bottom==bottom &&
      ac.cur_word && !StrCmp(ac.cur_word,"ACUI");
    Free(before);Free(after);
    if(stable)break;
  }
  ACUIPrefixReport;
  ACUILog("ACUI prefix ready\n");
  while(TRUE) {
    line=ACUIInputLine;
    if(line) {
      word=StrMatch("ACUIAlpha",line);
      if(word && !StrCmp(word,"ACUIAlpha"))break;
      Free(line);
    }
    Sleep(10);
  }
  acui_report=MAlloc(65536);acui_report_size=0;ACUILine("SELECTED ACUIAlpha");Free(line);
  ACUIExport("ACUISelected.DATA");ACUILog("ACUI selected\n");
  while(acui_executions!=1)Sleep(10);
  ACUILog("ACUI executed\n");
}
public U0 ACUIArm(CTask *focus)
{
  acui_focus=focus;
  if(!TaskValidate(focus) || !Spawn(&ACUIWatch,NULL,"Autocomplete UI observer"))throw('UIWatch',TRUE);
  ACUILog("ACUI armed\n");
}
ACUILog("ACUI fixture loaded\n");
