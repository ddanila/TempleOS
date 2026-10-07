#include "/Adam/Ctrls/CtrlsCore.HC"
fp_update_ctrls=&CtrlsUpdate;

U0 DrawCtrls(CTask *task)
{
  CCtrl *c;
  CDC *dc=DCAlias(gr.dc2,task);
  c=task->next_ctrl;
  while (c!=&task->next_ctrl) {
    if (c->flags&CTRLF_SHOW) {
      if (c->flags&CTRLF_BORDER) {
	if (!Bt(&task->display_flags,DISPLAYf_NO_BORDER)) {
	  PUSHFD
	  CLI
	  while (LBts(&task->task_flags,TASKf_TASK_LOCK))
	    PAUSE

	  task->win_left--; //Allow drawing on border
	  task->win_right++;
	  task->win_top--;
	  task->win_bottom++;
	  WinDerivedValsUpdate(task);

	  LBtr(&task->task_flags,TASKf_TASK_LOCK);
	  POPFD

	  if (c->draw_it)
	    (*c->draw_it)(dc,c);

	  PUSHFD
	  CLI
	  while (LBts(&task->task_flags,TASKf_TASK_LOCK))
	    PAUSE

	  task->win_left++;
	  task->win_right--;
	  task->win_top++;
	  task->win_bottom--;
	  WinDerivedValsUpdate(task);

	  LBtr(&task->task_flags,TASKf_TASK_LOCK);
	  POPFD
	}
      } else
	if (c->draw_it)
	  (*c->draw_it)(dc,c);
    }
    c=c->next;
  }
  DCDel(dc);
}

#include "/Adam/Ctrls/WinScrollControlsCore.HC"
#define VIEWANGLES_SPACING	22
#define VIEWANGLES_RANGE	48
#define VIEWANGLES_BORDER	2
#define VIEWANGLES_SNAP		2

U0 DrawViewAnglesCtrl(CDC *dc,CCtrl *c)
{
  I64 i,j;
  CViewAngles *s=c->state;

  dc->color=s->cbd;
  GrRect(dc, c->left,c->top,VIEWANGLES_SPACING*4+3,
	VIEWANGLES_SPACING*2+VIEWANGLES_RANGE);
  dc->color=s->cbg;
  GrRect(dc, c->left+VIEWANGLES_BORDER,c->top+VIEWANGLES_BORDER,
	VIEWANGLES_SPACING*4+3-2*VIEWANGLES_BORDER,
	VIEWANGLES_SPACING*2+VIEWANGLES_RANGE-2*VIEWANGLES_BORDER);
  dc->color=s->cfg;
  GrLine(dc,c->left+VIEWANGLES_SPACING,c->top+VIEWANGLES_SPACING,
	c->left+VIEWANGLES_SPACING,c->top+VIEWANGLES_SPACING+
	VIEWANGLES_RANGE-1);
  GrLine(dc,c->left+2*VIEWANGLES_SPACING+1,c->top+VIEWANGLES_SPACING,
	c->left+2*VIEWANGLES_SPACING+1,c->top+VIEWANGLES_SPACING+
	VIEWANGLES_RANGE-1);
  GrLine(dc,c->left+3*VIEWANGLES_SPACING+2,c->top+VIEWANGLES_SPACING,
	c->left+3*VIEWANGLES_SPACING+2,c->top+VIEWANGLES_SPACING+
	VIEWANGLES_RANGE-1);
  for (i=1;i<VIEWANGLES_RANGE+1;i+=2*VIEWANGLES_SNAP) {
    j=2-i/3&1;
    GrLine(dc,c->left+VIEWANGLES_SPACING-j,c->bottom-VIEWANGLES_SPACING-i,
	  c->left+VIEWANGLES_SPACING+j,c->bottom
	  -VIEWANGLES_SPACING-i);
    GrLine(dc,c->left+2*VIEWANGLES_SPACING+1-j,c->bottom-VIEWANGLES_SPACING-i,
	  c->left+2*VIEWANGLES_SPACING+1+j,c->bottom
	  -VIEWANGLES_SPACING-i);
    GrLine(dc,c->left+3*VIEWANGLES_SPACING+2-j,c->bottom-VIEWANGLES_SPACING-i,
	  c->left+3*VIEWANGLES_SPACING+2+j,c->bottom
	  -VIEWANGLES_SPACING-i);
  }

  dc->color=s->cx;
  GrPrint(dc,c->left+VIEWANGLES_SPACING-FONT_WIDTH/2,
	c->top+VIEWANGLES_SPACING-(1+FONT_HEIGHT),"X");
  GrPrint(dc,c->left+VIEWANGLES_SPACING-3*FONT_WIDTH/2,
	c->top+VIEWANGLES_SPACING+VIEWANGLES_RANGE+3,
	"%3d",s->sx*360/VIEWANGLES_RANGE);
  i=c->left+VIEWANGLES_SPACING;
  if (s->sx>VIEWANGLES_RANGE/2)
    j=-VIEWANGLES_RANGE/2+s->sx;
  else
    j=s->sx+VIEWANGLES_RANGE/2;
  j=c->top+VIEWANGLES_SPACING+VIEWANGLES_RANGE-1-j;
  GrRect(dc,i-3,j-2,7,5);
  dc->color=s->cx^8;
  GrRect(dc,i-2,j-1,5,3);

  dc->color=s->cy;
  GrPrint(dc,c->left+2*VIEWANGLES_SPACING+1-FONT_WIDTH/2,
	c->top+VIEWANGLES_SPACING-(1+FONT_HEIGHT),"Y");
  GrPrint(dc,c->left+2*VIEWANGLES_SPACING+1-3*FONT_WIDTH/2,
	c->top+VIEWANGLES_SPACING+VIEWANGLES_RANGE+3,
	"%3d",s->sy*360/VIEWANGLES_RANGE);
  i=c->left+2*VIEWANGLES_SPACING+1;
  if (s->sy>VIEWANGLES_RANGE/2)
    j=-VIEWANGLES_RANGE/2+s->sy;
  else
    j=s->sy+VIEWANGLES_RANGE/2;
  j=c->top+VIEWANGLES_SPACING+VIEWANGLES_RANGE-1-j;
  GrRect(dc,i-3,j-2,7,5);
  dc->color=s->cy^8;
  GrRect(dc,i-2,j-1,5,3);

  dc->color=s->cz;
  GrPrint(dc,c->left+3*VIEWANGLES_SPACING+2-FONT_WIDTH/2,
	c->top+VIEWANGLES_SPACING-(1+FONT_HEIGHT),"Z");
  GrPrint(dc,c->left+3*VIEWANGLES_SPACING+2-3*FONT_WIDTH/2,
	c->top+VIEWANGLES_SPACING+VIEWANGLES_RANGE+3,
	"%3d",s->sz*360/VIEWANGLES_RANGE);
  i=c->left+3*VIEWANGLES_SPACING+2;
  if (s->sz>VIEWANGLES_RANGE/2)
    j=-VIEWANGLES_RANGE/2+s->sz;
  else
    j=s->sz+VIEWANGLES_RANGE/2;
  j=c->top+VIEWANGLES_SPACING+VIEWANGLES_RANGE-1-j;
  GrRect(dc,i-3,j-2,7,5);
  dc->color=s->cz^8;
  GrRect(dc,i-2,j-1,5,3);
}

U0 UpdateDerivedViewAnglesCtrl(CCtrl *c)
{
  CViewAngles *s=c->state;
  c->left=c->win_task->pix_width-(VIEWANGLES_SPACING*4+3);
  c->right=c->left+VIEWANGLES_SPACING*4+3;
  c->top=c->win_task->pix_height-(VIEWANGLES_SPACING*2+VIEWANGLES_RANGE);
  c->bottom=c->top+VIEWANGLES_SPACING*2+VIEWANGLES_RANGE;
  s->sx=ClampI64(RoundI64(s->sx,VIEWANGLES_SNAP),0,VIEWANGLES_RANGE-1);
  s->sy=ClampI64(RoundI64(s->sy,VIEWANGLES_SNAP),0,VIEWANGLES_RANGE-1);
  s->sz=ClampI64(RoundI64(s->sz,VIEWANGLES_SNAP),0,VIEWANGLES_RANGE-1);
  s->ax=2*ã*s->sx/VIEWANGLES_RANGE;
  s->ay=2*ã*s->sy/VIEWANGLES_RANGE;
  s->az=2*ã*s->sz/VIEWANGLES_RANGE;
}

U0 LeftClickViewAngles(CCtrl *c,I64 x,I64 y,Bool)
{
  CViewAngles *s=c->state;
  I64 i;
  i=VIEWANGLES_RANGE-1-(y-(c->top+VIEWANGLES_SPACING));
  if (i>=VIEWANGLES_RANGE/2)
    i-=VIEWANGLES_RANGE/2;
  else
    i+=VIEWANGLES_RANGE/2;
  if (x<c->left+(c->right-c->left)/3)
    s->sx=i;
  else if (x<c->left+2*(c->right-c->left)/3)
    s->sy=i;
  else
    s->sz=i;
  if (c->update_derived_vals)
    (*c->update_derived_vals)(c);
}

public CCtrl *ViewAnglesNew(CTask *task=NULL)
{//Create view angle ctrl. See $LK,"::/Demo/Graphics/Shading.HC"$.
  CCtrl *c;
  CViewAngles *s;
  if (!task) task=Fs;
  if (!(c=CtrlFindUnique(task,CTRLT_VIEWING_ANGLES))) {
    s=CAlloc(sizeof(CViewAngles),task);
    c=CAlloc(sizeof(CCtrl));
    s->cbd=BLUE;
    s->cbg=LTBLUE;
    s->cfg=BLACK;
    s->cx=LTGREEN;
    s->cy=GREEN;
    s->cz=LTGREEN;
    c->win_task=task;
    c->flags=CTRLF_SHOW|CTRLF_CAPTURE_LEFT_MS;
    c->type=CTRLT_VIEWING_ANGLES;
    c->state=s;
    c->draw_it=&DrawViewAnglesCtrl;
    c->left_click=&LeftClickViewAngles;
    c->update_derived_vals=&UpdateDerivedViewAnglesCtrl;
    QueIns(c,task->last_ctrl);
    TaskDerivedValsUpdate(task);
  }
  return c;
}

public U0 ViewAnglesDel(CTask *task=NULL)
{//Free view angle ctrl.
  CCtrl *c;
  if (!task) task=Fs;
  if (c=CtrlFindUnique(task,CTRLT_VIEWING_ANGLES)) {
    QueRem(c);
    Free(c->state);
    Free(c);
  }
}
