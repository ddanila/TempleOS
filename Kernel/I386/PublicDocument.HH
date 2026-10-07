#ifndef I386_PUBLIC_DOCUMENT_INCLUDED
#define I386_PUBLIC_DOCUMENT_INCLUDED
#include "/Kernel/DocGlobals.HH"
#include "/Adam/DolDoc/EdLinkTypes.HH"
#help_index "DolDoc"
public _extern _DOC_LINK_FILE U8 *DocLinkFile(U8 *link_st,CTask *mem_task=NULL);
public _extern _ED_LINK_CVT I64 EdLinkCvt(U8 *link_st,
  U8 **_filename=NULL,U8 **_needle_str=NULL,I64 *_num=NULL,I64 edf_dof_flags=0);
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
public _extern _ED Bool Ed(U8 *filename,I64 flags=0);
public _extern _DOC_ALLOCATION_CHECK I64 DocAllocationCheck();
public _extern _DOC_EXE Bool DocExe(CDoc *doc,I64 flags=0);
public _extern _EXE_DOC I64 ExeDoc(CDoc *doc,I64 ccf_flags=0);
public _extern _HELP Bool Help(U8 *name=0);
public _extern _DOC_DOLLAR CDocEntry *PrsDollarCmd(CDoc *doc,U8 *source);
public _extern _DOC_DATA_FMT U0 DocDataFmt(CDoc *doc,CDocEntry *entry,I64 value=DOCM_CANCEL);
public _extern _DOC_DATA_SCAN U0 DocDataScan(CDoc *doc,CDocEntry *entry);

public _extern _DOC_PUT_S CDocEntry *DocPutS(CDoc *doc,U8 *source);
public _extern _DOC_PRINT CDocEntry *DocPrint(CDoc *doc=NULL,U8 *fmt,...);

public _extern _DOC_BORDER_NEW CDoc *DocBorderNew(CDoc *pdoc);
public _extern _DOC_ENTRY_LINK U8 *DocEntryLink(CDoc *doc,CDocEntry *doc_e);
public _extern _ED_OVERSTRIKE_CB U8 *EdOverStrikeCB(CDoc *doc,CDocEntry *entry,CTask *mem_task);
public _extern _ED_AUTO_SAVE_CB U8 *EdAutoSaveCB(CDoc *doc,CDocEntry *entry,CTask *mem_task);
public _extern _ED_FILTER_CB U8 *EdFilterCB(CDoc *doc,CDocEntry *entry,CTask *mem_task);
public _extern _ED_DOLLAR_CB U8 *EdDollarCB(CDoc *doc,CDocEntry *entry,CTask *mem_task);
public _extern _ED_MORE_CB U8 *EdMoreCB(CDoc *doc,CDocEntry *entry,CTask *mem_task);
public _extern _ED_DOLLAR_TYPE_CB U8 *EdDollarTypeCB(CDoc *doc,CDocEntry *entry,CTask *mem_task);
#endif
