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
public _extern _DOC_REPORT_LITERAL U0 DocReportLiteral(I64 mS,U8 *message);
public _extern _DOC_BIN_FIND_NUM CDocBin *DocBinFindNum(CDoc *doc,I64 num);
public _extern _DOC_BIN_FIND_TAG CDocBin *DocBinFindTag(CDoc *doc,U8 *tag);
public _extern _DOC_BINS_VALIDATE U0 DocBinsValidate(CDoc *doc);
public _extern _DOC_BIN_DEL U0 DocBinDel(CDoc *doc,CDocBin *bin);
public _extern _DOC_ENTRY_DEL U0 DocEntryDel(CDoc *doc,CDocEntry *entry);
public _extern _DOC_UNDO_DEL U0 DocUndoDel(CDoc *doc,CDocUndo *undo);
public _extern _DOC_UNDO_COUNT U0 DocUndoCntSet(CDoc *doc);
public _extern _DOC_REM_SOFT U0 DocRemSoftNewLines(CDoc *doc=0,CDocEntry *entry=0);
public _extern _DOC_INS_ENTRY U0 DocInsEntry(CDoc *doc,CDocEntry *entry);
public _extern _DOC_NEW CDoc *DocNew(U8 *filename=0,CTask *task=0);
public _extern _DOC_RST U0 DocRst(CDoc *doc,Bool is_old);
public _extern _DOC_DEL U0 DocDel(CDoc *doc);
public _extern _DOC_SIZE I64 DocSize(CDoc *doc);
public _extern _DOC_PUT_KEY U0 DocPutKey(CDoc *doc,I64 ch=0,I64 sc=0);
public _extern _DOC_SAVE U8 *DocSave(CDoc *doc,I64 *size=0);
public _extern _DOC_WRITE Bool DocWrite(CDoc *doc,Bool prompt=FALSE);
public _extern _DOC_READ CDoc *DocRead(U8 *name=0,I64 flags=0);
public _extern _DOC_ED Bool DocEd(CDoc *doc,I64 flags=0);
#endif
