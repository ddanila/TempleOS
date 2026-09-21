public CCtrl *CtrlFindUnique(CTask *haystack_task,I64 needle_type)
{//Find task ctrl given $LK,"ctrl_type",A="MN:CTRLT_VIEWING_ANGLES"$.
  CCtrl *c;
  c=haystack_task->next_ctrl;
  while (c!=&haystack_task->next_ctrl) {
    if (c->type==needle_type)
      return c;
    c=c->next;
  }
  return NULL;
}

U0 CtrlsUpdate(CTask *task)
{
  CCtrl *c;
  c=task->next_ctrl;
  while (c!=&task->next_ctrl) {
    if (c->update_derived_vals)
      (*c->update_derived_vals)(c);
    if (c->flags&CTRLF_BORDER) {
      c->scrn_left  =gr.pan_text_x+task->pix_left+c->left-FONT_WIDTH;
      c->scrn_right =gr.pan_text_x+task->pix_left+c->right-FONT_WIDTH;
      c->scrn_top   =gr.pan_text_y+task->pix_top+c->top-FONT_HEIGHT;
      c->scrn_bottom=gr.pan_text_y+task->pix_top+c->bottom-FONT_HEIGHT;
    } else {
      c->scrn_left  =gr.pan_text_x+task->pix_left+c->left;
      c->scrn_right =gr.pan_text_x+task->pix_left+c->right;
      c->scrn_top   =gr.pan_text_y+task->pix_top+c->top;
      c->scrn_bottom=gr.pan_text_y+task->pix_top+c->bottom;
    }
    c=c->next;
  }
}

Bool CtrlInsideRect(CCtrl *c,I64 x,I64 y)
{//scrn coordinates
  if (c->scrn_left<=x<=c->scrn_right &&
	c->scrn_top<=y<=c->scrn_bottom)
    return TRUE;
  else
    return FALSE;
}

public Bool CtrlInside(CCtrl *c,I64 x,I64 y)
{//Is x,y inside a ctrl?
  if (c->flags&CTRLF_SHOW) {
    if (c->inside_ctrl)
      return (*c->inside_ctrl)(c,x,y);
    else
      return CtrlInsideRect(c,x,y);
  } else
    return FALSE;
}
