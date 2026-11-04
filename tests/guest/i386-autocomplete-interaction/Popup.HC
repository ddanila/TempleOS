CTask *acpu_parent,*acpu_task=NULL;
class CACPUFrame {I64 sequence,same,popup_z,ac_z;};
CACPUFrame *acpu_frame;
U16 *acpu_z_now,*acpu_z_old;
U8 *acpu_frame_body;
I64 acpu_frame_counter=0;
U0 (*acpu_old_final)(CDC *dc);
U0 ACPUFrame(CDC *dc)
{
  if(acpu_old_final)(*acpu_old_final)(dc);
  if(TaskValidate(acpu_task) && dc->width_internal==640 && dc->height==480) {
    acpu_frame->sequence=0;
    MemCpy(acpu_z_old,acpu_z_now,9600);
    MemCpy(acpu_z_now,gr.win_z_buf,9600);
    MemCpy(acpu_frame_body,dc->body,640*480);
    acpu_frame->same=!MemCmp(acpu_z_old,acpu_z_now,9600);
    acpu_frame->popup_z=acpu_task->win_z_num;
    acpu_frame->ac_z=ac.task->win_z_num;
    acpu_frame->sequence=++acpu_frame_counter;
  }
}
CDoc *acpu_put,*acpu_display,*acpu_border;
CDocEntry *acpu_entry;
I64 acpu_col,acpu_sy;
U0 ACPUExport(U8 *name,U8 *data,I64 size)
{
  U8 *line;
  if(acui_native) {
    line=MStrPrint("C:/%s",name);
    if(!FileWrite(line,data,size))throw('PuWrite',TRUE);
    Free(line);
  }
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);ACUILog(line);Free(line);
}
U0 ACPUSnapshot(I64 stage)
{
  CDoc *doc=DocDisplay(acpu_task);
  U8 *before,*after,*head,*report,*name;
  I64 n,m,frame,left,right,top,bottom,sx,sy,y,col,mask;
  Bool stable;
  while(TRUE) {
    while(!Bt(&acpu_task->task_flags,TASKf_AWAITING_MSG))Sleep(1);
    before=DocSave(doc,&n);
    left=acpu_task->win_left;right=acpu_task->win_right;
    top=acpu_task->win_top;bottom=acpu_task->win_bottom;
    sx=acpu_task->scroll_x;sy=acpu_task->scroll_y;
    y=doc->cur_entry->y;col=doc->cur_col;
    frame=winmgr.updates;while(winmgr.updates==frame)Sleep(1);
    after=DocSave(doc,&m);
    stable=n==m && !MemCmp(before,after,n) && StrMatch("Apple:",after) &&
      left==acpu_task->win_left && right==acpu_task->win_right &&
      top==acpu_task->win_top && bottom==acpu_task->win_bottom &&
      sx==acpu_task->scroll_x && sy==acpu_task->scroll_y &&
      y==doc->cur_entry->y && col==doc->cur_col;
    Free(before);
    if(stable)break;
    Free(after);
  }
  acpu_entry=doc->cur_entry;acpu_col=doc->cur_col;acpu_sy=sy;
  mask=0;
  if(acpu_parent->popup_task==acpu_task)mask|=1;
  if(acpu_task->parent_task==acpu_parent)mask|=2;
  if(sys_focus_task==acpu_task)mask|=4;
  if(DocPut(acpu_task)==doc)mask|=8;
  if(doc->win_task==acpu_task)mask|=16;
  head=MStrPrint("STAGE %d MASK %d\nRECT %d %d %d %d\nSTATE %d %d %d %d\nZBUFFER %X %d %d\nRASTER %d %d %d %d\nFRAME %X %X\nDOCUMENT %d\n",
    stage,mask,left,right,top,bottom,sx,sy,y,col,acpu_z_now,acpu_task->win_z_num,ac.task->win_z_num,
    doc->x-doc->line_start_col+left+sx/8,doc->y-doc->top_line_num+top+sy/8,ms.pos.x,ms.pos.y,acpu_frame,acpu_frame_body,m);
  report=MAlloc(StrLen(head)+m);MemCpy(report,head,StrLen(head));
  MemCpy(report+StrLen(head),after,m);
  name=MStrPrint("ACPUPopup%d.DATA",stage);
  ACPUExport(name,report,StrLen(head)+m);Free(name);Free(head);Free(after);
  //The observer heap owns each report until the popup has been closed.
  name=MStrPrint("ACPU stage %d\n",stage);ACUILog(name);Free(name);
}
U0 ACPUWatch(I64 unused)
{
  CDoc *doc;
  CDocEntry *entry;
  I64 stage,col,sy,old_num,mask;
  U8 *line,*report;
  while(!(acpu_task=acpu_parent->popup_task) || !TaskValidate(acpu_task))Sleep(1);
  old_num=acpu_task->task_num;
  while(!(doc=DocDisplay(acpu_task)))Sleep(1);
  ACPUSnapshot(0);
  for(stage=1;stage<=2;stage++) {
    entry=acpu_entry;col=acpu_col;sy=acpu_sy;
    while(doc->cur_entry==entry && doc->cur_col==col && acpu_task->scroll_y==sy)Sleep(1);
    ACPUSnapshot(stage);
  }
  while(TaskValidate(acpu_task) && acpu_task->task_num==old_num ||
      acpu_parent->popup_task || sys_focus_task!=acpu_parent)Sleep(1);
  gr.fp_final_scrn_update=acpu_old_final;
  mask=0;
  if(DocPut(acpu_parent)==acpu_put)mask|=1;
  if(DocDisplay(acpu_parent)==acpu_display)mask|=2;
  if(DocBorder(acpu_parent)==acpu_border)mask|=4;
  if(!acpu_parent->popup_task)mask|=8;
  if(sys_focus_task==acpu_parent)mask|=16;
  line=ACNInputLine;
  report=MStrPrint("RESTORED %d\nINPUT %s\n",mask,line);Free(line);
  ACPUExport("ACPUClosed.DATA",report,StrLen(report));
  ACUILog("ACPU closed\n");
  //The popup had focus, so ACTask may still hold its word/choices. Observe
  //normal parent choices again before the host requests another completion.
  while(TRUE) {
    while(!ac.cur_word || StrCmp(ac.cur_word,"Appl") || ac.partial_len!=4 ||
        acd.num_fillins!=10 || StrCmp(acd.fillins[0]+1,"Applaud"))Sleep(10);
    line=DocSave(DocDisplay(ac.task),&col);
    mask=StrMatch("Word:Appl",line)!=NULL;
    Free(line);
    if(mask)break;
    Sleep(10);
  }
  report=MStrPrint("RESUMED %s %d %d %s\n",ac.cur_word,ac.partial_len,acd.num_fillins,acd.fillins[0]+1);
  ACPUExport("ACPUResumed.DATA",report,StrLen(report));
  ACUILog("ACPU resumed\n");
  while(acn_executions<1)Sleep(10);
}
public U0 ACPUArm(CTask *parent)
{
  acpu_parent=parent;acpu_put=DocPut(parent);acpu_display=DocDisplay(parent);acpu_border=DocBorder(parent);
  acpu_frame=CAlloc(sizeof(CACPUFrame));acpu_z_now=CAlloc(9600);acpu_z_old=CAlloc(9600);
  acpu_frame_body=MAlloc(640*480);
  acpu_old_final=gr.fp_final_scrn_update;gr.fp_final_scrn_update=&ACPUFrame;
  ACNArm(parent,0);
  if(!Spawn(&ACPUWatch,NULL,"Dictionary popup observer"))throw('PuWatch',TRUE);
  ACUILog("ACPU armed\n");
}
ACUILog("ACPU fixture loaded\n");
