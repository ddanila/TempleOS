#ifndef TASK_SETTINGS_TYPES_INCLUDED
#define TASK_SETTINGS_TYPES_INCLUDED
#include "/Kernel/ColorTypes.HH"
#include "/Kernel/StringLimits.HH"
#define TSF_SAME_SONG	1
public class CTaskSettings
{
  CTaskSettings *next;
  U8	*cur_dir;
  I64	left,right,top,bottom;
  U0	(*draw_it)(CTask *task,CDC *dc);
  U0	(*task_end_cb)();
  CTask *song_task,*animate_task;
  I64	scroll_x,scroll_y,scroll_z;
  CBGR48 palette[COLORS_NUM];
  U32	win_inhibit;
  U8	text_attr,title_src,
	border_attr,border_src,
	task_title[STR_LEN];
  Bool	border,hide_cursor,highlight_cursor,scroll,autocomplete,pad[3];
#assert !($$&7)
};

#endif
