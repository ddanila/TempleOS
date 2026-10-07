U0 SCIdle(U8 *data){while(TRUE)Yield;}
I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0,count=0,used;
  CTask *task=Spawn(&SCIdle,NULL,"Scroll",-1,Fs);
  CCtrl *h,*v,*c;
  task->win_left=0;task->win_right=39;task->win_top=0;task->win_bottom=19;
  WinScrollsInit(task);
  h=CtrlFindUnique(task,CTRLT_WIN_HSCROLL);
  v=CtrlFindUnique(task,CTRLT_WIN_VSCROLL);
  for(c=task->next_ctrl;c!=&task->next_ctrl;c=c->next)count++;
  if(h && v && count==2 && h->win_task==task && v->win_task==task && h->state==&task->horz_scroll && v->state==&task->vert_scroll && h->draw_it && v->draw_it)mask|=1;
  used=Fs->data_heap->used_u8s;WinScrollsInit(task);
  if(Fs->data_heap->used_u8s==used && CtrlFindUnique(task,CTRLT_WIN_HSCROLL)==h && CtrlFindUnique(task,CTRLT_WIN_VSCROLL)==v)mask|=2;
  task->horz_scroll.min=0;task->horz_scroll.max=19;task->horz_scroll.pos=10;
  (*h->left_click)(h,4,0,TRUE);
  if(!task->horz_scroll.pos && (h->flags&CTRLF_CLICKED) && Bt(&task->horz_scroll.flags,WSSf_SET_TO_POS))mask|=4;
  (*h->left_click)(h,4,0,FALSE);
  task->vert_scroll.min=0;task->vert_scroll.max=19;task->vert_scroll.pos=10;
  (*v->wheel_chg)(v,100);
  if(task->vert_scroll.pos==19 && !(h->flags&CTRLF_CLICKED))mask|=8;
  task->vert_scroll.min=5;task->vert_scroll.max=3;task->vert_scroll.pos=99;
  (*v->update_derived_vals)(v);
  if(task->vert_scroll.max==5 && task->vert_scroll.pos==5 && v->right-v->left==7 && v->bottom-v->top==7)mask|=16;
  QueRem(h);Free(h);QueRem(v);Free(v);Kill(task);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
