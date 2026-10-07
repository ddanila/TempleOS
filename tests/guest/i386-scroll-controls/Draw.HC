U0 SCIdle(U8 *data){while(TRUE)Yield;}
I64 SCMatch(CDC *dc,Bool pressed)
{
  I64 x,y,color,count=0;
  for(y=0;y<16;y++)for(x=0;x<16;x++) {
    color=BLACK;
    if(2<=x<=9 && 3<=y<=10) { if(pressed)color=RED;else color=BLUE; }
    if(4<=x<=7 && 5<=y<=8) { if(pressed)color=BLUE;else color=RED; }
    if(dc->body[y*dc->width_internal+x]==color)count++;
  }
  return count;
}
I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0;
  CTask *task=Spawn(&SCIdle,NULL,"DrawScroll",-1,Fs);
  CCtrl *h,*v;
  CDC *dc=DCNew(16,16);
  WinScrollsInit(task);
  h=CtrlFindUnique(task,CTRLT_WIN_HSCROLL);v=CtrlFindUnique(task,CTRLT_WIN_VSCROLL);
  h->left=2;h->right=9;h->top=3;h->bottom=10;task->horz_scroll.color=0x41;
  DCFill(dc,BLACK);h->flags&=~CTRLF_CLICKED;(*h->draw_it)(dc,h);
  if(SCMatch(dc,FALSE)==256)mask|=1;
  DCFill(dc,BLACK);h->flags|=CTRLF_CLICKED;(*h->draw_it)(dc,h);
  if(SCMatch(dc,TRUE)==256)mask|=2;
  DCDel(dc);QueRem(h);Free(h);QueRem(v);Free(v);Kill(task);
  if(Fs->data_heap->used_u8s==base)mask|=4;
  return mask;
}
