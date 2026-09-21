//Portable form of GrTextBase's character/window clipping and U32 cell writes.
Bool TextBaseCharCore(U32 *base,I64 cols,I64 rows,CTask *task,Bool border,
  I64 x,I64 y,I64 value)
{
  I64 low=0,extra=0;
  if(border) { low=-1; extra=1; }
  x+=task->scroll_x>>3; y+=task->scroll_y>>3;
  if(x<low || y<low) return FALSE;
  x+=task->win_left; y+=task->win_top;
  if(x>task->win_right+extra || x<0 || x>=cols ||
      y>task->win_bottom+extra || y<0 || y>=rows) return FALSE;
  base[y*cols+x]=value;
  return TRUE;
}
Bool TextBaseSpanCore(I64 cols,I64 rows,CTask *task,
  I64 *x,I64 *y,I64 *length,I64 *skip)
{
  I64 end,over;
  *skip=0; *x+=task->scroll_x>>3;
  if(*x<0) { *length+=*x; *skip-=*x; *x=0; }
  *x+=task->win_left; end=*x+*length-1;
  if(end>task->win_right) {
    over=end-task->win_right; end-=over; *length-=over;
  }
  if(*x<0) { *length+=*x; *skip-=*x; *x=0; }
  over=end+1-cols;
  if(over>0) *length-=over;
  if(*length<1) return FALSE;
  *y+=task->scroll_y>>3;
  if(*y<0) return FALSE;
  *y+=task->win_top;
  if(*y>task->win_bottom || *y<0 || *y>=rows) return FALSE;
  return TRUE;
}
Bool TextBaseStrCore(U32 *base,I64 cols,I64 rows,CTask *task,
  I64 x,I64 y,I64 length,I64 attr,U8 *str)
{
  I64 skip,i;
  if(!TextBaseSpanCore(cols,rows,task,&x,&y,&length,&skip)) return FALSE;
  base+=y*cols+x; str+=skip;
  for(i=0;i<length;i++) base[i]=(attr&~0xFF)|str[i];
  return TRUE;
}
Bool TextBaseAttrStrCore(U32 *base,I64 cols,I64 rows,CTask *task,
  I64 x,I64 y,I64 length,U32 *attrs)
{
  I64 skip,i;
  if(!TextBaseSpanCore(cols,rows,task,&x,&y,&length,&skip)) return FALSE;
  base+=y*cols+x; attrs+=skip;
  for(i=0;i<length;i++) base[i]=attrs[i];
  return TRUE;
}
Bool TextBaseAttrCore(U32 *base,I64 cols,I64 rows,CTask *task,
  I64 x,I64 y,I64 length,I64 attr)
{
  I64 skip,i;
  if(!TextBaseSpanCore(cols,rows,task,&x,&y,&length,&skip)) return FALSE;
  base+=y*cols+x;
  for(i=0;i<length;i++) {
    if(base[i]&0xFF) break;
    base[i]=attr;
  }
  return TRUE;
}
