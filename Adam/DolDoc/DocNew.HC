#include "/Adam/DolDoc/DocEntryAlloc.HC"
#help_index "DolDoc"

#include "/Adam/DolDoc/DocEntryLife.HC"

public U0 DocRst(CDoc *doc,Bool is_old)
{//Del all entries and set doc to dfts.
  Bool unlock;
  CDocEntry *doc_e,*doc_e2;
  CDocUndo *u,*u8;
  CDocSettings *s;
  CDocBin *b,*b1;
  if (!doc && !(doc=DocPut))
    return;
  unlock=DocLock(doc);
  if (is_old) {
    doc_e=doc->head.next;
    while (doc_e!=doc) {
      doc_e2=doc_e->next;
      DocEntryDel(doc,doc_e);
      doc_e=doc_e2;
    }
    u=doc->undo_head.next;
    while (u!=&doc->undo_head) {
      u8=u->next;
      DocUndoDel(doc,u);
      u=u8;
    }
    b=doc->bin_head.next;
    while (b!=&doc->bin_head) {
      b1=b->next;
      QueRem(b);
      Free(b->data);
      Free(b);
      b=b1;
    }
  }
//Check $LK,"DocInsDoc",A="MN:DocInsDoc"$
  doc->flags&=DOCF_BREAK_UNLOCKED;
  doc->head.next=doc->head.last=doc;
  QueInit(&doc->bin_head);
  QueInit(&doc->undo_head);
  doc->undo_head.time_stamp=0;
  doc->undo_cnt=0;
  doc->cur_bin_num=1;
  doc->dollar_buf_ptr=0;
  doc->cmd_U8=CH_SPACE;
  doc->page_line_num=0;
  doc->best_d=I64_MAX;

  s=&doc->settings_head;
  s->left_margin=DOC_DFT;
  s->right_margin=DOC_DFT;
  s->indent=0;
  s->page_len=66;
  s->header=DOC_DFT;
  s->footer=DOC_DFT;
  s->state=DOCSS_NORMAL;
  s->comment_depth=0;
  s->paren_depth=0;
  s->brace_depth=0;
  s->shifted_x=0;
  s->shifted_y=0;
  s->cur_text_attr=s->dft_text_attr=DOC_ATTR_DFT_TEXT;

  doc_e=&doc->head;
  doc_e->type=DOCT_ERROR;
  doc_e->de_flags=0;
  doc_e->x=0;
  doc_e->y=0;
  doc_e->min_col=0;
  doc_e->max_col=0;
  doc_e->page_line_num=doc->page_line_num;
  MemCpy(&doc_e->settings,s,sizeof(CDocSettings));

  DocTop(doc);
  if (unlock)
    DocUnlock(doc);
}

public U0 DocDel(CDoc *doc)
{//Free entire doc and entries.
  if (!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return;
  DocLock(doc);
  doc->doc_signature=0;
  DocRst(doc,TRUE);
  Free(doc->find_replace);
  Free(doc->dollar_buf);
  DocUnlock(doc);
  Free(doc);
}

public I64 DocSize(CDoc *doc)
{//Mem size of doc and all its entries.
  Bool unlock;
  CDocEntry *doc_e;
  CDocUndo *u;
  CDocBin *b;
  I64 res=0;

  if (!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return 0;
  unlock=DocLock(doc);

  doc_e=doc->head.next;
  while (doc_e!=doc) {
    res+=DocEntrySize(doc,doc_e);
    doc_e=doc_e->next;
  }

  u=doc->undo_head.next;
  while (u!=&doc->undo_head) {
    res+=MSize2(u->body);
    res+=MSize2(u);
    u=u->next;
  }

  b=doc->bin_head.next;
  while (b!=&doc->bin_head) {
    res+=MSize2(b->data);
    res+=MSize2(b);
    b=b->next;
  }

  res+=MSize2(doc->find_replace);
  res+=MSize2(doc->dollar_buf);
  res+=MSize2(doc);
  if (unlock)
    DocUnlock(doc);
  return res;
}

#help_index "DolDoc"
public CDoc *DocNew(U8 *filename=NULL,CTask *task=NULL)
{//MAlloc new $LK,"DolDoc",A="FI:::/Doc/DolDocOverview.DD"$. (Begin a new doc.)
  CDoc *doc;
  if (!task) task=Fs;
  doc=CAlloc(sizeof(CDoc),task);
  if (filename)
    StrCpy(doc->filename.name,filename);
  else
    StrCpy(doc->filename.name,blkdev.tmp_filename);
  doc->find_replace=CAlloc(sizeof(CEdFindText),task);
  doc->find_replace->scan_fwd=TRUE;
  doc->find_replace->match_case=TRUE;
  doc->find_replace->pmt=TRUE;
  doc->left_click_link=&EdLeftClickLink;
  doc->dollar_buf_size=84;
  doc->dollar_buf=MAlloc(doc->dollar_buf_size,task);
  doc->max_entries=I64_MAX;
  doc->win_task=task;
  doc->mem_task=task;
  DocRst(doc,FALSE);
  doc->doc_signature=DOC_SIGNATURE_VAL;
  return doc;
}
