#ifndef WIN_CURSOR_SCOPE_LOCAL
#define WIN_CURSOR_SCOPE_LOCAL
#define WIN_CURSOR_SCOPE_OPEN
#define WIN_CURSOR_SCOPE_DOC
#define WIN_CURSOR_SCOPE_CLOSE
#endif
CDoc *WinCursorPosSet(CTask *task,I64 msx,I64 msy,Bool set_cursor=TRUE)
{
  CDoc *res=NULL,*locked_doc=NULL;
  Bool unlock=FALSE;
  I64 x0,y0;
  WIN_CURSOR_SCOPE_LOCAL;
  if (!task) task=Fs;
  try {
    if (WinInside(msx,msy,task)) {
      WIN_CURSOR_SCOPE_OPEN;
      if ((res=DocDisplay(task)) && res->flags&DOCF_DONT_SHOW)
        res=NULL;
      WIN_CURSOR_SCOPE_DOC;
      if (res && set_cursor) {
        locked_doc=res;unlock=DocLock(res);
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
        }
        if (unlock) {unlock=FALSE;DocUnlock(locked_doc);}
      }
      WinToTop(task);
    }
  } catch {
    if (unlock) {unlock=FALSE;DocUnlock(locked_doc);}
    WIN_CURSOR_SCOPE_CLOSE;
  }
  WIN_CURSOR_SCOPE_CLOSE;
  return res;
}
