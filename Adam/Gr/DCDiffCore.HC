#ifdef I386_DC_EXT_EXPLICIT_CONTEXT
public CDC *DCExt(CDC *dc,I64 x1,I64 y1,I64 x2,I64 y2,
#else
public CDC *DCExt(CDC *dc=gr.dc,I64 x1,I64 y1,I64 x2,I64 y2,
#endif
	CTask *task=NULL)
{//Extract new device context rect from device context.
  CDC *res;
  CTask *win_task;
  if (x1>x2) SwapI64(&x1,&x2);
  if (y1>y2) SwapI64(&y1,&y2);
  if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x1+=win_task->pix_left+win_task->scroll_x;
    y1+=win_task->pix_top +win_task->scroll_y;
    x2+=win_task->pix_left+win_task->scroll_x;
    y2+=win_task->pix_top +win_task->scroll_y;
  }
  res=DCNew(x2-x1+1,y2-y1+1,task);
  DCFill(res);
  GrBlot(res,-x1,-y1,dc);
  return res;
}

public CDC *DCDiff(CDC *base,CDC *update)
{//Trim to win of what has chged.
  I64 i,x1=0,y1=0,x2=update->width-1,y2=update->height-1; //inclusive
  U32 *ptr_base,*ptr_update;
  CDC *res;
  ptr_base  =base->body;
  ptr_update=update->body;
  while (y1<=y2) {
    i=update->width>>2;
    while (i--)
      if (*ptr_base++!=*ptr_update++)
	goto df_y2;
    i=update->width&3;
    while (i--)
      if (*ptr_base(U8 *)++!=*ptr_update(U8 *)++)
	goto df_y2;
    y1++;
  }
  return NULL;
df_y2:
  ptr_base  =base->body  +base->width_internal	*base->height;
  ptr_update=update->body+update->width_internal*update->height;
  while (y1<y2) {
    i=update->width>>2;
    while (i--)
      if (*--ptr_base!=*--ptr_update)
	goto df_x1;
    i=update->width&3;
    while (i--)
      if (*--ptr_base(U8 *)!=*--ptr_update(U8 *))
	goto df_x1;
    y2--;
  }
df_x1:
  while (x1<x2) {
    for (i=y1;i<=y2;i++)
      if (GrPeek0(base,x1,i)!=GrPeek0(update,x1,i))
	 goto df_x2;
    x1++;
  }
df_x2:
  while (x1<x2) {
    for (i=y1;i<=y2;i++)
      if (GrPeek0(base,x2,i)!=GrPeek0(update,x2,i))
	 goto df_done;
    x2--;
  }
df_done:
  res=DCExt(update,x1,y1,x2,y2);
  res->x0=x1;
  res->y0=y1;
  return res;
}

