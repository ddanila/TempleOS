CTask *cr_parent,*cr_leaf;
CCtrl *cr_foreign;
I64 *cr_cookie;
I64 cr_results[3],cr_mode,cr_count;
Bool cr_ready,cr_release,cr_recovered,cr_parent_clean,cr_parent_done;
CTask *CRHead(CTask *task)
{return (&task->next_child_task)(U8 *)-offset(CTask.next_sibling_task);}
I64 CRCount(CTask *task)
{CCtrl *c;I64 n=0;for(c=task->next_ctrl;c!=&task->next_ctrl;c=c->next)n++;return n;}
U0 CREnd()
{throw('CtrlRet');}
U0 CRLeaf(U8 *data)
{
  WinScrollsInit(Fs);
  cr_foreign->win_task=Fs;QueIns(cr_foreign,Fs->last_ctrl);
  cr_count=CRCount(Fs);cr_ready=TRUE;
  if(cr_mode==2)Fs->task_end_cb=&CREnd;
  try {while(!cr_release)Yield;}
  catch {
    if(Fs->except_ch=='CtrlRet') {
      Fs->catch_except=TRUE;
      cr_recovered=CRCount(Fs)==3 && cr_foreign->win_task==Fs && cr_foreign->next!=cr_foreign;
    }
  }
  while(!cr_release)Yield;
  if(cr_mode==1)Exit;
}
U0 CRParent(U8 *data)
{
  I64 deadline=cnts.jiffies+10000;
  WinScrollsInit(Fs);cr_leaf=Spawn(&CRLeaf,NULL,"Control leaf",-1,Fs,16384);
  while(!cr_ready && cnts.jiffies<deadline)Yield;
  if(!cr_ready)return;
  if(cr_mode==2) {
    Kill(cr_leaf,TRUE,FALSE);
    while(!cr_recovered && cnts.jiffies<deadline)Yield;
  }
  cr_release=TRUE;
  if(cr_mode==2)Kill(cr_leaf,TRUE,FALSE);
  while(Fs->next_child_task!=CRHead(Fs) && cnts.jiffies<deadline)Yield;
  cr_parent_clean=Fs->next_child_task==CRHead(Fs) && Fs->last_child_task==CRHead(Fs) && !TaskValidate(cr_leaf);
  cr_parent_done=TRUE;
}
I64 CRRun(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,deadline,mask=0;
  CTask *first=Fs->next_child_task,*last=Fs->last_child_task;
  cr_mode=mode;cr_count=0;cr_ready=cr_release=cr_recovered=cr_parent_clean=cr_parent_done=FALSE;
  cr_foreign=CAlloc(sizeof(CCtrl));cr_cookie=CAlloc(16);
  cr_cookie[0]=0x123456789ABCDEF;cr_cookie[1]=0x3456789ABCDEF01;
  cr_foreign->state=cr_cookie;cr_foreign->left=37;cr_foreign->flags=CTRLF_SHOW;
  deadline=cnts.jiffies+15000;cr_parent=Spawn(&CRParent,NULL,"Control parent",-1,Fs,16384);
  while((!cr_parent_done || TaskValidate(cr_parent) || Fs->next_child_task!=first || Fs->last_child_task!=last) && cnts.jiffies<deadline)Yield;
  if(cr_ready && cr_count==3)mask|=1;
  if(!TaskValidate(cr_leaf))mask|=2;
  if(cr_parent_clean)mask|=4;
  if(cr_foreign->next==cr_foreign && cr_foreign->last==cr_foreign && !cr_foreign->win_task)mask|=8;
  if(cr_foreign->state==cr_cookie && cr_foreign->left==37 && cr_foreign->flags==CTRLF_SHOW &&
      cr_cookie[0]==0x123456789ABCDEF && cr_cookie[1]==0x3456789ABCDEF01)mask|=16;
  if(mode!=2 && !cr_recovered || mode==2 && cr_recovered)mask|=32;
  if(cr_parent_done && !TaskValidate(cr_parent) && Fs->next_child_task==first && Fs->last_child_task==last)mask|=64;
  //A failed retirement still owns the association; do not free borrowed storage under it.
  if(mask==127) {
    Free(cr_foreign);Free(cr_cookie);
    if(Fs->data_heap->used_u8s==before)mask|=128;
  }
  return mask;
}
Bool CRContract()
{
  I64 i;U8 *line,*p;
  MemSet(cr_results,0,sizeof(cr_results));
  for(i=0;i<3;i++) {cr_results[i]=CRRun(i);if(cr_results[i]!=255)break;}
  line=MStrPrint("EXPORT modes.bin %X 18\n",cr_results);
  p=line;while(*p)OutU8(0xE9,*p++);Free(line);
  return cr_results[0]==255 && cr_results[1]==255 && cr_results[2]==255;
}
