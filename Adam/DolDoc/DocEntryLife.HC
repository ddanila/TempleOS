#help_index "DolDoc"
public U0 DocEntryDel(CDoc *doc,CDocEntry *doc_e)
{//Free entry and all parts of entry.
  if (!doc || doc==doc_e)
    DocReportLiteral(3000,"DocEntryDel");
  else {
    if (doc->cur_entry==doc_e)
      doc->cur_entry=doc_e->next;
    QueRem(doc_e);
    if (doc_e->de_flags & DOCEF_TAG)
      Free(doc_e->tag);
    if (doc_e->de_flags & DOCEF_AUX_STR)
      Free(doc_e->aux_str);
    if (doc_e->de_flags & DOCEF_DEFINE)
      Free(doc_e->define_str);
    if (doc_e->de_flags & DOCEF_HTML_LINK)
      Free(doc_e->html_link);
    if (doc_e->de_flags & DOCEF_LEFT_MACRO)
      Free(doc_e->left_macro);
    if (doc_e->de_flags & DOCEF_RIGHT_MACRO)
      Free(doc_e->right_macro);
    if (doc_e->de_flags & DOCEF_BIN_PTR_LINK)
      Free(doc_e->bin_ptr_link);
    if (doc_e->de_flags & DOCEF_HAS_BIN)
      DocBinDel(doc,doc_e->bin_data);
    if (doc_e->de_flags & DOCEF_REMALLOC_DATA)
      Free(doc_e->data);
    Free(doc_e);
  }
}

U0 DocUndoDel(CDoc *,CDocUndo *u)
{
  Free(u->body);
  Free(u);
}

U0 DocUndoCntSet(CDoc *doc)
{
  Bool unlock=DocLock(doc);
  CDocUndo *u=doc->undo_head.next;
  doc->undo_cnt=0;
  while (u!=&doc->undo_head) {
    doc->undo_cnt++;
    u=u->next;
  }
  if (unlock)
    DocUnlock(doc);
}

U0 DocRemSoftNewLines(CDoc *doc=NULL,CDocEntry *doc_e=NULL)
{
  CDocEntry *doc_e2,*saved_ll=doc_e;
  Bool unlock;
  if (!doc && !(doc=DocPut))
    return;
  unlock=DocLock(doc);
  if (!doc_e) doc_e=doc->head.next;
  while (doc_e!=doc) {
    doc_e2=doc_e->next;
    if (doc_e->type_u8==DOCT_SOFT_NEW_LINE) {
      if (doc->cur_entry==doc_e) {
	doc->cur_entry=doc_e2;
	doc->cur_col=doc->cur_entry->min_col;
      }
      DocEntryDel(doc,doc_e);
    } else if (saved_ll && doc_e->type_u8==DOCT_NEW_LINE)
      break;
    doc_e=doc_e2;
  }
  if (unlock)
    DocUnlock(doc);
}

public U0 DocInsEntry(CDoc *doc,CDocEntry *doc_e)
{//Insert entry into doc, updating its vals.
  U8 *dst;
  Bool unlock=DocLock(doc);
  CDocEntry *doc_ce=doc->cur_entry,*doc_ne;

  doc_e->x=doc_ce->x;
  doc_e->y=doc_ce->y;
  doc_e->page_line_num=doc_ce->page_line_num;
  MemCpy(&doc_e->settings,&doc_ce->settings,sizeof(CDocSettings));
  if (doc->cur_col>0 &&
	doc_ce->type_u8==DOCT_TEXT &&
	!(doc_ce->de_flags&(DOCEF_TAG_CB|DOCEF_DEFINE|DOCEF_AUX_STR|
	DOCEF_HTML_LINK|DOCEF_BIN_PTR_LINK)) &&
	doc->cur_col<doc_ce->max_col) {
    dst=doc_ce->tag+doc->cur_col;
    doc_ne=DocEntryNewTag(doc,doc_ce,dst);
    *dst=0;
    doc_ne->type=DOCT_TEXT|doc_ce->type&0xFFFFFF00;
    doc_ce->max_col=doc->cur_col;
    QueIns(doc_ne,doc_ce);
    doc->cur_col=0;
    doc_ce=doc_ne;
  }
  if (doc_ce->type_u8==DOCT_TEXT && doc->cur_col>=doc_ce->max_col) {
    QueIns(doc_e,doc_ce);
    doc->cur_entry=doc_e->next;
  } else {
    QueIns(doc_e,doc_ce->last);
    doc->cur_entry=doc_ce;
  }
  doc->cur_col=doc->cur_entry->min_col;
  DocRemSoftNewLines(doc,doc->cur_entry);
  if (unlock)
    DocUnlock(doc);
}

