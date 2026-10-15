I64 cl_caller_delta,cl_clip_delta,cl_control_caller,cl_control_clip;
Bool CLLine(CDoc *d,U8 *wanted)
{U8 *s=DocScanLine(d,d->head.next);Bool r;if(s)r=!StrCmp(s,wanted);else r=!*wanted;Free(s);return r;}
I64 CLContract(I64 mode)
{
  I64 before,clip_before,m=0;
  CDoc *d,*t,*copy=NULL;
  CDocEntry *first;
  U8 *source="AB",*target="xABy",*clip="AB";
  Bool locked=mode==5,selected=FALSE;
  ClipDel;before=Fs->data_heap->used_u8s;clip_before=sys_clip_doc->mem_task->data_heap->used_u8s;
  d=DocNew("ClipSource.DD");t=DocNew("ClipTarget.DD");
  DocPrint(d,"AB");DocPrint(t,"xy");DocTop(d);DocTop(t);first=d->head.next;
  first->type|=DOCET_SEL;
  if(locked){DocLock(d);DocLock(t);DocLock(sys_clip_doc);}
  switch(mode) {
    case 0:ClipCopy(d);EdCursorRight(t);ClipPaste(t);break;
    case 1:ClipCut(d);ClipPaste(t);source="";target="ABxy";break;
    case 2:copy=DocCopy(d,first,first);DocBottom(t);DocInsDoc(t,copy);target="xyAB";clip="";selected=TRUE;break;
    case 3:DocCut(d,first,first);source="";target="xy";clip="";break;
    case 4:first->type&=~DOCET_SEL;ClipCopy(d);EdCursorRight(t);ClipPaste(t);target="xy";clip="";break;
    case 5:ClipCopy(d);ClipPaste(t);target="ABxy";break;
  }
  if(CLLine(d,source))m|=1;
  if(CLLine(t,target))m|=2;
  if(mode==1||mode==3||Bt(&first->type,DOCEt_SEL)==selected)m|=4;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==locked&&Bt(&t->locked_flags,DOClf_LOCKED)==locked&&
      Bt(&sys_clip_doc->locked_flags,DOClf_LOCKED)==locked)m|=8;
  if(CLLine(sys_clip_doc,clip))m|=16;
  DocUnlock(d);DocUnlock(t);DocUnlock(sys_clip_doc);
  DocDel(copy);DocDel(d);DocDel(t);ClipDel;
  cl_caller_delta=Fs->data_heap->used_u8s-before;cl_clip_delta=sys_clip_doc->mem_task->data_heap->used_u8s-clip_before;
  if(Fs->data_heap->used_u8s==before&&sys_clip_doc->mem_task->data_heap->used_u8s==clip_before)m|=32;
  return m;
}
Bool cl_worker_done;
U0 CLWorker(U8 *data)
{
  CDoc *d=DocNew("WorkerClip.DD");
  DocPrint(d,"Stay");DocTop(d);d->head.next(CDocEntry *)->type|=DOCET_SEL;
  if(data)ClipCopy(d);DocDel(d);cl_worker_done=TRUE;
}
Bool CLLinked(CTask *target)
{
  CTask *self=Fs,*node=self->next_child_task;
  CTask *head=(&self->next_child_task)(U8 *)-offset(CTask.next_sibling_task);
  while(node!=head){if(node==target)return TRUE;node=node->next_sibling_task;}
  return FALSE;
}
CTask *CLSpawnWait(Bool copy=TRUE)
{
  CTask *worker;
  I64 i;
  cl_worker_done=FALSE;worker=Spawn(&CLWorker,copy,"Clipboard worker",-1,Fs);
  LBtr(&worker->display_flags,DISPLAYf_SHOW);
  for(i=0;i<200&&(TaskValidate(worker)||CLLinked(worker));i++)Sleep(5);
  return worker;
}
I64 CLWorkerContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *worker,*old_child=Fs->next_child_task;
  CDocEntry *e;
  I64 before,clip_before,i,m=0;
  //Warm startup/task caches before measuring a separate worker lifecycle.
  CLSpawnWait;ClipDel;Sleep(20);
  before=Fs->data_heap->used_u8s;clip_before=sys_clip_doc->mem_task->data_heap->used_u8s;
  CLSpawnWait(FALSE);ClipDel;Sleep(20);
  cl_control_caller=Fs->data_heap->used_u8s-before;
  cl_control_clip=sys_clip_doc->mem_task->data_heap->used_u8s-clip_before;
  before=Fs->data_heap->used_u8s;clip_before=sys_clip_doc->mem_task->data_heap->used_u8s;
  if(sys_clip_doc->mem_task==adam_task&&MHeapCtrl(sys_clip_doc)->mem_task==adam_task)m|=1;
  worker=CLSpawnWait;
  e=sys_clip_doc->head.next;
  if(e!=sys_clip_doc&&MHeapCtrl(e)->mem_task==adam_task&&MHeapCtrl(e->tag)->mem_task==adam_task)m|=2;
  if(cl_worker_done&&!TaskValidate(worker)&&!CLLinked(worker)&&Fs->next_child_task==old_child)m|=4;
  if(CLLine(sys_clip_doc,"Stay"))m|=8;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
  ClipDel;
  //Allow asynchronous storage reaping to finish before heap observations.
  for(i=0;i<200&&(Fs->data_heap->used_u8s!=before+cl_control_caller||sys_clip_doc->mem_task->data_heap->used_u8s!=clip_before+cl_control_clip);i++)Sleep(5);
  cl_caller_delta=Fs->data_heap->used_u8s-before;cl_clip_delta=sys_clip_doc->mem_task->data_heap->used_u8s-clip_before;
  if(cl_caller_delta==cl_control_caller&&cl_clip_delta==cl_control_clip)m|=32;
  return m;
}
