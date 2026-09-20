#ifndef I386_PUBLIC_DOCUMENT_INCLUDED
#define I386_PUBLIC_DOCUMENT_INCLUDED
#include "/Kernel/DocGlobals.HH"
#help_index "DolDoc"
public _extern _DOC_LOCK Bool DocLock(CDoc *doc);
public _extern _DOC_UNLOCK Bool DocUnlock(CDoc *doc);
public _extern _DOC_PUT CDoc *DocPut(CTask *task=0);
public _extern _DOC_DISPLAY CDoc *DocDisplay(CTask *task=0);
public _extern _DOC_BORDER CDoc *DocBorder(CTask *task=0);
public extern CDolDocGlbls doldoc;
public _extern _DOC_EDITABLE Bool IsEditableText(CDocEntry *doc_e);
public _extern _DOC_ENTRY_BASE CDocEntry *DocEntryNewBase(CDoc *doc,I64 type,I64 de_flags=0,I64 x=0,I64 y=0,I64 page_line_num=0);
public _extern _DOC_ENTRY_TAG CDocEntry *DocEntryNewTag(CDoc *doc,CDocEntry *doc_ce,U8 *tag);
public _extern _DOC_ENTRY_SIZE I64 DocEntrySize(CDoc *doc,CDocEntry *doc_e);
public _extern _DOC_ENTRY_COPY CDocEntry *DocEntryCopy(CDoc *doc,CDocEntry *doc_e);
public _extern _DOC_FORM_FWD U0 DocFormFwd(CDoc *doc,Bool giveup=FALSE);
public _extern _DOC_FORM_BWD U0 DocFormBwd(CDoc *doc,Bool giveup=FALSE);
public _extern _DOC_DEFAULTS_INIT U0 DocDefaultsInit(CDolDocGlbls *state);
public _extern _DOC_INIT U0 DocInit();
public _extern _DOC_DICTIONARY_NEW CHashTable *DocDictionaryNew();
public _extern _DOC_DICTIONARY_DEL U0 DocDictionaryDel(CHashTable *table);
public _extern _DOC_GLOBALS_INIT U0 DocGlobalsInit();
public _extern _DOC_START U0 ConsoleDocumentStart();
#endif
