//Observe actual dictionary slots and input. Never call a completion action.
I64 acn_index,acn_executions=0;
U8 *ACNInputLine()
{
  U8 *line=ACUIInputLine,*start,*res=NULL;
  //The terminal's drive prompt is part of DocScanLine on the original.
  if(line && (start=StrMatch("ACNCheck(\"",line)))res=StrNew(start);
  Free(line);return res;
}
U8 *ACNLine(U8 *prefix,U8 *word)
{
  return MStrPrint("%s%s",prefix,word);
}
U0 ACNPrefixReport()
{
  U8 *line,*body;
  I64 i,size;
  acui_report=MAlloc(65536);acui_report_size=0;
  line=MStrPrint("INDEX %d WORD %s LENGTH %d DICTIONARY %d COUNT %d\nRECT %d %d %d %d\n",
    acn_index,ac.cur_word,ac.partial_len,acd.num_words,acd.num_fillins,
    ac.task->win_left,ac.task->win_right,ac.task->win_top,ac.task->win_bottom);
  ACUILine(line);Free(line);
  for(i=0;i<acd.num_fillins;i++) {
    line=MStrPrint("SLOT %d %s",i,acd.fillins[i]+1);
    ACUILine(line);Free(line);
  }
  body=DocSave(DocDisplay(ac.task),&size);
  line=MStrPrint("DOCUMENT %d\n",size);ACUIAppend(line,StrLen(line));Free(line);
  ACUIAppend(body,size);Free(body);
  line=MStrPrint("ACNPrefix%d.DATA",acn_index);ACUIExport(line);Free(line);
}
U0 ACNWatch(I64 unused)
{
  U8 *line,*before,*after,*expected,*name;
  I64 frame,before_size,after_size,left,right,top,bottom,wanted=acn_index+1;
  Bool ready,stable;
  while(TRUE) {
    line=ACNInputLine;
    ready=line && !StrCmp(line,"ACNCheck(\"Appl") && ac.cur_word &&
      !StrCmp(ac.cur_word,"Appl");
    Free(line);
    if(ready)break;
    Sleep(10);
  }
  //The prefix pointer precedes printing. Require a stable document and rect
  //across a completed WinMgr frame after the application's refresh sleep.
  while(TRUE) {
    while(!Bt(&ac.task->task_flags,TASKf_IDLE) || ac.task->wake_jiffy<=cnts.jiffies)Sleep(10);
    before=DocSave(DocDisplay(ac.task),&before_size);
    left=ac.task->win_left;right=ac.task->win_right;
    top=ac.task->win_top;bottom=ac.task->win_bottom;
    frame=winmgr.updates;
    while(winmgr.updates==frame)Sleep(1);
    after=DocSave(DocDisplay(ac.task),&after_size);
    stable=before_size==after_size && !MemCmp(before,after,before_size) &&
      StrMatch("Word:Appl",before) && StrMatch("Word:Appl",after) &&
      ac.task->win_left==left && ac.task->win_right==right &&
      ac.task->win_top==top && ac.task->win_bottom==bottom &&
      ac.cur_word && !StrCmp(ac.cur_word,"Appl");
    Free(before);Free(after);
    if(stable)break;
  }
  if(acd.num_fillins!=10)throw('NumSlots',TRUE);
  expected=ACNLine("ACNCheck(\"",acd.fillins[acn_index]+1);
  ACNPrefixReport;
  ACUILog("ACN prefix ready\n");
  while(TRUE) {
    line=ACNInputLine;
    ready=line && !StrCmp(line,expected);
    Free(line);
    if(ready)break;
    Sleep(10);
  }
  acui_report=MAlloc(65536);acui_report_size=0;
  ACUILine(expected);Free(expected);
  name=MStrPrint("ACNSelected%d.DATA",acn_index);ACUIExport(name);Free(name);
  ACUILog("ACN selected\n");
  //Keep observer-owned exports alive until the host submits the captured input.
  while(acn_executions<wanted)Sleep(10);
}
public U0 ACNArm(CTask *focus,I64 index)
{
  if(!(0<=index<10) || !TaskValidate(focus))throw('NumArm',TRUE);
  acn_index=index;acui_focus=focus;
  if(!Spawn(&ACNWatch,NULL,"Numeric autocomplete observer"))throw('NumWatch',TRUE);
  ACUILog("ACN armed\n");
}
public I64 ACNCheck(U8 *word)
{
  U8 *line,*name;
  acn_executions++;
  acui_report=MAlloc(65536);acui_report_size=0;
  line=MStrPrint("EXECUTION %d INDEX %d WORD %s",acn_executions,acn_index,word);
  ACUILine(line);Free(line);
  name=MStrPrint("ACNExecuted%d.DATA",acn_index);ACUIExport(name);Free(name);
  ACUILog("ACN executed\n");
  return 42;
}
ACUILog("ACN fixture loaded\n");
