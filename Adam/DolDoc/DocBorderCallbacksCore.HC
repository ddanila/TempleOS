U8 *EdOverStrikeCB(CDoc *,CDocEntry *doc_e,CTask *mem_task)
{
  CDoc *doc=doc_e->user_data;
  U8 *st=MAlloc(8,mem_task);
  if (doc->flags & DOCF_OVERSTRIKE)
    *st='O';
  else
    *st='Ä';
  st[1]=0;
  return st;
}

U8 *EdAutoSaveCB(CDoc *,CDocEntry *doc_e,CTask *mem_task)
{
  CDoc *doc=doc_e->user_data;
  U8 *st=MAlloc(8,mem_task);
  if (doc->flags & DOCF_AUTO_SAVE)
    *st='S';
  else
    *st='Ä';
  st[1]=0;
  return st;
}

U8 *EdFilterCB(CDoc *,CDocEntry *doc_e,CTask *mem_task)
{
  CDoc *doc=doc_e->user_data;
  U8 *st=MAlloc(8,mem_task);
  if (doc->find_replace->filter_lines)
    *st='F';
  else
    *st='Ä';
  st[1]=0;
  return st;
}

U8 *EdDollarCB(CDoc *,CDocEntry *doc_e,CTask *mem_task)
{
  CDoc *doc=doc_e->user_data;
  U8 *st=MAlloc(8,mem_task);
  if (doc->flags & DOCF_IN_DOLLAR)
    *st='$$';
  else
    *st='Ä';
  st[1]=0;
  return st;
}

U8 *EdMoreCB(CDoc *,CDocEntry *doc_e,CTask *mem_task)
{
  CDoc *doc=doc_e->user_data;
  U8 *st=MAlloc(8,mem_task);
  if (doc->flags&DOCF_MORE)
    StrCpy(st,"MoreÄ");
  else
    StrCpy(st,"ÄÄÄÄÄ");
  return st;
}

U8 *EdDollarTypeCB(CDoc *,CDocEntry *doc_e,CTask *mem_task)
{
  CDoc *doc=doc_e->user_data;
  U8 *src=DefineSub(doc->cur_entry->type_u8,"ST_DOC_CMDS"),
	*st=CAlloc(8,mem_task);
  if (doc->cur_entry==doc)
    src="EOF";
  else if (!src)
    src="ERR";
  StrPrint(st,"%-3ts",src);
  return st;
}

