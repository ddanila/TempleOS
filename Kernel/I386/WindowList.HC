//Frame membership is numeric. Never keep a ring pointer across a callback yield.
class CNativeWindowListScope:CNativeRenderScope {
  I64 **numbers;
};
U0 NativeWindowListRelease(CNativeRenderScope *base)
{
  CNativeWindowListScope *scope=base;
  I64 *numbers=*scope->numbers;
  *scope->numbers=NULL;Free(numbers);
}
CTask *NativeWindowFind(I64 number)
{//Single-CPU cooperative scan; no callback or yield until target admission.
  CTask *anchor=sys_winmgr_task,*task=anchor;
  do {
    if(!TaskValidate(task))return NULL;
    if(task->task_num==number)return task;
    task=task->next_task;
  } while(task!=anchor);
  return NULL;
}
U0 NativeWindowListDraw(CDC *dc)
{
  CNativeWindowListScope scope;
  CTask *task,*anchor=sys_winmgr_task;
  I64 *numbers=NULL,count=0,i=0;
  scope.numbers=&numbers;
  try {
    NativeRenderScopeOpen(&scope,&NativeWindowListRelease);
    task=anchor;
    do {
      if(!TaskValidate(task))throw('WinList',TRUE);
      count++;task=task->next_task;
    } while(task!=anchor);
    numbers=MAlloc(count*sizeof(I64));
    task=anchor;
    do {
      numbers[i++]=task->task_num;task=task->next_task;
    } while(task!=anchor);
    for(i=0;i<count;i++) {
      //Only identities survive a yielding update. New members join next frame.
      task=NativeWindowFind(numbers[i]);
      if(task && !NativeRenderOwnerClosing(task) &&
          Bt(&task->display_flags,DISPLAYf_SHOW) &&
          Bt(gr.win_uncovered_bitmap,task->win_z_num))
        GrUpdateTaskWin(task);
    }
    NativeWindowListRelease(&scope);
  } catch {
    NativeWindowListRelease(&scope);
    NativeRenderScopeClose(&scope);
  }
  NativeRenderScopeClose(&scope);
}
Bool NativeWindowPresent(Bool blink=FALSE)
{//Explicit full-ring component; normal-boot scheduling is integrated separately.
  return NativeGraphicsPresent(&NativeWindowListDraw,blink);
}
