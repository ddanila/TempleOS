CDoc *WinCursorPosSet(CTask *task,I64 msx,I64 msy,Bool set_cursor=TRUE)
{
  CDoc *res=NULL;
  Bool unlock;
  I64 x0,y0;
  if (!task) task=Fs;
  if (WinInside(msx,msy,task)) {
    if ((res=DocDisplay(task)) && res->flags&DOCF_DONT_SHOW)
      res=NULL;
    else if (set_cursor) {
      unlock=DocLock(res);
      if (res->doc_signature!=DOC_SIGNATURE_VAL)
	res=NULL;
      else {
	x0=res->line_start_col;
	y0=res->top_line_num;
	DocRecalc(res,RECALCF_HAS_CURSOR);
	res->x=(msx-task->pix_left-task->scroll_x)/FONT_WIDTH +x0;
	res->y=(msy-task->pix_top -task->scroll_y)/FONT_HEIGHT+y0;
	DocRecalc(res,RECALCt_FIND_CURSOR);
	task->scroll_x=0;
	task->scroll_y=0;
	task->scroll_z=0;
	if (unlock)
	  DocUnlock(res);
      }
    }
    WinToTop(task);
  }
  return res;
}
