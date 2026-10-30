#ifndef I386_PUBLIC_DOCUMENT_INCLUDED
#define I386_PUBLIC_DOCUMENT_INCLUDED
#include "/Kernel/DocGlobals.HH"
#include "/Kernel/RawTypes.HH"
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
public _extern _ED_FIND_NEXT U0 EdFindNext(CDoc *doc);
public _extern _ED_SEL_ALL U0 EdSelAll(CDoc *doc,Bool sel);
public _extern _ED_FIND_PAIRED Bool EdFindPaired(CDoc *doc,U8 plus,U8 minus,Bool fwd,Bool abort_on_dbl_colon=FALSE);
public _extern _ED_GO_TO_FUN Bool EdGoToFun(CDoc *doc,Bool fwd,Bool abort_on_dbl_colon);
public _extern _ED_SEL_FUN U0 EdSelFun(CDoc *doc,Bool abort_on_dbl_colon=FALSE);
public _extern _DOC_COLLAPSE U0 DocCollapse(Bool collapse=TRUE,CDoc *doc=NULL);
public _extern _DOC_ENTRY_TOGGLE U0 DocEntryToggle(CDoc *doc);
public _extern _DOC_FLAGS_TOGGLE U0 DocFlagsToggle(CDoc *doc,I64 tog_flags);
public _extern _DOC_UNDO_DEL U0 DocUndoDel(CDoc *doc,CDocUndo *undo);
public _extern _DOC_CAPTURE_UNDO Bool DocCaptureUndo(CDoc *doc,Bool force=FALSE);
public _extern _DOC_UNDO_RESTORE U0 DocUndoRestore(CDoc *doc);
public _extern _DOC_UNDO_COUNT U0 DocUndoCntSet(CDoc *doc);
public _extern _DOC_REM_SOFT U0 DocRemSoftNewLines(CDoc *doc=0,CDocEntry *entry=0);
public _extern _DOC_INS_ENTRY U0 DocInsEntry(CDoc *doc,CDocEntry *entry);
public _extern _DOC_NEW CDoc *DocNew(U8 *filename=0,CTask *task=0);
public _extern _DOC_RST U0 DocRst(CDoc *doc,Bool is_old);
public _extern _DOC_DEL U0 DocDel(CDoc *doc);
public _extern _DOC_SIZE I64 DocSize(CDoc *doc);
public _extern _DOC_PUT_KEY U0 DocPutKey(CDoc *doc,I64 ch=0,I64 sc=0);
public _extern _DOC_SCAN_LINE U8 *DocScanLine(CDoc *doc,CDocEntry *doc_e,
  I64 *cur_col=NULL,CDocEntry **_do_e_end=NULL);
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
public _extern _DOC_PRINT_PARTIAL U0 DocPrintPartial(CDoc *doc=NULL,U8 *fmt,...);
public _extern _DOC_GET_KEY I64 DocGetKey(I64 *sc=NULL);
public _extern _DOC_RECALC Bool DocRecalc(CDoc *doc,I64 recalc_flags=RECALCt_NORMAL);
public _extern _DOC_UPDATE_TASK_DOCS U0 DocUpdateTaskDocs(CTask *task);
public _extern _DOC_ENTRY_RUN I64 DocEntryRun(CDoc *doc,CDocEntry *entry,
  Bool exited,I64 *has_action=NULL);
public _extern _DOC_MENU I64 DocMenu(CDoc *doc,I64 flags=0);
#include "/Adam/DolDoc/TermRightMenuTypes.HH"
public _extern _POP_UP_TERM_RIGHT I64 PopUpTermRight(U8 *header);
public _extern _POP_UP_MENU I64 PopUpMenu(CDoc *doc,I64 flags=0);
public _extern _POP_UP_1 I64 PopUp1(U8 *b1,I64 n1,U8 *header=NULL,U8 *footer=NULL);
public _extern _POP_UP_2 I64 PopUp2(U8 *b1,I64 n1,U8 *b2,I64 n2,U8 *header=NULL,U8 *footer=NULL);
public _extern _POP_UP_OK Bool PopUpOk(U8 *header=NULL,U8 *footer=NULL);
public _extern _POP_UP_NO_YES Bool PopUpNoYes(U8 *header=NULL,U8 *footer=NULL);
public _extern _POP_UP_CANCEL_OK Bool PopUpCancelOk(U8 *header=NULL,U8 *footer=NULL);
public _extern _POP_UP_PICK_LST I64 PopUpPickLst(U8 *list);
public _extern _ED_CUR_U8 I64 EdCurU8(CDoc *doc);
public _extern _ED_CURSOR_LEFT U0 EdCursorLeft(CDoc *doc,I64 sc=I64_MIN);
public _extern _ED_CURSOR_RIGHT U0 EdCursorRight(CDoc *doc,I64 sc=I64_MIN);
public _extern _ED_LINE_UP U0 EdLineUp(CDoc *doc,I64 sc=I64_MIN);
public _extern _ED_LINE_DOWN U0 EdLineDown(CDoc *doc,I64 sc=I64_MIN);
public _extern _ED_CHAR_DEL U0 EdCharDel(CDoc *doc);
public _extern _ED_CHAR_INS U0 EdCharIns(I64 ch,I64 sc,CDoc *doc);
public _extern _ED_LINE_DEL U0 EdLineDel(CDoc *doc);
public _extern _DOC_TOP U0 DocTop(CDoc *doc=NULL);
public _extern _DOC_CENTER U0 DocCenter(CDoc *doc=NULL,I64 recalc_flags=RECALCt_NORMAL);
public _extern _DOC_BOTTOM U0 DocBottom(CDoc *doc=NULL);
public _extern _DOC_INS_DOC U0 DocInsDoc(CDoc *doc=NULL,CDoc *source);
public _extern _CLIP_DEL U0 ClipDel();
public _extern _CLIP_COPY U0 ClipCopy(CDoc *doc);
public _extern _CLIP_CUT U0 ClipCut(CDoc *doc);
public _extern _CLIP_PASTE U0 ClipPaste(CDoc *doc);
public _extern _DOC_CUT U0 DocCut(CDoc *doc,CDocEntry *start,CDocEntry *end);
public _extern _DOC_COPY CDoc *DocCopy(CDoc *doc,CDocEntry *start,CDocEntry *end);
public _extern _SYS_CLIP_DOC CDoc *sys_clip_doc;
public _extern _DOC_LOAD U0 DocLoad(CDoc *doc,U8 *source,I64 bytes);
public _extern _DOC_2_PLAIN_TEXT U8 *Doc2PlainText(CDoc *doc,CDocEntry *entry);
public _extern _DOC_FORM Bool DocForm(U8 *data,U8 *class_name=lastclass,I64 flags=0,U8 *header=0,U8 *footer=0);
public _extern _POP_UP_FORM Bool PopUpForm(U8 *data,U8 *class_name=lastclass,I64 flags=DOF_SIZE_MIN,U8 *header=0,U8 *footer=0);
public _extern _DOC_GO_TO_LINE Bool DocGoToLine(CDoc *doc,I64 line_num);
public _extern _ED_FIND_REPLACE I64 EdFindReplace(CDoc *doc);
public _extern _ED_GO_TO_LINE U0 EdGoToLine(CDoc *doc);
public _extern _ED_REPLACE I64 EdReplace(CDoc *doc,U8 *find,U8 *replace,
  Bool sel=TRUE,Bool match_case=TRUE,Bool whole_labels=FALSE);
#include "/Adam/DolDoc/DocFindPromptTypes.HH"
#include "/Adam/DolDoc/DocReplaceMenuTypes.HH"
public _extern _DOC_CLEAR U0 DocClear(CDoc *doc=NULL,Bool clear_holds=FALSE);
public _extern _DOC_SPRITE CDocEntry *DocSprite(CDoc *doc=NULL,U8 *elems,U8 *fmt=NULL);
public _extern _DOC_GR U0 DocGR(CDoc *doc=NULL,U8 *filename);
public _extern _DOC_DUMP U0 DocDump(CDoc *doc,I64 uS_delay=0);
public _extern _DOC_TYPE Bool DocType(CDoc *doc=NULL,U8 *filename,I64 trailing_new_lines=1);
public _extern _TYPE Bool Type(U8 *filename,I64 trailing_new_lines=1);
#endif
