#ifndef DOC_ED_FUNCTION
#define DOC_ED_FUNCTION DocEd
#endif
#ifndef DOC_VIEW_FUNCTION
#define DOC_VIEW_FUNCTION View
#endif
//Complete original View and DocEd state/input path.
#help_index "DolDoc/Output;StdOut/DolDoc"

public Bool DOC_VIEW_FUNCTION()
{//Go live for user interaction until <ESC> or <SHIFT-ESC>.
  I64 ch;
  do ch=DocGetKey;
  while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);
  return ch==CH_ESC;
}

#help_index "DolDoc"

#include "/Adam/DolDoc/DocEdStateCore.HC"
#ifndef DOC_ED_SCOPE_LOCAL
#define DOC_ED_SCOPE_LOCAL
#define DOC_ED_SCOPE_OPEN
#define DOC_ED_RESTORE DocEdStateRestore(&state)
#endif

public Bool DOC_ED_FUNCTION(CDoc *doc,I64 dof_flags=0)
{//Live for user interaction. End on <ESC> or <SHIFT-ESC>.
  CDocEdState state;
  CDocEntry *doc_e;
  Bool res;
  DOC_ED_SCOPE_LOCAL;
  MemSet(&state,0,sizeof(CDocEdState));
  state.task=Fs;state.doc=doc;state.dof_flags=dof_flags;
  state.old_put_doc=DocPut;state.old_display_doc=DocDisplay;state.old_border_doc=DocBorder;
  state.old_attr=Fs->text_attr;state.old_title_src=Fs->title_src;
  state.old_top=Fs->win_top;state.old_bottom=Fs->win_bottom;
  state.old_left=Fs->win_left;state.old_right=Fs->win_right;
  try {
  DOC_ED_SCOPE_OPEN;
  if (dof_flags&DOF_WIN_MAX)
    WinMax;

  state.unlock=DocLock(doc);
  state.lock_saved=TRUE;
  doc->win_task=Fs;
  state.bdoc=DocNew;
  state.bdoc->flags|=DOCF_BORDER_DOC;
  DocPrint(state.bdoc,"$$CM+TY+LX+NC,0,-1$$");
  DocPrint(state.bdoc,"$$TX+RX+BD,\"[X]\"$$");
  DocPrint(state.bdoc,"$$BK,1$$$$TX+LX+BD,\"MENU\"$$$$BK,0$$");

  state.old_task_title=StrNew(Fs->task_title);
  if (Fs->title_src!=TTS_LOCKED_CONST) {
    Fs->title_src=TTS_ED_FILENAME;
    MemCpy(Fs->task_title,doc->filename.name,STR_LEN-1);
  }
  doc_e=DocPrint(state.bdoc,"$$DA-TRM-P+BD+RD+CX+IV,LEN=STR_LEN-1,"
	"A=\"%%s...\",SCX=16$$");
  doc_e->data=&Fs->task_title;
  DocDataFmt(state.bdoc,doc_e);

  if (doc->flags & DOCF_ALLOW_UNDO) {
    DocPrint(state.bdoc,"$$CM+BY+LX+NC,1,1$$");
    doc_e=DocPrint(state.bdoc,"$$DA+BD+RD-TRM,RT=U32,A=\"Undo:%%03d\"$$\n");
    doc_e->data=&doc->undo_cnt;
    DocDataFmt(state.bdoc,doc_e);
  }

  DocPrint(state.bdoc,"$$CM+BY+RX+NC,-31,1$$");
  doc_e=DocPrint(state.bdoc,"$$TX+BD+TC,\"     \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdMoreCB;
  doc_e=DocPrint(state.bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdDollarTypeCB;
  doc_e=DocPrint(state.bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdFilterCB;
  doc_e=DocPrint(state.bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdOverStrikeCB;
  doc_e=DocPrint(state.bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdAutoSaveCB;
  doc_e=DocPrint(state.bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdDollarCB;
  doc_e=DocPrint(state.bdoc,"$$DA+BD+RD-TRM,A=\"Line:%%04d \"$$");
  doc_e->data=&doc->line;
  DocDataFmt(state.bdoc,doc_e);
  doc_e=DocPrint(state.bdoc,"$$DA+BD+RD-TRM,A=\"Col:%%04d\"$$\n");
  doc_e->data=&doc->col;
  DocDataFmt(state.bdoc,doc_e);

  DocRecalc(state.bdoc);
  DocRecalc(doc);
  if (!(dof_flags&DOF_DONT_HOME))
    DocTop(doc);
  Fs->border_doc=state.bdoc;
  if (doc!=state.old_display_doc)
    doc->parent_doc=state.old_display_doc;
  Fs->put_doc=Fs->display_doc=doc;
  if (!(dof_flags&DOF_DONT_TEXT_ATTR))
    Fs->text_attr=DOC_ATTR_DFT_TEXT;
  if (!(dof_flags&DOF_DONT_SHOW)) {
    LBts(&Fs->display_flags,DISPLAYf_SHOW);
    WinZBufUpdate;
  }
  if (dof_flags&DOF_SIZE_MIN)
    doc->flags|=DOCF_SIZE_MIN;

  DocUnlock(doc);
  if (!(dof_flags&DOF_DONT_WINMGR_SYNC)) {
    Refresh(2,TRUE);
    if (doc->flags&DOCF_SIZE_MIN)
      Refresh(2,TRUE);
  }
  res=DOC_VIEW_FUNCTION;

  DocLock(doc);
  if (res) {
    doc_e=doc->head.next;
    while (doc_e!=doc) {
      if (doc_e->type_u8==DOCT_DATA || doc_e->type_u8==DOCT_CHECK_BOX)
	DocDataScan(doc,doc_e);
      doc_e=doc_e->next;
    }
  }
  } catch { DOC_ED_RESTORE; }
  DOC_ED_RESTORE;
  return res;
}
