#help_index "Menus"
#help_file "::/Doc/Menus"

CTask *MenuTask()
{
  CTask *res=sys_focus_task;
  while (res && !res->cur_menu)
    res=res->parent_task;
  return res;
}

CMenuEntry *sys_cur_submenu_entry=NULL;

#include "/Adam/MenuParseCore.HC"

I64 MenuEntryWidth(CMenuEntry *tmpme)
{
  I64 res=StrLen(tmpme->name);
  CMenuEntry *tmpse=tmpme->sub;
  while (tmpse) {
    res=MaxI64(res,StrLen(tmpse->name));
    tmpse=tmpse->next;
  }
  return res+1;
}

public CMenu *MenuPush(U8 *st)
{//Save old pulldown menu and replace with new from str.
  CMenu *m=MenuNew(st);
  m->next=Fs->cur_menu;
  Fs->cur_menu=m;
  return m;
}

public CMenu *MenuFilePush(U8 *filename)
{//Save old pulldown menu and replace with new from file.
  CMenu *m=MenuFile(filename);
  m->next=Fs->cur_menu;
  Fs->cur_menu=m;
  return m;
}

public U0 MenuPop()
{//Restore old pulldown menu. Delete just-deactivated menu.
  CMenu *m=Fs->cur_menu;
  if (!m) return;
  Fs->cur_menu=m->next;
  MenuDel(m);
}

U0 DrawMenu(CDC *dc)
{
  CMenu *m;
  CMenuEntry *tmpme,*tmpse,*cur_submenu=NULL;
  U8 *st=NULL;
  CTask *task=MenuTask;
  I64 i,w,x0,y0,x1=ms.pos.x,y1=ms.pos.y;
  if (!TaskValidate(task) || !(m=task->cur_menu)) {
    sys_cur_submenu_entry=NULL;
    return;
  }
  dc->color=m->attr>>4;
  GrRect(dc,0,0,GR_WIDTH,FONT_HEIGHT);
  x0=0;
  tmpme=m->sub;
  while (tmpme) {
    w=MenuEntryWidth(tmpme)*FONT_WIDTH;
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
	  sys_cur_submenu_entry=cur_submenu=tmpse;
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
  sys_cur_submenu_entry=cur_submenu;
}
