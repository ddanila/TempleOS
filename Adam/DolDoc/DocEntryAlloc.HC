#help_index "DolDoc"

Bool IsEditableText(CDocEntry *doc_e)
{
  if (doc_e->type_u8==DOCT_TEXT&&!(doc_e->de_flags&DOCEG_DONT_EDIT))
    return TRUE;
  else
    return FALSE;
}

CDocEntry *DocEntryNewBase(CDoc *doc,I64 type,I64 de_flags=0,
	I64 x=0,I64 y=0,I64 page_line_num=0)
{//See also $LK,"MAllocIdent",A="FF:::/Adam/DolDoc/DocRecalc.HC,MAllocIdent"$ and $MA-X+PU,"CDocEntry",LM="F(\"sizeof(CDocEntry)\");View;"$.
  CDocEntry *res=CAlloc(sizeof(CDocEntryBase),doc->mem_task);
  res->type=type;
  res->de_flags=de_flags|doldoc.dft_de_flags[type.u8[0]];
  res->x=x;
  res->y=y;
  res->page_line_num=page_line_num;
  return res;
}

CDocEntry *DocEntryNewTag(CDoc *doc,CDocEntry *doc_ce,U8 *tag)
{
  I64 l=StrLen(tag);
  CDocEntry *res=DocEntryNewBase(doc,doc_ce->type,doc_ce->de_flags,
	doc_ce->x,doc_ce->y,doc_ce->page_line_num);
  res->de_flags=doc_ce->de_flags; //Override
  res->max_col=l;
  res->tag=MAlloc(l+1,doc->mem_task);
  MemCpy(res->tag,tag,l+1);
  MemCpy(&res->settings,&doc_ce->settings,sizeof(CDocSettings));
  return res;
}

public I64 DocEntrySize(CDoc *,CDocEntry *doc_e)
{//Mem size of entry and all parts.
  I64 res;
  if (!doc_e) return 0;
  res=MSize2(doc_e);
  if (doc_e->de_flags & DOCEF_TAG)
    res+=MSize2(doc_e->tag);
  if (doc_e->de_flags & DOCEF_AUX_STR)
    res+=MSize2(doc_e->aux_str);
  if (doc_e->de_flags & DOCEF_DEFINE)
    res+=MSize2(doc_e->define_str);
  if (doc_e->de_flags & DOCEF_HTML_LINK)
    res+=MSize2(doc_e->html_link);
  if (doc_e->de_flags & DOCEF_LEFT_MACRO)
    res+=MSize2(doc_e->left_macro);
  if (doc_e->de_flags & DOCEF_RIGHT_MACRO)
    res+=MSize2(doc_e->right_macro);
  if (doc_e->de_flags & DOCEF_BIN_PTR_LINK)
    res+=MSize2(doc_e->bin_ptr_link);
  if (doc_e->de_flags & DOCEF_REMALLOC_DATA)
    res+=MSize2(doc_e->data);
  return res;
}

public CDocEntry *DocEntryCopy(CDoc *doc,CDocEntry *doc_e)
{//Make copy of entry and all parts of entry.
  CDocEntry *doc_ne;
  CDocBin *tmpb;
  CTask *task=doc->mem_task;
  doc_ne=MAllocIdent(doc_e,task);
  doc_ne->next=doc_ne;
  doc_ne->last=doc_ne;
  if (doc_e->de_flags & DOCEF_TAG)
    doc_ne->tag=MAllocIdent(doc_e->tag,task);
  if (doc_e->de_flags & DOCEF_AUX_STR)
    doc_ne->aux_str=MAllocIdent(doc_e->aux_str,task);
  if (doc_e->de_flags & DOCEF_DEFINE)
    doc_ne->define_str=MAllocIdent(doc_e->define_str,task);
  if (doc_e->de_flags & DOCEF_HTML_LINK)
    doc_ne->html_link=MAllocIdent(doc_e->html_link,task);
  if (doc_e->de_flags & DOCEF_LEFT_MACRO)
    doc_ne->left_macro=MAllocIdent(doc_e->left_macro,task);
  if (doc_e->de_flags & DOCEF_RIGHT_MACRO)
    doc_ne->right_macro=MAllocIdent(doc_e->right_macro,task);
  if (doc_e->de_flags & DOCEF_BIN_PTR_LINK)
    doc_ne->bin_ptr_link=MAllocIdent(doc_e->bin_ptr_link,task);
  if (doc_e->de_flags & DOCEF_HAS_BIN) {
    tmpb=MAllocIdent(doc_e->bin_data,task);
    tmpb->data=MAllocIdent(doc_e->bin_data->data,task);
    doc_ne->bin_num=doc->cur_bin_num;
    tmpb->num=doc->cur_bin_num++;
    doc_ne->bin_data=tmpb;
    if (doc_e->de_flags&DOCEF_TAG && doc_e->tag && *doc_e->tag)
      tmpb->tag=StrNew(doc_e->tag,task);
    else
      tmpb->tag=NULL;
    QueIns(tmpb,doc->bin_head.last);
  }
  if (doc_e->de_flags & DOCEF_REMALLOC_DATA)
    doc_ne->data=MAllocIdent(doc_e->data,task);
  return doc_ne;
}

