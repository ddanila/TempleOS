#ifndef CONTROL_TYPES_INCLUDED
#define CONTROL_TYPES_INCLUDED
#help_index "Ctrls"
#define CTRLT_GENERIC		0
#define CTRLT_WIN_HSCROLL	1 //unique
#define CTRLT_WIN_VSCROLL	2 //unique
#define CTRLT_VIEWING_ANGLES	3 //unique

#define CTRLF_SHOW		1
#define CTRLF_BORDER		2
#define CTRLF_CAPTURE_LEFT_MS	4
#define CTRLF_CAPTURE_RIGHT_MS	8
#define CTRLF_CLICKED		16

#define WSSf_SET_TO_POS		0

public class CCtrl
{
  CCtrl *next,*last;
  CTask *win_task;
  I64	type,flags;

  //win pix coordinates
  I64	left,right,top,bottom;

  //scrn pix coordinates (derived)
  I64	scrn_left,scrn_right,scrn_top,scrn_bottom;

  U8	*state;

  //called on resize
  U0	(*update_derived_vals)(CCtrl *c);
  U0	(*draw_it)(CDC *dc,CCtrl *c);

  Bool	(*inside_ctrl)(CCtrl *c,I64 x,I64 y); //For nonbox shapes
  U0	(*left_click)(CCtrl *c,I64 x,I64 y,Bool down);
  U0	(*right_click)(CCtrl *c,I64 x,I64 y,Bool down);
  U0	(*wheel_chg)(CCtrl *c,I64 delta);
};
#endif
