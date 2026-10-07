I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0,x,y,color,count=0,changed;
  CDC *dc=DCNew(16,16);
  CTask *task=CAlloc(sizeof(CTask));
  DCFill(dc,BLACK);
  task->scroll_x=2;task->scroll_y=1;
  task->pix_left=3;task->pix_top=4;task->pix_right=10;task->pix_bottom=11;
  dc->win_task=task;dc->flags=DCF_SCRN_BITMAP|DCF_ON_TOP;dc->color=RED;
  changed=GrRect(dc,-1,-1,12,12);
  for(y=0;y<16;y++)for(x=0;x<16;x++) {
    color=BLACK;if(4<=x<=10 && 4<=y<=11)color=RED;
    if(dc->body[y*dc->width_internal+x]==color)count++;
  }
  if(changed==56 && count==256)mask|=1;
  if(!GrRect(dc,20,20,1,1) && dc->body[4*dc->width_internal+4]==RED)mask|=2;
  dc->win_task=Fs;dc->flags=0;Free(task);DCDel(dc);
  if(Fs->data_heap->used_u8s==base)mask|=4;
  return mask;
}
