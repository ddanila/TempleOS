I64 ts_lifecycle[12];
U0 TSLifecycle()
{
  I64 i,n,base,code_base,used,mask=0;
  CTask *task;
  CCtrl *c,*h,*v;
  U8 *s;
  for(i=0;i<3;i++) {
    base=Fs->data_heap->used_u8s;code_base=Fs->code_heap->used_u8s;
    task=User;
    h=CtrlFindUnique(task,CTRLT_WIN_HSCROLL);v=CtrlFindUnique(task,CTRLT_WIN_VSCROLL);
    n=0;for(c=task->next_ctrl;c!=&task->next_ctrl;c=c->next)n++;
    if(h && v && n==2 && h->win_task==task && v->win_task==task && h->state==&task->horz_scroll && v->state==&task->vert_scroll)mask|=1<<(i*4);
    used=Fs->data_heap->used_u8s;WinScrollsInit(task);
    if(CtrlFindUnique(task,CTRLT_WIN_HSCROLL)==h && CtrlFindUnique(task,CTRLT_WIN_VSCROLL)==v && Fs->data_heap->used_u8s==used)mask|=2<<(i*4);
    if(Kill(task))mask|=4<<(i*4);
    WinFocus(Fs);Sleep(100);
    ts_lifecycle[i*4]=base;ts_lifecycle[i*4+1]=Fs->data_heap->used_u8s;
    ts_lifecycle[i*4+2]=code_base;ts_lifecycle[i*4+3]=Fs->code_heap->used_u8s;
    if(base==ts_lifecycle[i*4+1] && code_base==ts_lifecycle[i*4+3])mask|=8<<(i*4);
  }
  s=MStrPrint("EXPORT terminal-scroll-lifecycle.bin %X %X\n",ts_lifecycle,sizeof(ts_lifecycle));TSLog(s);Free(s);
  s=MStrPrint("TERMINAL SCROLL LIFECYCLE %d\n",mask);TSLog(s);Free(s);
  TSLog("TERMINAL SCROLL LIFECYCLE DONE\n");
}
