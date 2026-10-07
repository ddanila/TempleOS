#define WIN_SCROLL_SIZE		8
#define WIN_SCROLL_BORDER_BONUS	4
U0 DrawWinScroll(CDC *dc,CCtrl *c)
{
  CWinScroll *s=c->state;

  if (c->flags&CTRLF_CLICKED)
    dc->color=s->color>>4;
  else
    dc->color=s->color&0xF;
  GrRect(dc,c->left,c->top,c->right-c->left+1,c->bottom-c->top+1);

  if (c->flags&CTRLF_CLICKED)
    dc->color=s->color&0xF;
  else
    dc->color=s->color>>4;
  GrRect(dc,c->left+2,c->top+2,c->right-c->left+1-4,c->bottom-c->top+1-4);
}

U0 WinDerivedScrollValsUpdate(CCtrl *c)
{
  CWinScroll *s=c->state;
  I64 range;
  if (s->max<s->min) s->max=s->min;
  if (s->pos<s->min) s->pos=s->min;
  if (s->pos>s->max) s->pos=s->max;
  s->color=c->win_task->border_attr&0xF^0xF+
	(c->win_task->border_attr&0xF)<<4;
  range=s->max-s->min;
  if (!range) range=1;
  switch (c->type) {
    case CTRLT_WIN_HSCROLL:
      c->left  =gr.pan_text_x+FONT_WIDTH-WIN_SCROLL_BORDER_BONUS+
	    (s->pos-s->min)*(c->win_task->pix_width+2*WIN_SCROLL_BORDER_BONUS
	    -WIN_SCROLL_SIZE)/range;
      c->right =c->left+WIN_SCROLL_SIZE-1;
      c->top   =gr.pan_text_y+FONT_HEIGHT+
	    (FONT_WIDTH-WIN_SCROLL_SIZE)/2+c->win_task->pix_height;
      c->bottom=c->top+WIN_SCROLL_SIZE-1;
      break;
    case CTRLT_WIN_VSCROLL:
      c->left  =gr.pan_text_x+FONT_WIDTH+
	    (FONT_WIDTH-WIN_SCROLL_SIZE)/2+c->win_task->pix_width;
      c->right =c->left+WIN_SCROLL_SIZE-1;
      c->top   =gr.pan_text_y+FONT_HEIGHT-WIN_SCROLL_BORDER_BONUS+
	    (s->pos-s->min)*(c->win_task->pix_height+
	    2*WIN_SCROLL_BORDER_BONUS-WIN_SCROLL_SIZE)/range;
      c->bottom=c->top+WIN_SCROLL_SIZE-1;
      break;
  }
}

U0 LeftClickHWinScroll(CCtrl *c,I64 x,I64,Bool down)
{
  CTask *task=c->win_task;
  CWinScroll *s=c->state;
  I64 range=task->pix_width+2*WIN_SCROLL_BORDER_BONUS-WIN_SCROLL_SIZE;
  LBts(&s->flags,WSSf_SET_TO_POS);
  s->pos=((x-(FONT_WIDTH-WIN_SCROLL_BORDER_BONUS))
  *(s->max-s->min+1)+range/2)/range+s->min;
  if (down)
    c->flags|=CTRLF_CLICKED;
  else
    c->flags&=~CTRLF_CLICKED;
  if (c->update_derived_vals)
    (*c->update_derived_vals)(c);
}

U0 LeftClickVWinScroll(CCtrl *c,I64,I64 y,Bool down)
{
  CTask *task=c->win_task;
  CWinScroll *s=c->state;
  I64 range=task->pix_height+2*WIN_SCROLL_BORDER_BONUS-WIN_SCROLL_SIZE;
  LBts(&s->flags,WSSf_SET_TO_POS);
  s->pos=((y-(FONT_HEIGHT-WIN_SCROLL_BORDER_BONUS))
  *(s->max-s->min+1)+range/2)/range+s->min;
  if (down)
    c->flags|=CTRLF_CLICKED;
  else
    c->flags&=~CTRLF_CLICKED;
  if (c->update_derived_vals)
    (*c->update_derived_vals)(c);
}

U0 WheelChangeWinScroll(CCtrl *c,I64 delta)
{
  CWinScroll *s=c->state;
  LBts(&s->flags,WSSf_SET_TO_POS);
  s->pos+=delta;
  if (c->update_derived_vals)
    (*c->update_derived_vals)(c);
}

U0 WinScrollsInit(CTask *task)
{
  CCtrl *c;

  if (!CtrlFindUnique(task,CTRLT_WIN_HSCROLL)) {
    c=CAlloc(sizeof(CCtrl));
    c->win_task=task;
    c->flags=CTRLF_SHOW|CTRLF_BORDER|CTRLF_CAPTURE_LEFT_MS;
    c->type=CTRLT_WIN_HSCROLL;
    c->state=&task->horz_scroll;
    c->update_derived_vals=&WinDerivedScrollValsUpdate;
    c->draw_it=&DrawWinScroll;
    c->left_click=&LeftClickHWinScroll;
    QueIns(c,task->last_ctrl);
  }

  if (!CtrlFindUnique(task,CTRLT_WIN_VSCROLL)) {
    c=CAlloc(sizeof(CCtrl));
    c->win_task=task;
    c->flags=CTRLF_SHOW|CTRLF_BORDER|CTRLF_CAPTURE_LEFT_MS;
    c->type=CTRLT_WIN_VSCROLL;
    c->state=&task->vert_scroll;
    c->update_derived_vals=&WinDerivedScrollValsUpdate;
    c->draw_it=&DrawWinScroll;
    c->left_click=&LeftClickVWinScroll;
    c->wheel_chg=&WheelChangeWinScroll;
    QueIns(c,task->last_ctrl);
  }
  TaskDerivedValsUpdate(task);
}
