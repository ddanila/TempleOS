extern U0 NativePostMsg(CTask *task,I64 code,I64 a,I64 b,I64 flags=0);
//Focus and capture are checked separately. The menu can come from an ancestor.
CTask *native_app_menu_focus;
CMenu *native_app_menu_captured;
I64 native_app_menu_task_num;

CMenu *NativeAppMenuFor(CTask *task)
{
  while(TaskValidate(task)) {
    if(task->cur_menu)return task->cur_menu;
    if(task==task->parent_task)break;
    task=task->parent_task;
  }
  return NULL;
}

CMenu *NativeAppMenuCurrent()
{
  CTask *task=sys_focus_task;
  if(!TaskValidate(task) || NativeRenderOwnerClosing(task) ||
      !Bt(&task->display_flags,DISPLAYf_NOT_RAW) ||
      Bt(&task->win_inhibit,WIf_FOCUS_TASK_MENU))return NULL;
  return NativeAppMenuFor(task);
}

U0 NativeAppMenuReset()
{
  native_app_menu_focus=NULL;
  native_app_menu_captured=NULL;
  native_app_menu_task_num=0;
}

I64 NativeAppMenuWidth(CMenuEntry *entry)
{
  I64 width=StrLen(entry->name);
  for(entry=entry->sub;entry;entry=entry->next)
    width=MaxI64(width,StrLen(entry->name));
  return (width+1)*FONT_WIDTH;
}

CMenuEntry *NativeAppMenuHit(CMenu *menu,I64 x,I64 y)
{
  CMenuEntry *entry,*child;
  I64 left=0,right,row;
  if(!menu || y<FONT_HEIGHT)return NULL;
  for(entry=menu->sub;entry;entry=entry->next) {
    right=left+NativeAppMenuWidth(entry);
    if(left<=x<right) {
      child=entry->sub;
      for(row=y/FONT_HEIGHT-1;row>0 && child;row--)child=child->next;
      return child;
    }
    left=right;
  }
  return NULL;
}

Bool NativeAppMenuVisible()
{
  CMenu *menu=NativeAppMenuCurrent;
  return menu && (ms.pos.y<FONT_HEIGHT ||
    (native_app_menu_focus==sys_focus_task && native_app_menu_captured==menu &&
     sys_focus_task->task_num==native_app_menu_task_num && ms.lb));
}

Bool NativeAppMenuMouse(I64 x,I64 y,U32 buttons,U32 previous)
{
  CTask *focus=sys_focus_task;
  CMenu *menu=NativeAppMenuCurrent;
  CMenuEntry *entry;
  if(native_app_menu_focus) {
    if(!(buttons&1)) {
      entry=NULL;
      if((previous&1) && focus==native_app_menu_focus && menu==native_app_menu_captured &&
          menu && focus->task_num==native_app_menu_task_num)
        entry=NativeAppMenuHit(menu,x,y);
      NativeAppMenuReset;
      if(entry) {
        if((entry->msg_code==MSG_KEY_DOWN || entry->msg_code==MSG_KEY_DOWN_UP) && !entry->arg2)
          entry->arg2=Char2ScanCode(entry->arg1);
        NativePostMsg(focus,entry->msg_code,entry->arg1,entry->arg2,0);
      }
    }
    return TRUE;
  }
  if(!menu || y<0 || y>=FONT_HEIGHT)return FALSE;
  if((buttons&1) && !(previous&1)) {
    native_app_menu_focus=focus;native_app_menu_captured=menu;
    native_app_menu_task_num=focus->task_num;
  }
  return TRUE;
}

U0 NativeAppMenuDraw(CDC *dc)
{
  CMenu *m=NativeAppMenuCurrent;
  CMenuEntry *tmpme,*tmpse;
  U8 *st=NULL;
  I64 i,w,x0,y0,x1=ms.pos.x,y1=ms.pos.y;
  if(!m)return;
  dc->color=m->attr>>4;
  GrRect(dc,0,0,GR_WIDTH,FONT_HEIGHT);
  x0=0;
  tmpme=m->sub;
  while (tmpme) {
    w=NativeAppMenuWidth(tmpme);
    if (x0<=x1<x0+w) {
      if (0<=y1<FONT_HEIGHT) {
	dc->color=m->attr&15;
	GrRect(dc,x0,0,w,FONT_HEIGHT);
	dc->color=m->attr>>4;
      } else
	dc->color=m->attr&15;
      GrPrint(dc,x0,0,"%s",tmpme->name);
      y0=FONT_HEIGHT;
      tmpse=tmpme->sub;
      while (tmpse) {
	if (tmpse->checked)
	  i=m->attr^0xFF;
	else
	  i=m->attr;
	if (y0<=y1<y0+FONT_HEIGHT) {
	  if (tmpse->msg_code==MSG_KEY_DOWN||
		tmpse->msg_code==MSG_KEY_DOWN_UP) {
	    if (!tmpse->arg2)
	      tmpse->arg2=Char2ScanCode(tmpse->arg1);
	    st=ScanCode2KeyName(tmpse->arg2);
	  }
	  dc->color=i&15;
	  GrRect(dc,x0,y0,w,FONT_HEIGHT);
	  dc->color=i>>4;
	  GrPrint(dc,x0,y0,"%s",tmpse->name);
	  if (st) {
	    dc->color=i>>4;
	    GrRect(dc,x0+w,y0-FONT_HEIGHT,
		  (StrLen(st)+1)*FONT_WIDTH,FONT_HEIGHT*3);
	    dc->color=i&15;
	    GrPrint(dc,x0+w,y0,"%s",st);
	    Free(st);
	  }
	} else {
	  dc->color=i>>4;
	  GrRect(dc,x0,y0,w,FONT_HEIGHT);
	  dc->color=i&15;
	  GrPrint(dc,x0,y0,"%s",tmpse->name);
	}
	y0+=FONT_HEIGHT;
	tmpse=tmpse->next;
      }
    } else {
      dc->color=m->attr&15;
      GrPrint(dc,x0,0,"%s",tmpme->name);
    }
    x0+=w;
    tmpme=tmpme->next;
  }
}
