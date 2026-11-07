U0 WCContract()
{
  CTask *task=Fs,*focus=sys_focus_task;
  CDoc *put=DocPut,*display=DocDisplay,*doc=DocNew("Cursor.DD");
  CDocEntry *first,*second,*entry;
  I64 left=task->win_left,right=task->win_right,top=task->win_top,bottom=task->win_bottom;
  I64 sx=task->scroll_x,sy=task->scroll_y,sz=task->scroll_z;
  I64 flags=task->display_flags,inhibit=task->win_inhibit,rows[16],details[12],x,y,col;
  U8 *text="abcdefghij\nklmnopqrst",*s,*p;
  doc->flags|=DOCF_PLAIN_TEXT;DocLoad(doc,text,StrLen(text));DocTop(doc);
  first=doc->head.next;second=doc->head.last;
  task->put_doc=task->display_doc=doc;
  Bts(&task->display_flags,DISPLAYf_SHOW);
  Bts(&task->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Btr(&task->win_inhibit,WIf_SELF_FOCUS);
  WinHorz(3,52);WinVert(4,29);
  task->scroll_x=task->scroll_y=task->scroll_z=0;
  x=task->pix_left;y=task->pix_top;
  DocLock(doc);
  rows[0]=WinCursorPosSet(NULL,x+3*FONT_WIDTH,y)==doc;
  rows[1]=doc->cur_entry==first && doc->cur_col==3;
  rows[2]=Bt(&doc->locked_flags,DOClf_LOCKED) && doc->owning_task==task;
  rows[3]=WinCursorPosSet(task,x+4*FONT_WIDTH,y+FONT_HEIGHT)==doc &&
    doc->cur_entry==second && doc->cur_col==4;
  task->scroll_x=16;task->scroll_y=8;task->scroll_z=3;
  rows[4]=WinCursorPosSet(task,x+16+2*FONT_WIDTH,y+8)==doc &&
    doc->cur_entry==first && doc->cur_col==2;
  rows[5]=!task->scroll_x && !task->scroll_y && !task->scroll_z;
  entry=doc->cur_entry;col=doc->cur_col;
  task->scroll_x=16;task->scroll_y=8;task->scroll_z=3;
  rows[6]=WinCursorPosSet(task,x,y,FALSE)==doc && doc->cur_entry==entry &&
    doc->cur_col==col && task->scroll_x==16 && task->scroll_y==8 && task->scroll_z==3;
  rows[7]=sys_focus_task==task;
  rows[8]=!WinCursorPosSet(task,x-1,y) && !WinCursorPosSet(task,task->pix_right+1,y) &&
    !WinCursorPosSet(task,x,y-1) && !WinCursorPosSet(task,x,task->pix_bottom+1) &&
    doc->cur_entry==entry && doc->cur_col==col && task->scroll_x==16;
  doc->flags|=DOCF_DONT_SHOW;
  rows[9]=!WinCursorPosSet(task,x,y) && doc->cur_entry==entry && doc->cur_col==col;
  doc->flags&=~DOCF_DONT_SHOW;
  Btr(&task->display_flags,DISPLAYf_SHOW);
  rows[10]=!WinCursorPosSet(task,x,y) && doc->cur_entry==entry && doc->cur_col==col;
  Bts(&task->display_flags,DISPLAYf_SHOW);
  task->scroll_x=task->scroll_y=task->scroll_z=0;
  details[0]=x;details[1]=task->pix_left;details[2]=y;details[3]=task->pix_top;
  details[4]=doc->line_start_col;details[5]=doc->top_line_num;
  DocUnlock(doc);
  //The preceding scroll-adjusted selection left viewport (2,1). Query and
  //hidden cases preserve it; this click therefore selects second-line col 3.
  rows[11]=WinCursorPosSet(task,x+FONT_WIDTH,y)==doc && doc->cur_entry==second && doc->cur_col==3;
  details[6]=doc->x;details[7]=doc->y;details[8]=doc->cur_col;
  details[9]=doc->cur_entry==first;details[10]=doc->line_start_col;details[11]=doc->top_line_num;
  rows[12]=!Bt(&doc->locked_flags,DOClf_LOCKED);
  rows[13]=!StrCmp(first->tag,"abcdefghij") && !StrCmp(second->tag,"klmnopqrst");
  rows[14]=details[4]==2 && details[5]==1;
  rows[15]=details[10]==0 && details[11]==0;
  task->put_doc=put;task->display_doc=display;
  task->display_flags=flags;task->win_inhibit=inhibit;
  WinHorz(left,right);WinVert(top,bottom);
  task->scroll_x=sx;task->scroll_y=sy;task->scroll_z=sz;
  DocDel(doc);if(TaskValidate(focus))WinToTop(focus);
  s=MStrPrint("EXPORT cursor.bin %X %X\n",rows,sizeof(rows));
  p=s;while(*p)OutU8(0xE9,*p++);Free(s);
  s=MStrPrint("EXPORT details.bin %X %X\n",details,sizeof(details));
  p=s;while(*p)OutU8(0xE9,*p++);Free(s);
  p="WIN CURSOR DONE\n";while(*p)OutU8(0xE9,*p++);
  Sleep(1000);
}
