//Retained task-owned VGA consoles and native command input.
#include "/Kernel/Types.HH"
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/MathConstants.HH"
#include "/Kernel/DirEntryTypes.HH"
#include "/Kernel/BlkDev/DriveTypes.HH"
#include "/Kernel/BlkDev/CFileTypes.HH"
#define TRUE 1
#define FALSE 0
#define ON 1
#define OFF 0
#include "/Kernel/I386/ConsoleRuntime.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/TextVga.HH"
#include "/Kernel/I386/Vga.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Frame.HH"
import CI386Frame *I386TaskFrameParent(CI386Task *task,CI386Frame *frame);
import U8 *I386TaskFrameReturn(CI386Task *task,CI386Frame *frame);
#include "/Kernel/I386/ExceptRuntime.HH"
#include "/Kernel/I386/TaskBreak.HH"
#include "/Kernel/I386/DocLock.HH"
#include "/Kernel/I386/DocAccess.HH"
#include "/Kernel/I386/KernelSymbols.HH"
#include "/Kernel/FontStd.HC"
import Bool I386SchedYield(CI386Scheduler *scheduler);
import U0 HashAdd(CHash *entry,CHashTable *table);
import U0 KernelLog(U8 *text);
import U0 KernelHex(U64 value);
import U0 KernelStop();
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import Bool I386SchedWake(CI386Scheduler *scheduler,CI386Task *task);
import Bool I386SchedBlock(CI386Scheduler *scheduler);
import Bool I386KbcQueueGet(CI386KbcQueue *queue,U8 *data,U8 *status);
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
CI386ConsoleConfig *console_config;
CI386EditorContext native_editor_context;
CI386Text console_default_text;
U8 *console_default_planes;
extern CI386Text *NativeTerminalText();
extern U8 **NativeTerminalPlanes();
extern Bool NativeTerminalVisible();
extern U0 NativeTerminalAdoptRoot();
extern U0 NativeTerminalConsoleHeading();
extern U0 NativeUserTaskCont();
extern U0 NativeSrvTaskCont();
extern U0 NativeSrvCmdLine(I64 dummy=0);
extern I64 NativePopUp(U8 *buf,CTask *parent=0,CTask **_pu_task=0);
extern I64 NativePopUpPrint(U8 *fmt,...);
extern I64 DocEntryRun(CDoc *doc,CDocEntry *entry,Bool exited,I64 *has_action=0);
extern I64 DocMenu(CDoc *doc,I64 flags=0);
extern I64 PopUpMenu(CDoc *doc,I64 flags=0);
extern I64 PopUpTermRight(U8 *header);
extern I64 PopUpPickLst(U8 *list);
extern I64 EdCurU8(CDoc *doc);
extern U0 EdCursorLeft(CDoc *doc,I64 sc=I64_MIN);
extern U0 EdCursorRight(CDoc *doc,I64 sc=I64_MIN);
extern U0 EdLineUp(CDoc *doc,I64 sc=I64_MIN);
extern U0 EdLineDown(CDoc *doc,I64 sc=I64_MIN);
extern U0 EdCharDel(CDoc *doc);
extern U0 EdCharIns(I64 ch,I64 sc,CDoc *doc);
extern U0 EdLineDel(CDoc *doc);
extern U0 DocInsDoc(CDoc *doc,CDoc *source);
extern U0 DocCollapse(Bool collapse=TRUE,CDoc *doc=0);
extern U0 DocEntryToggle(CDoc *doc);
extern U0 DocFlagsToggle(CDoc *doc,I64 tog_flags);
extern U8 *StrFind(U8 *needle,U8 *haystack_str,I64 flags=0);
extern U0 EdFindNext(CDoc *doc);
extern U0 EdSelAll(CDoc *doc,Bool sel);
extern Bool EdFindPaired(CDoc *doc,U8 plus,U8 minus,Bool fwd,Bool abort_on_dbl_colon=FALSE);
extern Bool EdGoToFun(CDoc *doc,Bool fwd,Bool abort_on_dbl_colon);
extern U0 EdSelFun(CDoc *doc,Bool abort_on_dbl_colon=FALSE);
extern Bool DocForm(U8*data,U8*name=lastclass,I64 flags=0,U8*header=0,U8*footer=0);
extern Bool PopUpForm(U8*data,U8*name=lastclass,I64 flags=DOF_SIZE_MIN,U8*header=0,U8*footer=0);
extern Bool DocGoToLine(CDoc *doc,I64 line_num);
extern I64 EdFindReplace(CDoc *doc);
extern U0 EdGoToLine(CDoc *doc);
extern I64 FSize(CFile *f);
extern I64 Clus2Blk(CDrv *dv,I64 c);
extern I64 EdReplace(CDoc*doc,U8*find,U8*replace,Bool sel=TRUE,Bool match_case=TRUE,Bool whole_labels=FALSE);
extern I64 NativeTimeStamp();
extern U0 NativeTimeStampInit();
extern Bool DocCaptureUndo(CDoc *doc,Bool force=FALSE);
extern U0 DocUndoRestore(CDoc *doc);
extern U0 DocLoad(CDoc *doc,U8 *source,I64 bytes);
extern U8 *Doc2PlainText(CDoc *doc,CDocEntry *entry);
extern U0 ClipDel();
extern U0 ClipCopy(CDoc *doc);
extern U0 ClipCut(CDoc *doc);
extern U0 ClipPaste(CDoc *doc);
extern U0 DocCut(CDoc *doc,CDocEntry *start,CDocEntry *end);
extern CDoc *DocCopy(CDoc *doc,CDocEntry *start,CDocEntry *end);
CDoc *sys_clip_doc;
I64 (*native_servant_flush)(CTask *task);
extern U0 NativeUserCmdLine(I64 dummy=0);
extern CTask *NativeWinFocus(CTask *task=0);
extern I64 *NativeTerminalLossSeen();
extern U0 NativeTerminalDiscardKeyboard();
extern Bool NativeTerminalFocusKey(CI386KeyEvent *event);
extern U0 NativeUserHotkey(U8 *data);
extern CDoc *NativeTerminalDocument();
extern U0 NativeTerminalTranscriptStart();
extern class CNativeLegacyViewScope;
extern CNativeLegacyViewScope *NativeLegacyViewOpen(Bool restore_docs=FALSE);
extern U0 NativeLegacyViewClose(CNativeLegacyViewScope *scope);
extern Bool NativeTerminalProjects(CDoc *doc,U8 *text=0,I64 sc=0);
extern U0 NativeTerminalDiagnosticRecord(U8 *text);
extern U0 NativeTerminalDocumentRendered(CTask *task);
extern U0 NativeConsoleWrite(U8 *text);
extern U0 NativeConsolePut(I64 ch);
extern CDocEntry *NativeConsolePrompt();
extern I64 NativeTerminalInputKey(CI386KeyEvent *event);
extern CTask *NativeUser(U8 *fmt=0,...);
extern U0 NativeXTalk(CTask *task,U8 *fmt,...);
extern U0 NativeTaskWait(CTask *task=0,Bool cmd_line_pmt=FALSE);
extern U0 PostMsgWait(CTask *task,I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
class CI386UserProviders {
  CTask *(*spawn)(U0 (*entry)(U8 *data),U8 *data,U8 *name,I64 cpu,
    CTask *parent,I64 stack_size,I64 flags);
  Bool (*kill)(CTask *task,Bool wait,Bool just_break);
  Bool (*suspend)(CTask *task,Bool state);
};
CI386UserProviders native_user_providers;

#define console_text (*NativeTerminalText())
#define console_planes (*NativeTerminalPlanes())
extern U0 ConsolePresent();
extern U0 Refresh(I64 cnt=1,Bool force=FALSE);
extern Bool NativeKeyboardStart();
extern I64 NativeReadKey(CI386KeyboardReader *reader,CI386KeyEvent *event,Bool wait=TRUE);
extern I64 NativeJobSource(U8 *text);
CTask *sys_focus_task,*sys_winmgr_task,*sys_task_being_scrn_updated;
CTask *native_window_worker;
I64 native_window_fault_task;
U0 (*native_window_sleep)(I64 ms);
extern Bool NativeWindowOwnsView();
extern U0 NativeWinMgrEnsure();
extern Bool NativeWinMgrStart();
extern U0 WinMax(CTask *task=0);
extern Bool WinBorder(Bool val=0,CTask *task=0);
extern I64 NativeWinToTop(CTask *task=0,Bool update_z_buf=TRUE);
extern Bool DocExe(CDoc *doc,I64 flags=0);
extern I64 ExeDoc(CDoc *doc,I64 ccf_flags=0);
public Bool MouseGet(I64 *x,I64 *y,I64 *buttons=0,I64 *packets=0)
{
  CI386MouseState *mouse;
  U32 flags;
  if(!x || !y || !console_config || !(mouse=console_config->mouse) ||
      !mouse->installed) return FALSE;
  flags=I386IrqSave; *x=mouse->x; *y=mouse->y;
  if(buttons) *buttons=mouse->buttons;
  if(packets) *packets=mouse->packets;
  I386IrqRestore(flags); return TRUE;
}
I64 console_diagnostic_line;
U8 console_diagnostic_filename[256];
#include "/Kernel/BitFieldExtractCore.HC"
U0 BFieldOrU32(U8 *bit_field,I64 bit,U32 pattern)
{//The original reads and writes an unaligned eight-byte word.
  U64 *word=bit_field+(bit(U64)>>3);
  *word|=pattern(U64)<<(bit&7);
}
#include "/Kernel/I386/DocumentRuntime.HC"
#include "/Kernel/I386/InstallTree.HC"
#include "/Kernel/I386/BuildModuleDispatch.HC"
#include "/Kernel/I386/BuildBootImage.HC"
#include "/Kernel/I386/SoundRuntime.HC"
#include "/Kernel/I386/TextBase.HC"
#include "/Kernel/I386/Window.HC"
#include "/Kernel/I386/RasterRuntime.HC"
#include "/Kernel/IsRawCore.HC"
#include "/Kernel/I386/BusyRuntime.HC"
extern Bool NativeIsDebugMode();
extern U0 NativeBreakpointInstall();
extern Bool ConsoleCpuCapture(CI386ExceptionFrame *frame);
extern U0 ConsoleCpuDebug(CI386ExceptionFrame *frame);
#include "/Kernel/I386/FormatterRuntime.HC"
#define MUSIC_JIFFIES NativeJiffies()
#define MUSIC_NATIVE_SINGLE_CPU 1
#include "/Adam/MusicStateCore.HC"
#include "/Adam/MusicResetCore.HC"
#include "/Kernel/WindowManagerTypes.HH"
#include "/Kernel/MaxCore.HC"
#include "/Adam/WinMgrRefreshCore.HC"
CWinMgrGlbls winmgr;
I64 native_presentation_epoch=0;
U0 NativePresentationCommit()
{//Physical uploads are distinct from completed manager iterations.
  native_presentation_epoch++;
}
F64 NativeWinRefreshFPS()
{
  U32 flags=I386IrqSave;
  F64 fps=winmgr.fps;
  I386IrqRestore(flags);
  return fps;
}
extern U8 *NativeCaller(I64 num=1);
#define Caller NativeCaller
extern U0 PutChars(U64 chars);
extern U0 PutS(U8 *s);
#include "/Kernel/PrintCore.HC"
CDoc *(*fp_doc_put)(CTask *task);
#include "/Kernel/GetOutOfDollarCore.HC"
#include "/Kernel/DiagnosticText.HH"
#include "/Kernel/DiagnosticPrintCore.HC"
#include "/Kernel/DefineLoadCore.HC"
#include "/Kernel/DefinePrintCore.HC"
#include "/Adam/God/BibleTypes.HH"
#include "/Kernel/I386/ScannerRuntime.HC"
#include "/Kernel/I386/RawOutputRuntime.HC"
#include "/Adam/God/BibleInitCore.HC"
#include "/Kernel/I386/SourceLinkRuntime.HC"
extern I64 ExePrint(U8 *fmt,...);
U8 *NativeEdLinkTmpFilename()
{
  return console_config->files->tmp_filename();
}
#define ED_LINK_TMP_FILENAME NativeEdLinkTmpFilename()
#include "/Adam/DolDoc/EdLinkCvtCore.HC"
#include "/Adam/DolDoc/DocLinkFileCore.HC"
#include "/Kernel/I386/DocDollarRuntime.HC"
#include "/Adam/DolDoc/DocBorderCallbacksCore.HC"
#include "/Adam/DolDoc/DocBorderNewCore.HC"
#include "/Adam/DolDoc/DocEntryLinkCore.HC"
#include "/Kernel/I386/MenuRuntime.HC"
#include "/Kernel/I386/MacroRuntime.HC"
Bool (*native_raw_bit_equ)(U8 *bit_field,I64 bit,Bool val);
Bool NativeRawBitEqu(U8 *bit_field,I64 bit,Bool val)
{ return (*native_raw_bit_equ)(bit_field,bit,val); }
#define LBEqu NativeRawBitEqu
#include "/Kernel/VGAFlushCore.HC"
#include "/Kernel/RawCore.HC"
extern U0 Yield();
#include "/Adam/DolDoc/DocPrintPartialCore.HC"
extern Bool DocRecalc(CDoc *doc,I64 recalc_flags=RECALCt_NORMAL);
#include "/Kernel/EndianCore.HC"
#include "/Kernel/BlkDev/BlockDevTypes.HH"
U8 NativeDriveAlias(U8 alias)
{
  return console_config->files->drive_alias(alias);
}
#define DRIVE_BOOT_LET NativeDriveAlias(':')
#define DRIVE_HOME_LET NativeDriveAlias('~')
#include "/Kernel/BlkDev/DriveLetterCore.HC"
CDrv *NativeDriveLookup(U8 letter)
{ return console_config->files->drive_lookup(letter); }
#define DRIVE_LOOKUP NativeDriveLookup(drv_let)
#include "/Kernel/BlkDev/DriveLookupCore.HC"
#define DRIVE_MAP_SLOT console_config->drive_map[drv_let-'A']
#include "/Kernel/BlkDev/DriveMapCore.HC"
#include "/Kernel/BlkDev/BlockDevLookupCore.HC"
#include "/Kernel/BlkDev/DriveWritableCore.HC"
#include "/Kernel/BlkDev/BlockDevLockCore.HC"
#include "/Kernel/BlkDev/DriveLockCore.HC"
//Use the original cache implementation against the same kernel-owned globals.
//Cache initialization and block I/O wiring are separate from console startup.
extern U8 *ACAlloc(I64 size);
U8 *AMAlloc(I64 size)
{ return MAlloc(size,I386TaskSelf->owner->root); }
CBlkDevGlbls *DskCacheGlobals()
{ return console_config->block_globals; }
#define I386_DSK_CACHE_GLOBALS 1
#include "/Kernel/BlkDev/DskCache.HC"
#include "/Kernel/BlkDev/FreeListTypes.HH"
#include "/Kernel/BlkDev/RedSeaFreeFreeListCore.HC"
#include "/Kernel/BlkDev/DriveDeleteCore.HC"
#define DRIVE_DEVICE_DELETE_RECORD &console_config->drive_records[i]
#include "/Kernel/BlkDev/DriveDeviceDeleteCore.HC"
#define DRIVE_RELEASE_RECORD &console_config->drive_records[i]
#define BLOCK_DEV_RELEASE_RECORD &console_config->block_records[i]
#include "/Kernel/BlkDev/DriveReleaseCore.HC"
#include "/Kernel/BlkDev/BlockDevReleaseCore.HC"
extern U0 NativeRenderOwnerRetire(CI386Task *task);
U0 NativeStorageOwnerRetire(CI386Task *task)
{
  if(task!=I386TaskSelf)throw('Task',TRUE);
  DrvsRelease;BlkDevsRelease;
  NativeRenderOwnerRetire(task);
}
import U32 char_bmp_filename[16];
#include "/Kernel/BlkDev/FileNameCheckCore.HC"
#include "/Kernel/SilentCore.HC"
#include "/Kernel/BlkDev/DriveClassCore.HC"
#define DRIVE_SLOT_RECORD &console_config->drive_records[i]
#define DRIVE_SLOT_SIGNATURE console_config->drive_records[i].dv_signature
#include "/Kernel/BlkDev/DriveSlotCore.HC"
#include "/Kernel/BlkDev/BlockSize.HH"
#define BLOCK_DEV_SLOT_RECORD &console_config->block_records[i]
#include "/Kernel/BlkDev/BlockDevSlotCore.HC"
#include "/Kernel/BlkDev/DriveTextAttrCore.HC"
#include "/Kernel/FileMaskTypes.HH"
#include "/Kernel/WildMatchCore.HC"
#include "/Kernel/BlkDev/FilesFindMatchCore.HC"
#include "/Kernel/I386/RenderScope.HC"
#include "/Kernel/I386/DerivedScope.HC"
#include "/Kernel/I386/TaskUpdateScope.HC"
#include "/Adam/DolDoc/DocRecalcLib.HC"
#define BLINK_JIFFIES NativeJiffies()
#include "/Kernel/BlinkCore.HC"
#define DOC_RECALC_JIFFIES NativeJiffies()
#define DOC_RECALC_FPS NativeWinRefreshFPS()
import U32 char_bmp_alpha_numeric[16];
CTask **native_highlight_root;
#define DOC_HIGHLIGHT_ROOT (*native_highlight_root)
#include "/Kernel/HashTypeNumCore.HC"
#include "/Adam/DolDoc/DocHighlightCore.HC"
#include "/Adam/Gr/Gr.HH"
#include "/Adam/Gr/SpriteRecordsCore.HC"
#include "/Adam/Gr/DC2SpriteCore.HC"
#include "/Adam/Gr/DocSpriteCore.HC"
#include "/Kernel/BlkDev/FileNames.HC"
#include "/Kernel/BlkDev/ExtDftCore.HC"
#define FileRead NativePublicFileRead
#include "/Adam/Gr/GRReadCore.HC"
#include "/Adam/Gr/DocGRCore.HC"
#include "/Adam/DolDoc/DocDumpCore.HC"
#include "/Adam/DolDoc/DocTypeCore.HC"
#include "/Adam/Gr/SpriteDataValidateCore.HC"
#define GRAPHICS_DEFAULT_DC NULL
#define GRAPHICS_RESOLVE_DEFAULT_DC if (!dc) dc=gr.dc;
#include "/Adam/Gr/GrMath.HC"
#include "/Adam/Gr/GrPixelCore.HC"
#include "/Adam/Gr/GrPenTablesCore.HC"
#include "/Adam/Gr/GrBlotCore.HC"
//Mutually dependent point and bitmap cores share the actual implementation below.
extern I64 GrBlot3(CDC *dc,I64 x1,I64 y1,I64 z1,CDC *img);
#include "/Adam/Gr/GrPointClipCore.HC"
#include "/Adam/Gr/GrBlot3Core.HC"
#include "/Adam/Gr/GrRasterSpanCore.HC"
#include "/Adam/Gr/GrFillCircleCore.HC"
#include "/Adam/Gr/GrPlot3Core.HC"
#include "/Adam/Gr/GrLineCore.HC"
#include "/Adam/Gr/GrLine3Core.HC"
#include "/Adam/Gr/GrTextCore.HC"
#include "/Adam/Gr/GrText3Core.HC"
#include "/Adam/Gr/GrTextCompositesCore.HC"
#include "/Adam/Gr/GrFloodRayCore.HC"
#include "/Adam/Gr/GrFloodFillCore.HC"
#include "/Adam/Gr/GrFloodFill3Core.HC"
#include "/Adam/Gr/GrArrowCore.HC"
#include "/Adam/Gr/GrFillTriangleCore.HC"
#include "/Adam/Gr/GrFillPolyCore.HC"
#include "/Adam/Gr/GrRect3Core.HC"
#include "/Adam/PolarCore.HC"
#include "/Adam/Gr/GrCurves3Core.HC"
#include "/Adam/Gr/GrSplines3Core.HC"
#include "/Adam/Gr/GrMeshCore.HC"
#include "/Adam/Gr/SpriteRenderCore.HC"
//Song strings use the existing scheduler-root-owned provider defined below.
extern U8 *NativeAStrNew(U8 *text);
#define AStrNew NativeAStrNew
#include "/Kernel/I386/DocRecalcScope.HC"
#include "/Kernel/I386/DocDelete.HC"
#include "/Adam/DolDoc/DocRecalcCore.HC"
#include "/Kernel/StrIMatchCore.HC"


#include "/Kernel/JobResScanCore.HC"
#include "/Kernel/KeyDevTypes.HH"
CKeyDevGlbls keydev;
extern U8 *Char2KeyName(I64 ch,Bool include_ctrl=TRUE);
extern U0 KeyDescSet(U8 *fmt,...);
extern U0 PutKey(I64 ch=0,I64 sc=0);
extern U0 PutChars(U64 chars);
extern U0 PutS(U8 *s);
extern CKeyDevEntry *KeyDevAdd(Bool (*key)(I64 ch,I64 sc),Bool (*text)(U8 *s),I64 priority,Bool key_descs=FALSE);
extern U0 KeyDevRem(CKeyDevEntry *entry);
extern Bool ScanKey(I64 *ch=0,I64 *sc=0,Bool echo=FALSE);
extern I64 GetKey(I64 *sc=0,Bool echo=FALSE,Bool raw_cursor=FALSE);
extern I64 DocGetKey(I64 *sc=NULL);
extern U8 *DocGetStr2(I64 flags=0);
extern U8 *GetStr(U8 *msg=NULL,U8 *dft=NULL,I64 flags=0);
U8 *(*fp_getstr2)(I64 flags=0);
extern U0 NativeKeyDevStart();
I64 (*native_public_scan_msg)(I64 *a,I64 *b,I64 mask,CTask *task);
extern U0 NativePrint(U8 *fmt,...);
extern U0 NativePutS(U8 *text);
extern U0 NativePutChars(U64 chars);
U0 (*native_output_msg)(I64 msg_code,I64 arg1,I64 arg2,I64 flags);
U0 (*native_post_msg)(CTask *task,I64 msg_code,I64 arg1,I64 arg2,I64 flags);
U0 (*native_action_exit)();
#include "/Kernel/I386/InputFilterRuntime.HC"
#include "/Kernel/I386/StreamRuntime.HC"
U0 Yield()
{//Use the managed public scheduler provider resolved during console init.
  (*native_input_yield)();
}
CJob *native_sys_macro_head;
#include "/Adam/DolDoc/DocMacroPlaybackCore.HC"
U0 PlaySysMacro(I64 n=1)
{
  PlaySysMacroCore(n,sys_focus_task,native_sys_macro_head);
}
U8 *console_title="TempleOS i386\nHolyC console\n\n";
CI386KeyboardState console_hotkeys;
CI386Task *console_break_task;
CI386KernelSymbol console_doc_exports[347],*console_doc_export_cursor;
U32 console_doc_data_exports[11]={0x00040000,0x00080002,0x00004060,0x00400000,0x00000000,0x00001000,0x80000000,0x20000008,0x00000020,0x01118000,0x00000000};
extern U8 *NativeCaller(I64 num=1);
extern U0 NativeDebug(U8 *msg=NULL,I64 msg_num=0);
extern Bool NativeDebugMode(Bool value);
extern Bool NativeIsDebugMode();
extern U0 ConsoleDebugException(U8 *context,CI386Task *task,CCmpCtrl *cc,I64 exception);
#include "/Kernel/I386/PublicDebugTypes.HH"
extern CBpt *BptFind(U8 *addr,CTask *task=0,Bool rem=FALSE);
extern Bool BptS(U8 *addr,CTask *task=0,Bool live=TRUE);
extern Bool BptR(U8 *addr,CTask *task=0,Bool live=TRUE,Bool rem=TRUE);
extern Bool B(U8 *addr,CTask *task=0,Bool live=TRUE);
extern I64 B2(CTask *task=0,Bool live=TRUE);
extern I64 *TaskRegAddr(CTask *task,I64 reg_num);
extern U0 NativeDebugGoClear(U8 *ip=U32_MAX,CTask *task=NULL);
extern U0 NativeDebugStep(U8 *ip=U32_MAX,CTask *task=NULL);
extern U0 NativeDebugGo(U8 *ip=U32_MAX,CTask *task=NULL);
U32 console_version=I386_CONSOLE_VERSION;
U8 **native_owner_retire_slot;
extern Bool NativeWindowPresent(Bool blink=FALSE);
extern U0 DrawCtrls(CTask *task);
extern U0 GrUpdateTaskWin(CTask *task);
extern Bool NativeGraphicsStart();
extern Bool NativeGraphicsStorageReserve();
extern Bool NativeGraphicsPresent(U0 (*draw)(CDC *dc)=NULL,Bool blink=FALSE);
extern Bool NativeTextBasePresent(Bool blink=FALSE,I64 pan_x=0,I64 pan_y=0,Bool hide_col=FALSE,Bool hide_row=FALSE);
extern U0 NativeTextBaseRestore();
extern Bool ConsoleDisplay();
extern U0 ConsoleKeys(I64 unused);
extern U0 ConsoleSubmit(U8 *line);
extern Bool ConsoleSource(U8 *source,U8 *filename,I64 flags=0);
extern I64 ExePutS(U8 *buf,U8 *filename=NULL,I64 flags=0,CLexHashTableContext *htc=NULL);
extern I64 ExePrint(U8 *fmt,...);
extern Bool ConsoleRootHeaders();
U0 ConsoleDocExportSet(U8 *address)
{//Initialization supplies bindings in order; share conversion and advancement.
  console_doc_export_cursor->val=(address+0)(U64);
  console_doc_export_cursor++;
}

Bool ConsoleInit(CI386ConsoleConfig *config)
{
  U8 *display_planes;
  U8 *export_names="_DOC_LOCK\0_DOC_UNLOCK\0_DOC_PUT\0_DOC_DISPLAY\0_DOC_BORDER\0_DOC_EDITABLE\0_DOC_ENTRY_BASE\0_DOC_ENTRY_TAG\0_DOC_ENTRY_SIZE\0_DOC_ENTRY_COPY\0_DOC_FORM_FWD\0_DOC_FORM_BWD\0_DOC_DEFAULTS_INIT\0_DOC_INIT\0_DOC_DICTIONARY_NEW\0_DOC_DICTIONARY_DEL\0_DOC_GLOBALS_INIT\0_DOC_START\0doldoc\0_DOC_REPORT_LITERAL\0_DOC_BIN_FIND_NUM\0_DOC_BIN_FIND_TAG\0_DOC_BINS_VALIDATE\0_DOC_BIN_DEL\0_DOC_ENTRY_DEL\0_DOC_UNDO_DEL\0_DOC_UNDO_COUNT\0_DOC_REM_SOFT\0_DOC_INS_ENTRY\0_TEXT_CHAR\0_TEXT_LEN_STR\0_TEXT_LEN_ATTR_STR\0_TEXT_LEN_ATTR\0i386_text_base\0_TEXT_BASE_PRESENT\0_TEXT_BASE_RESTORE\0_LIST_SUB\0_LIST_MATCH\0_DEFINE\0_DEFINE_SUB\0_DEFINE_COUNT\0_DEFINE_MATCH\0_YEAR_START_DATE\0_STRUCT_TO_DATE\0_DAY_OF_WEEK\0_DATE_TO_STRUCT\0_FIRST_DAY_MONTH\0_LAST_DAY_MONTH\0_FIRST_DAY_YEAR\0_LAST_DAY_YEAR\0_BCD_TO_BIN\0local_time_offset\0_MAT4X4MULXYZ\0_DCTRANSFORM\0_MAT4X4IDENTEQU\0_MAT4X4IDENTNEW\0_MAT4X4NORMSQR65536\0_DCMAT4X4SET\0_DCLIGHTING\0_DCFILL\0_DCCLEAR\0_DCRST\0_DCEXTENTSINIT\0_DCALIAS\0_DCNEW\0_DCDEL\0_DCSIZE\0_DCDEPTHBUFRST\0_DCDEPTHBUFALLOC\0gr\0gr_palette_std\0_GRAPHICS_START\0_GRAPHICS_PRESENT\0_TEXT_BORDER\0_TEXT_RECT\0_WIN_SCROLL_NULL\0_WIN_SCROLL_RESTORE\0_WIN_DERIVED_VALS_UPDATE\0text\0_TASK_VALIDATE\0_TASK_DERIVED_VALS_UPDATE\0_WIN_HORZ\0_WIN_VERT\0_CTRL_FIND_UNIQUE\0_CTRLS_UPDATE\0_CTRL_INSIDE\0_WIN_Z_BUF_UPDATE\0_WIN_INSIDE\0_DOC_NEW\0_DOC_RST\0_DOC_DEL\0_DOC_SIZE\0_DOC_PUT_KEY\0_DOC_SAVE\0_DOC_WRITE\0_DOC_READ\0_DOC_ED\0_DOC_ALLOCATION_CHECK\0_DOC_EXE\0_DIR_MK\0_ED\0_DIR\0_ED_DIR\0_FILE_DEL\0_FILE_RENAME\0_DIR_DEL\0_FILE_MOVE\0_HELP\0_SND\0_SND_RST\0_MOUSE_GET\0_I386_INSTALL_TREE\0_I386_INSTALL_BOOT\0_I386_BUILD_MODULE\0_I386_BUILD_BOOT_IMAGE\0_I386_INSTALL_BOOT_IMAGE\0_EXE_DOC\0_I386_JOB_SOURCE\0_SYS_FOCUS_TASK\0_DBG\0_DEBUG_GO\0_DBG_MODE\0_IS_DBG_MODE\0_USER_CMD_LINE\0_USER_TASK_CONT\0_WIN_FOCUS\0_IS_RAW\0_STR_PRINT_JOIN\0_STR_PRINT\0_CAT_PRINT\0_MSTR_PRINT\0_USER\0_XTALK\0_TASK_WAIT\0_FILE_WRITE\0_FILE_READ\0_FILE_FIND\0_CD\0_DEBUG_STEP\0_TASK_REG_ADDR\0_BPT_FIND\0_BPT_SET\0_BPT_REMOVE\0_BPT_TOGGLE\0_BPT_CLEAR\0_DEBUG_GO_CLEAR\0_CALLER\0_SYS_MACRO_2_STR\0_SYS_MACRO_STRIP_KEY\0_PRINT\0_PUT_S\0_PUT_CHARS\0_TASK_TEXT\0_IN_STR\0_XTALK_STR_WAIT\0_PLAY_SYS_MACRO\0_STR_SCAN\0_STR_TO_I64\0_STR_TO_F64\0_STR_TO_DATE\0_DOC_DOLLAR\0_DOC_DATA_FMT\0_DOC_DATA_SCAN\0_DOC_PUT_S\0_DOC_PRINT\0_IN\0_JOB_RES_SCAN\0_JOB_DEL\0_TASK_EXE\0_SRV_TASK_CONT\0_SRV_CMD_LINE\0_WIN_TO_TOP\0_SYS_WINMGR_TASK\0_DOC_BORDER_NEW\0_ED_OVERSTRIKE_CB\0_ED_AUTO_SAVE_CB\0_ED_FILTER_CB\0_ED_DOLLAR_CB\0_ED_MORE_CB\0_ED_DOLLAR_TYPE_CB\0_MENU_NEW\0_MENU_FILE\0_MENU_ENTRY_FIND\0_MENU_SUB_ENTRY_FIND\0_MENU_DEL\0_GR_RECT\0_RAND_U16\0_DIST_SQR_I64\0_WIN_SCROLLS_INIT\0_RAW\0_VGA_FLUSH\0_DOC_ENTRY_LINK\0_FILE_NAME_ABS\0_SRC_LINE_NUM\0_SRC_FILE_NAME\0_SRC_ED_LINK\0_EXE_PUTS\0_EXE_PRINT\0_DEFINE_LOAD\0_DEFINE_PRINT\0_BIBLE_INIT\0_ED_LINK_CVT\0_DOC_LINK_FILE\0_DRV_CHECK\0_DRV_TO_LET\0_LET_TO_LET\0_LET_TO_BLOCK_DEV_TYPE\0_DRV_TEXT_ATTR_GET\0_STREAM_PRINT\0_STREAM_DIR\0_NOW\0_DOC_SCAN_LINE\0_PUT_KEY\0_KEY_DEV_ADD\0_KEY_DEV_REM\0_SCAN_KEY\0_GET_KEY\0_DOC_PRINT_PARTIAL\0_DOC_GET_KEY\0_DOC_RECALC\0_DOC_UPDATE_TASK_DOCS\0_DRAW_CTRLS\0_GR_UPDATE_TASK_WIN\0_SYS_TASK_BEING_SCRN_UPDATED\0_WINDOW_PRESENT\0_WINMGR_START\0_REFRESH\0_WINMGR_STATE\0_POP_UP\0_POP_UP_PRINT\0_WIN_MAX\0_DOC_ENTRY_RUN\0_DOC_MENU\0_POP_UP_MENU\0_POP_UP_PICK_LST\0_ED_CUR_U8\0_ED_CURSOR_LEFT\0_ED_CURSOR_RIGHT\0_ED_LINE_UP\0_ED_LINE_DOWN\0_ED_CHAR_DEL\0_ED_CHAR_INS\0_ED_LINE_DEL\0_DOC_TOP\0_DOC_CENTER\0_DOC_BOTTOM\0_DOC_INS_DOC\0_CLIP_DEL\0_CLIP_COPY\0_CLIP_CUT\0_CLIP_PASTE\0_DOC_CUT\0_DOC_COPY\0_SYS_CLIP_DOC\0_DOC_LOAD\0_DOC_2_PLAIN_TEXT\0_GET_TSC\0_DOC_CAPTURE_UNDO\0_DOC_UNDO_RESTORE\0_CHAR_2_KEY_NAME\0_KEY_DESC_SET\0_KEYDEV\0_DOC_COLLAPSE\0_DOC_ENTRY_TOGGLE\0_DOC_FLAGS_TOGGLE\0_STR_FIND\0_ED_FIND_NEXT\0_ED_SEL_ALL\0_ED_FIND_PAIRED\0_ED_GO_TO_FUN\0_ED_SEL_FUN\0_DOC_FORM\0_POP_UP_FORM\0_DOC_SPLIT_TAG\0_DOC_GO_TO_LINE\0_ED_REPLACE\0_STR_OCC\0_STR_FIRST_OCC\0_STR_LAST_OCC\0_STR_FIRST_REM\0_STR_LAST_REM\0_STR_UTIL\0_MSTR_UTIL\0_LET_TO_DRV\0_BLOCK_DEV_CHECK\0_LET_TO_BLOCK_DEV\0_DRV_IS_WRITABLE\0_FILE_NAME_CHK\0_SILENT\0_IS_SILENT\0_BLOCK_DEV_LOCK\0_BLOCK_DEV_UNLOCK\0_DRV_LOCK\0_DRV_UNLOCK\0_DRVS_RELEASE\0_BLOCK_DEVS_RELEASE\0_GET_OUT_OF_DOLLAR\0_PRINT_ERR\0_PRINT_WARN\0_RAW_PUT_CHAR\0RedSeaFreeFreeLst\0_DRV_DEL\0DrvBlkDevDel\0NativeDriveRecords\0NativeBlockRecords\0_BLOCK_DEV_NEXT_FREE_SLOT\0_DRV_MAKE_FREE_SLOT\0_DRV_NEXT_FREE_LET\0NativeDriveMap\0_DRV_MAP\0_GET_STR\0_DOC_GET_STR2\0_FP_GETSTR2\0_DOC_CLEAR\0_DC_2_SPRITE\0_DOC_SPRITE\0_DC_LOAD\0_EXPAND_BUF\0_EXT_DFT\0_GR_READ\0_DOC_GR\0_PORT_NOP\0_HPET\0_BUSY\0_DOC_DUMP\0_DOC_TYPE\0_TYPE\0_POP_UP_TERM_RIGHT\0_WIN_BORDER\0_POST_MSG_WAIT\0_ED_FIND_REPLACE\0_ED_GO_TO_LINE\0_FSIZE\0_CLUS_TO_BLOCK\0I386DskCacheInit\0I386DskCacheAdd\0I386RCache\0I386DskCacheInvalidate2\0I386DskCacheGlobals\0_BIT_FIELD_EXT_U32\0_BIT_FIELD_OR_U32\0_ARC_COMPRESS_BUF\0_ARC_CTRL_DEL\0_ARC_CTRL_NEW\0_ARC_EXPAND_BUF\0_ARC_FINISH_COMPRESSION\0_COMPRESS_BUF\0";
  CI386Task *task=I386TaskSelf;
  I64 i;
  CI386KernelSymbol *provider;
  if(!task || !task->hash_table || console_config || !config || !config->heap || !config->compiler ||
      config->compiler->version!=I386_COMPILER_SERVICES_VERSION ||
      config->compiler->bytes!=sizeof(CI386CompilerServices) || !config->compiler->input || !config->compiler->break_poll ||
      !config->pit_ticks || !config->jiffies || !config->input_poll || !config->doc_diagnostic_load || !config->editor_load || config->pit_divisor<2 || config->pit_divisor>65536 || !config->files || !config->drive_records || !config->drive_map || !config->block_records || !config->block_globals || config->drive_map!=config->block_globals->let_to_drv || config->block_records!=config->block_globals->blkdevs || !config->includes || !config->types || !config->reader || !config->input) return FALSE;
  provider=HashFind("_ADAM_TASK",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=3 || !provider->val) return FALSE;
  native_highlight_root=provider->val;
  if(!*native_highlight_root) return FALSE;
  provider=HashFind("_SPAWN",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_user_providers.spawn=provider->val;
  provider=HashFind("_KILL",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_user_providers.kill=provider->val;
  provider=HashFind("I386TaskOwnerRetireHook",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=3 || !provider->val)return FALSE;
  native_owner_retire_slot=provider->val;
  if(*native_owner_retire_slot && *native_owner_retire_slot!=&NativeStorageOwnerRetire)
    return FALSE;
  provider=HashFind("_SUSPEND",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_user_providers.suspend=provider->val;
  provider=HashFind("_LBEQU",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_raw_bit_equ=provider->val;
  provider=HashFind("_SYS_SEMAS",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=3 || !provider->val) return FALSE;
  sys_semas=provider->val;
  provider=HashFind("_SYS_MACRO_HEAD",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=3 || !provider->val) return FALSE;
  native_sys_macro_head=provider->val;
  provider=HashFind("_MSG",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_output_msg=provider->val;
  provider=HashFind("_POST_MSG",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_post_msg=provider->val;
  provider=HashFind("_EXIT",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_action_exit=provider->val;
  provider=HashFind("_JOBS_HNDLR",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_input_jobs=provider->val;
  provider=HashFind("_YIELD",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_input_yield=provider->val;
  provider=HashFind("_SLEEP",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val)return FALSE;
  native_window_sleep=provider->val;
  provider=HashFind("_FLUSH_MSGS",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_servant_flush=provider->val;
  provider=HashFind("I386CAllocExact",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_graphics_body_calloc=provider->val;
  provider=HashFind("_SCAN_MSG",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_public_scan_msg=provider->val;
  if(!I386KeyboardReadInit(config->reader,config->input)) return FALSE;
  I386KeyboardReset(&console_hotkeys);
  console_doc_export_cursor=console_doc_exports;
  ConsoleDocExportSet(&I386DocLock);
  ConsoleDocExportSet(&I386DocUnlock);
  ConsoleDocExportSet(&DocPut);
  ConsoleDocExportSet(&DocDisplay);
  ConsoleDocExportSet(&DocBorder);
  ConsoleDocExportSet(&IsEditableText);
  ConsoleDocExportSet(&DocEntryNewBase);
  ConsoleDocExportSet(&DocEntryNewTag);
  ConsoleDocExportSet(&DocEntrySize);
  ConsoleDocExportSet(&DocEntryCopy);
  ConsoleDocExportSet(&DocFormFwd);
  ConsoleDocExportSet(&DocFormBwd);
  ConsoleDocExportSet(&DocDefaultsInit);
  ConsoleDocExportSet(&DocInit);
  ConsoleDocExportSet(&DocDictionaryNew);
  ConsoleDocExportSet(&DocDictionaryDel);
  ConsoleDocExportSet(&DocGlobalsInit);
  ConsoleDocExportSet(&ConsoleDocumentStart);
  ConsoleDocExportSet(&doldoc);
  ConsoleDocExportSet(&DocReportLiteral);
  ConsoleDocExportSet(&DocBinFindNum);
  ConsoleDocExportSet(&DocBinFindTag);
  ConsoleDocExportSet(&DocBinsValidate);
  ConsoleDocExportSet(&DocBinDel);
  ConsoleDocExportSet(&DocEntryDel);
  ConsoleDocExportSet(&DocUndoDel);
  ConsoleDocExportSet(&DocUndoCntSet);
  ConsoleDocExportSet(&DocRemSoftNewLines);
  ConsoleDocExportSet(&DocInsEntry);
  NativeTextBaseInit;
  NativeRawInit;
  ConsoleDocExportSet(&TextChar);
  ConsoleDocExportSet(&TextLenStr);
  ConsoleDocExportSet(&TextLenAttrStr);
  ConsoleDocExportSet(&TextLenAttr);
  ConsoleDocExportSet(&i386_text_base);
  ConsoleDocExportSet(&NativeTextBasePresent);
  ConsoleDocExportSet(&NativeTextBaseRestore);
  ConsoleDocExportSet(&LstSub);
  ConsoleDocExportSet(&LstMatch);
  ConsoleDocExportSet(&Define);
  ConsoleDocExportSet(&DefineSub);
  ConsoleDocExportSet(&DefineCnt);
  ConsoleDocExportSet(&DefineMatch);
  ConsoleDocExportSet(&YearStartDate);
  ConsoleDocExportSet(&Struct2Date);
  ConsoleDocExportSet(&DayOfWeek);
  ConsoleDocExportSet(&Date2Struct);
  ConsoleDocExportSet(&FirstDayOfMon);
  ConsoleDocExportSet(&LastDayOfMon);
  ConsoleDocExportSet(&FirstDayOfYear);
  ConsoleDocExportSet(&LastDayOfYear);
  ConsoleDocExportSet(&Bcd2Bin);
  ConsoleDocExportSet(&local_time_offset);
  ConsoleDocExportSet(&Mat4x4MulXYZ);
  ConsoleDocExportSet(&DCTransform);
  ConsoleDocExportSet(&Mat4x4IdentEqu);
  ConsoleDocExportSet(&Mat4x4IdentNew);
  ConsoleDocExportSet(&Mat4x4NormSqr65536);
  ConsoleDocExportSet(&DCMat4x4Set);
  ConsoleDocExportSet(&DCLighting);
  ConsoleDocExportSet(&DCFill);
  ConsoleDocExportSet(&DCClear);
  ConsoleDocExportSet(&DCRst);
  ConsoleDocExportSet(&DCExtentsInit);
  ConsoleDocExportSet(&DCAlias);
  ConsoleDocExportSet(&DCNew);
  ConsoleDocExportSet(&DCDel);
  ConsoleDocExportSet(&DCSize);
  ConsoleDocExportSet(&DCDepthBufRst);
  ConsoleDocExportSet(&DCDepthBufAlloc);
  ConsoleDocExportSet(&gr);
  ConsoleDocExportSet(&gr_palette_std);
  ConsoleDocExportSet(&NativeGraphicsStart);
  ConsoleDocExportSet(&NativeGraphicsPresent);
  ConsoleDocExportSet(&TextBorder);
  ConsoleDocExportSet(&TextRect);
  ConsoleDocExportSet(&WinScrollNull);
  ConsoleDocExportSet(&WinScrollRestore);
  ConsoleDocExportSet(&WinDerivedValsUpdate);
  ConsoleDocExportSet(&text);
  ConsoleDocExportSet(&TaskValidate);
  ConsoleDocExportSet(&TaskDerivedValsUpdate);
  ConsoleDocExportSet(&WinHorz);
  ConsoleDocExportSet(&WinVert);
  ConsoleDocExportSet(&CtrlFindUnique);
  ConsoleDocExportSet(&CtrlsUpdate);
  ConsoleDocExportSet(&CtrlInside);
  ConsoleDocExportSet(&WinZBufUpdate);
  ConsoleDocExportSet(&WinInside);
  ConsoleDocExportSet(&DocNew);
  ConsoleDocExportSet(&DocRst);
  ConsoleDocExportSet(&DocDel);
  ConsoleDocExportSet(&DocSize);
  ConsoleDocExportSet(&DocPutKey);
  ConsoleDocExportSet(&DocSave);
  ConsoleDocExportSet(&DocWrite);
  ConsoleDocExportSet(&DocRead);
  ConsoleDocExportSet(&DocEd);
  ConsoleDocExportSet(&DocAllocationCheck);
  ConsoleDocExportSet(&DocExe);
  ConsoleDocExportSet(&DirMk);
  ConsoleDocExportSet(&Ed);
  ConsoleDocExportSet(&Dir);
  ConsoleDocExportSet(&EdDir);
  ConsoleDocExportSet(&FileDel);
  ConsoleDocExportSet(&FileRename);
  ConsoleDocExportSet(&DirDel);
  ConsoleDocExportSet(&FileMove);
  ConsoleDocExportSet(&Help);
  ConsoleDocExportSet(&Snd);
  ConsoleDocExportSet(&SndRst);
  ConsoleDocExportSet(&MouseGet);
  ConsoleDocExportSet(&I386InstallTree);
  ConsoleDocExportSet(&I386InstallBoot);
  ConsoleDocExportSet(&I386BuildModule);
  ConsoleDocExportSet(&I386BuildBootImage);
  ConsoleDocExportSet(&I386InstallBootImage);
  ConsoleDocExportSet(&ExeDoc);
  ConsoleDocExportSet(&NativeJobSource);
  ConsoleDocExportSet(&sys_focus_task);
  ConsoleDocExportSet(&NativeDebug);
  ConsoleDocExportSet(&NativeDebugGo);
  ConsoleDocExportSet(&NativeDebugMode);
  ConsoleDocExportSet(&NativeIsDebugMode);
  ConsoleDocExportSet(&NativeUserCmdLine);
  ConsoleDocExportSet(&NativeUserTaskCont);
  ConsoleDocExportSet(&NativeWinFocus);
  ConsoleDocExportSet(&IsRaw);
  ConsoleDocExportSet(&StrPrintJoin);
  ConsoleDocExportSet(&StrPrint);
  ConsoleDocExportSet(&CatPrint);
  ConsoleDocExportSet(&MStrPrint);
  ConsoleDocExportSet(&NativeUser);
  ConsoleDocExportSet(&NativeXTalk);
  ConsoleDocExportSet(&NativeTaskWait);
  ConsoleDocExportSet(&FileWrite);
  ConsoleDocExportSet(&NativePublicFileRead);
  ConsoleDocExportSet(&FileFind);
  ConsoleDocExportSet(&Cd);
  ConsoleDocExportSet(&NativeDebugStep);
  ConsoleDocExportSet(&TaskRegAddr);
  ConsoleDocExportSet(&BptFind);
  ConsoleDocExportSet(&BptS);
  ConsoleDocExportSet(&BptR);
  ConsoleDocExportSet(&B);
  ConsoleDocExportSet(&B2);
  ConsoleDocExportSet(&NativeDebugGoClear);
  ConsoleDocExportSet(&NativeCaller);
  ConsoleDocExportSet(&SysMacro2Str);
  ConsoleDocExportSet(&SysMacroStripKey);
  ConsoleDocExportSet(&NativePrint);
  ConsoleDocExportSet(&NativePutS);
  ConsoleDocExportSet(&NativePutChars);
  ConsoleDocExportSet(&NativeTaskText);
  ConsoleDocExportSet(&InStr);
  ConsoleDocExportSet(&XTalkStrWait);
  ConsoleDocExportSet(&PlaySysMacro);
  ConsoleDocExportSet(&StrScan);
  ConsoleDocExportSet(&Str2I64);
  ConsoleDocExportSet(&Str2F64);
  ConsoleDocExportSet(&Str2Date);
  ConsoleDocExportSet(&PrsDollarCmd);
  ConsoleDocExportSet(&DocDataFmt);
  ConsoleDocExportSet(&DocDataScan);
  ConsoleDocExportSet(&DocPutS);
  ConsoleDocExportSet(&DocPrint);
  ConsoleDocExportSet(&In);
  ConsoleDocExportSet(&JobResScan);
  ConsoleDocExportSet(&JobDel);
  ConsoleDocExportSet(&NativeTaskExe);
  ConsoleDocExportSet(&NativeSrvTaskCont);
  ConsoleDocExportSet(&NativeSrvCmdLine);
  sys_winmgr_task=task;
  ConsoleDocExportSet(&NativeWinToTop);
  ConsoleDocExportSet(&sys_winmgr_task);
  ConsoleDocExportSet(&DocBorderNew);
  ConsoleDocExportSet(&EdOverStrikeCB);
  ConsoleDocExportSet(&EdAutoSaveCB);
  ConsoleDocExportSet(&EdFilterCB);
  ConsoleDocExportSet(&EdDollarCB);
  ConsoleDocExportSet(&EdMoreCB);
  ConsoleDocExportSet(&EdDollarTypeCB);
  ConsoleDocExportSet(&NativeMenuNew);
  ConsoleDocExportSet(&MenuFile);
  ConsoleDocExportSet(&MenuEntryFind);
  ConsoleDocExportSet(&MenuSubEntryFind);
  ConsoleDocExportSet(&MenuDel);
  ConsoleDocExportSet(&GrRect);
  ConsoleDocExportSet(&RandU16);
  ConsoleDocExportSet(&DistSqrI64);
  ConsoleDocExportSet(&WinScrollsInit);
  ConsoleDocExportSet(&Raw);
  ConsoleDocExportSet(&VGAFlush);
  ConsoleDocExportSet(&DocEntryLink);
  ConsoleDocExportSet(&FileNameAbs);
  ConsoleDocExportSet(&SrcLineNum);
  ConsoleDocExportSet(&SrcFileName);
  ConsoleDocExportSet(&SrcEdLink);
  ConsoleDocExportSet(&ExePutS);
  ConsoleDocExportSet(&ExePrint);
  ConsoleDocExportSet(&DefineLoad);
  ConsoleDocExportSet(&DefinePrint);
  ConsoleDocExportSet(&BibleInit);
  ConsoleDocExportSet(&EdLinkCvt);
  ConsoleDocExportSet(&DocLinkFile);
  ConsoleDocExportSet(&DrvChk);
  ConsoleDocExportSet(&Drv2Let);
  ConsoleDocExportSet(&Let2Let);
  ConsoleDocExportSet(&Let2BlkDevType);
  ConsoleDocExportSet(&DrvTextAttrGet);
  ConsoleDocExportSet(&NativeStreamPrint);
  ConsoleDocExportSet(&NativeStreamDir);
  ConsoleDocExportSet(&NativeNow);
  ConsoleDocExportSet(&DocScanLine);
  ConsoleDocExportSet(&PutKey);
  ConsoleDocExportSet(&KeyDevAdd);
  ConsoleDocExportSet(&KeyDevRem);
  ConsoleDocExportSet(&ScanKey);
  ConsoleDocExportSet(&GetKey);
  ConsoleDocExportSet(&DocPrintPartial);
  ConsoleDocExportSet(&DocGetKey);
  ConsoleDocExportSet(&DocRecalc);
  ConsoleDocExportSet(&DocUpdateTaskDocs);
  ConsoleDocExportSet(&DrawCtrls);
  ConsoleDocExportSet(&GrUpdateTaskWin);
  ConsoleDocExportSet(&sys_task_being_scrn_updated);
  ConsoleDocExportSet(&NativeWindowPresent);
  ConsoleDocExportSet(&NativeWinMgrStart);
  ConsoleDocExportSet(&Refresh);
  ConsoleDocExportSet(&winmgr);
  ConsoleDocExportSet(&NativePopUp);
  ConsoleDocExportSet(&NativePopUpPrint);
  ConsoleDocExportSet(&WinMax);
  ConsoleDocExportSet(&DocEntryRun);
  ConsoleDocExportSet(&DocMenu);
  ConsoleDocExportSet(&PopUpMenu);
  ConsoleDocExportSet(&PopUpPickLst);
  ConsoleDocExportSet(&EdCurU8);
  ConsoleDocExportSet(&EdCursorLeft);
  ConsoleDocExportSet(&EdCursorRight);
  ConsoleDocExportSet(&EdLineUp);
  ConsoleDocExportSet(&EdLineDown);
  ConsoleDocExportSet(&EdCharDel);
  ConsoleDocExportSet(&EdCharIns);
  ConsoleDocExportSet(&EdLineDel);
  ConsoleDocExportSet(&DocTop);
  ConsoleDocExportSet(&DocCenter);
  ConsoleDocExportSet(&DocBottom);
  ConsoleDocExportSet(&DocInsDoc);
  ConsoleDocExportSet(&ClipDel);
  ConsoleDocExportSet(&ClipCopy);
  ConsoleDocExportSet(&ClipCut);
  ConsoleDocExportSet(&ClipPaste);
  ConsoleDocExportSet(&DocCut);
  ConsoleDocExportSet(&DocCopy);
  ConsoleDocExportSet(&sys_clip_doc);
  ConsoleDocExportSet(&DocLoad);
  ConsoleDocExportSet(&Doc2PlainText);
  ConsoleDocExportSet(&NativeTimeStamp);
  ConsoleDocExportSet(&DocCaptureUndo);
  ConsoleDocExportSet(&DocUndoRestore);
  ConsoleDocExportSet(&Char2KeyName);
  ConsoleDocExportSet(&KeyDescSet);
  ConsoleDocExportSet(&keydev);
  ConsoleDocExportSet(&DocCollapse);
  ConsoleDocExportSet(&DocEntryToggle);
  ConsoleDocExportSet(&DocFlagsToggle);
  ConsoleDocExportSet(&StrFind);
  ConsoleDocExportSet(&EdFindNext);
  ConsoleDocExportSet(&EdSelAll);
  ConsoleDocExportSet(&EdFindPaired);
  ConsoleDocExportSet(&EdGoToFun);
  ConsoleDocExportSet(&EdSelFun);
  ConsoleDocExportSet(&DocForm);
  ConsoleDocExportSet(&PopUpForm);
  ConsoleDocExportSet(&DocSplitTag);
  ConsoleDocExportSet(&DocGoToLine);
  ConsoleDocExportSet(&EdReplace);
  ConsoleDocExportSet(&StrOcc);
  ConsoleDocExportSet(&StrFirstOcc);
  ConsoleDocExportSet(&StrLastOcc);
  ConsoleDocExportSet(&StrFirstRem);
  ConsoleDocExportSet(&StrLastRem);
  ConsoleDocExportSet(&StrUtil);
  ConsoleDocExportSet(&MStrUtil);
  ConsoleDocExportSet(&Let2Drv);
  ConsoleDocExportSet(&BlkDevChk);
  ConsoleDocExportSet(&Let2BlkDev);
  ConsoleDocExportSet(&DrvIsWritable);
  ConsoleDocExportSet(&FileNameChk);
  ConsoleDocExportSet(&Silent);
  ConsoleDocExportSet(&IsSilent);
  ConsoleDocExportSet(&BlkDevLock);ConsoleDocExportSet(&BlkDevUnlock);
  ConsoleDocExportSet(&DrvLock);ConsoleDocExportSet(&DrvUnlock);
  ConsoleDocExportSet(&DrvsRelease);ConsoleDocExportSet(&BlkDevsRelease);
  ConsoleDocExportSet(&GetOutOfDollar);ConsoleDocExportSet(&PrintErr);ConsoleDocExportSet(&PrintWarn);
  ConsoleDocExportSet(&RawPutChar);
  ConsoleDocExportSet(&RedSeaFreeFreeLst);ConsoleDocExportSet(&DrvDel);
  ConsoleDocExportSet(&DrvBlkDevDel);ConsoleDocExportSet(&config->drive_records);ConsoleDocExportSet(&config->block_records);ConsoleDocExportSet(&BlkDevNextFreeSlot);
  ConsoleDocExportSet(&DrvMakeFreeSlot);ConsoleDocExportSet(&DrvNextFreeLet);
  ConsoleDocExportSet(&config->drive_map);ConsoleDocExportSet(&DrvMap);
  ConsoleDocExportSet(&GetStr);ConsoleDocExportSet(&DocGetStr2);ConsoleDocExportSet(&fp_getstr2);ConsoleDocExportSet(&DocClear);
  ConsoleDocExportSet(&DC2Sprite);ConsoleDocExportSet(&DocSprite);
  ConsoleDocExportSet(&DCLoad);ConsoleDocExportSet(&ExpandBuf);
  ConsoleDocExportSet(&ExtDft);ConsoleDocExportSet(&GRRead);ConsoleDocExportSet(&DocGR);
  ConsoleDocExportSet(&PortNop);ConsoleDocExportSet(&HPET);ConsoleDocExportSet(&Busy);
  ConsoleDocExportSet(&DocDump);ConsoleDocExportSet(&DocType);ConsoleDocExportSet(&Type);
  ConsoleDocExportSet(&PopUpTermRight);
  ConsoleDocExportSet(&WinBorder);
  ConsoleDocExportSet(&PostMsgWait);
  ConsoleDocExportSet(&EdFindReplace);ConsoleDocExportSet(&EdGoToLine);
  ConsoleDocExportSet(&FSize);ConsoleDocExportSet(&Clus2Blk);
  ConsoleDocExportSet(&DskCacheInit);ConsoleDocExportSet(&DskCacheAdd);
  ConsoleDocExportSet(&RCache);ConsoleDocExportSet(&DskCacheInvalidate2);
  ConsoleDocExportSet(&DskCacheGlobals);ConsoleDocExportSet(&BFieldExtU32);
  ConsoleDocExportSet(&BFieldOrU32);
  ConsoleDocExportSet(&ArcCompressBuf);ConsoleDocExportSet(&ArcCtrlDel);
  ConsoleDocExportSet(&ArcCtrlNew);ConsoleDocExportSet(&ArcExpandBuf);
  ConsoleDocExportSet(&ArcFinishCompression);ConsoleDocExportSet(&CompressBuf);
  for(i=0;i<sizeof(console_doc_exports)/sizeof(CI386KernelSymbol);i++) {
    console_doc_exports[i].str=export_names;
    while(*export_names)export_names++;
    export_names++;
    console_doc_exports[i].type=HTT_EXPORT_SYS_SYM;
    console_doc_exports[i].kind=1;
    if(Bt(console_doc_data_exports,i))console_doc_exports[i].kind=3;
    HashAdd(&console_doc_exports[i],task->hash_table);
  }
  DocDefaultsInit(&doldoc);
  display_planes=I386HeapAlloc(config->heap,153600,TRUE);
  if(!display_planes)return FALSE;
  if(!NativeGraphicsStorageReserve) {
    I386HeapFree(config->heap,display_planes);return FALSE;
  }
  console_planes=display_planes;
  console_config=config;
  mem_mapped_space=(config->heap->base+0)(U64)+config->heap->size;
  fp_doc_put=&DocPut;fp_getstr2=&DocGetStr2;
  native_editor_context.symbols=console_doc_exports;
  native_editor_context.symbol_count=sizeof(console_doc_exports)/sizeof(CI386KernelSymbol);
  NativeTimeStampInit; dbg.fun_seg_cache=native_fun_seg_cache;
  MusicSettingsRst;
  winmgr.fps=WINMGR_FPS;
  winmgr.ideal_refresh_tS=tS;
  winmgr.last_refresh_tS=winmgr.ideal_refresh_tS;
  NativeBreakpointInstall;
  *native_owner_retire_slot=(&NativeStorageOwnerRetire+0)(U64);
  if(config->defer_root_headers) return TRUE;
  return ConsoleRootHeaders;
}
Bool ConsoleRootHeaders()
{
  //Publish the resident reader with root declarations, after early diagnostics.
  console_config->files->public_reader(&NativeResidentReadBridge);
  //Publish the core first so its temporary parser arena is gone before the
  //remaining declarations. Each header transaction keeps atomic defines;
  //the complete user guard is committed only by the second compilation.
  KernelLog("ROOT KERNEL HEADERS begin\n");
  if(!ConsoleSource("#define NULL 0\n#define TRUE 1\n#define FALSE 0\n#include \"/Kernel/I386/PublicKernel.HH\"\n",
      "RootKernelHeaders.HC",I386_INPUT_ATOMIC_DEFINES|CCF_JUST_LOAD)) return FALSE;
  KernelLog("ROOT KERNEL HEADERS ok\n");
  //The immortal CPU root owns shared declarations; children inherit its scope.
  KernelLog("ROOT USER HEADERS begin\n");
  if(!ConsoleSource("#include \"/Kernel/I386/PublicUser.HH\"\n",
      "RootUserHeaders.HC",I386_INPUT_ATOMIC_DEFINES|CCF_JUST_LOAD)) return FALSE;
  KernelLog("ROOT USER HEADERS ok\n");
  return TRUE;
}
Bool ConsoleCancelRead(CI386Task *task)
{
  if(!console_config || !console_config->reader) return FALSE;
  return I386KbcInputCancel(console_config->reader->input,task);
}
Bool ConsoleKeyIrq(U8 data,U8 status)
{//Called with IF clear; request only, never allocate, switch or throw here.
  CI386Task *target;
  if(!I386KeyboardBreakKey(&console_hotkeys,data,status)) return FALSE;
  target=console_break_task;
  if(TaskValidate(sys_focus_task)) target=sys_focus_task;
  if(!target) return FALSE;
  return I386TaskBreakRequest(target);
}
I64 Main(CI386ConsoleServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386ConsoleServices)) return 0;
  services->version=console_version; services->bytes=bytes;
  services->init=&ConsoleInit; services->display=&ConsoleDisplay; services->keys=&ConsoleKeys;
  services->cancel_read=&ConsoleCancelRead;
  services->cancel_wait=&I386TaskCancelWait; services->key_irq=&ConsoleKeyIrq;
  services->root_headers=&ConsoleRootHeaders;
  services->window_ensure=&NativeWinMgrEnsure;
  services->cpu_capture=&ConsoleCpuCapture; services->cpu_debug=&ConsoleCpuDebug;
  return 1;
}
Bool console_display_initialized;
Bool ConsoleDisplay()
{
  U8 palette[48];
  I64 color;
  if(!console_config || console_display_initialized)return FALSE;
  if(!console_planes)console_planes=I386HeapAlloc(console_config->heap,153600,TRUE);
  if(!console_planes)KernelStop;
  for(color=0;color<16;color++) {
    palette[color*3]=0; palette[color*3+1]=0; palette[color*3+2]=0;
    if(color&4) palette[color*3]=42;
    if(color&2) palette[color*3+1]=42;
    if(color&1) palette[color*3+2]=42;
    if(color&8) {
      palette[color*3]+=21; palette[color*3+1]+=21; palette[color*3+2]+=21;
    }
    if(color==6) palette[color*3+1]=21;
  }
  I386VgaPalette(palette);
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,console_title);
  console_display_initialized=TRUE;
  ConsolePresent;
  return TRUE;
}
U0 ConsoleKeys(I64 unused)
{//Root startup; ordinary and spawned terminals share task-owned input loops.
  I64 header_used;
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  NativeTerminalAdoptRoot;
  sys_focus_task=task;
  //Fresh scheduler entries have IF clear. Devices and task services are ready;
  //allow timer/keyboard delivery during startup compilation and user execution.
  SetRFlags(GetRFlags|0x200);
  header_used=scope->heap->used;
  KernelLog("PUBLIC HEADERS begin\n");
  if(ConsoleSource("#include \"/Kernel/I386/PublicKernel.HH\"\n","ConsoleHeaders.HC",
      I386_INPUT_ATOMIC_DEFINES|CCF_JUST_LOAD)) KernelLog("PUBLIC HEADERS ok\n");
  else { ConsolePresent; KernelLog("PUBLIC HEADERS error\n"); KernelStop; }
  KernelLog("PUBLIC HEADERS MEMORY "); KernelHex(scope->heap->used-header_used); KernelLog("\n");
  KernelLog("STARTUP source begin\n");
  if(ConsoleSource("#include \"/Kernel/I386/StartOS.HC\"\n","ConsoleStartup.HC"))
    KernelLog("STARTUP source ok\n");
  else KernelLog("STARTUP source error\n");
  if(!NativeKeyboardStart) { KernelLog("KEYBOARD MESSAGE start failed\n"); KernelStop; }
  KernelLog("DONE native kernel startup\n");
  NativeUserTaskCont;
}

U0 NativeTerminalInput()
{
  CI386KeyEvent event;
  CDoc *doc=DocPut;
  CDocEntry *prompt;
  U8 *line;
  I64 length=0,decoded,ch,spaces,
      mouse_x=0,mouse_y=0,mouse_buttons=0,mouse_packets=0,
      next_mouse_x,next_mouse_y,next_mouse_buttons,next_mouse_packets;
  Bool mouse_visible=FALSE;
  NativeTerminalTranscriptStart;
  if(!doc) throw('DocOwner',TRUE);
  prompt=NativeConsolePrompt; ConsolePresent;
  MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets);
  while(1) {
    decoded=NativeTerminalInputKey(&event);
    if(decoded>0) I386TaskSelf->task_flags&=~(1<<TASKf_IDLE|1<<TASKf_CMD_LINE_PMT);
    if(decoded && mouse_visible) {
      NativeMousePlaneHide(console_planes,mouse_x,mouse_y);
      mouse_visible=FALSE;
    }
    if(decoded<0) {
      length=0;
      NativeConsoleWrite("\nInput reset\n");
      doc=DocPut; prompt=NativeConsolePrompt;
      ConsolePresent;
      KernelLog("INPUT RESET\n");
    } else if(decoded && event.type==2) {
      ch=event.ch;
      if(ch==3) {
        length=0; NativeConsoleWrite("^C\n");
        doc=DocPut; prompt=NativeConsolePrompt;
        KernelLog("INPUT CANCEL\n");
      } else if(ch==8) {
        if(length) { length--; NativeConsolePut(8); }
      } else if(ch==10) {
        line=DocScanLine(doc,prompt->next);
        KernelLog("INPUT LINE "); KernelLog(line); KernelLog("\n");
        NativeConsolePut(10);
        try { ConsoleSubmit(line); }
        catch { Free(line); }
        Free(line);
        length=0; doc=DocPut; prompt=NativeConsolePrompt;
      } else if(ch==9) {
        spaces=8-length%8;
        while(spaces--) {
          length++; NativeConsolePut(32);
        }
      } else if(ch>=32 && ch<=255) {
        length++; NativeConsolePut(ch);
      }
      ConsolePresent;
    }
    if(NativeTerminalVisible && MouseGet(&next_mouse_x,&next_mouse_y,&next_mouse_buttons,&next_mouse_packets) &&
        next_mouse_packets!=mouse_packets) {
      if(mouse_visible)
        NativeMousePlaneMove(console_planes,mouse_x,mouse_y,next_mouse_x,next_mouse_y);
      else {
        NativeDocMouseShow(console_planes,next_mouse_x,next_mouse_y);
        mouse_visible=TRUE; KernelLog("CONSOLE mouse pointer\n");
      }
      mouse_x=next_mouse_x; mouse_y=next_mouse_y;
      mouse_buttons=next_mouse_buttons; mouse_packets=next_mouse_packets;
    }
    if(!decoded) {
      I386TaskSelf->task_flags|=1<<TASKf_IDLE;
      if(!length) I386TaskSelf->task_flags|=1<<TASKf_CMD_LINE_PMT;
      I386SchedYield(I386TaskSelf->owner); I386TaskBreakPoll;
    }
  }
}


#include "/Kernel/I386/Vga.HC"
#include "/Kernel/I386/Text.HC"
#include "/Kernel/I386/TextVga.HC"
#include "/Kernel/I386/ConsoleOutput.HC"
#include "/Kernel/I386/KeyDevRuntime.HC"
#include "/Adam/DolDoc/DocGetKeyCore.HC"
#include "/Kernel/I386/ConsoleNumbers.HC"
#include "/Kernel/I386/ConsoleInput.HC"
#include "/Kernel/I386/Debugger.HC"

extern U0 ConsolePresentText(CI386Text *surface);

U0 ConsolePresent()
{
  if(NativeTerminalVisible) {
    //Consume only when a visible surface can honor the full-screen refresh.
    if(LBtr(&sys_semas[SEMA_FLUSH_VGA_IMAGE],0)) {
      NativeTerminalText()->dirty_first=0;NativeTerminalText()->dirty_last=60;
    }
    ConsolePresentText(&console_text);
  }
}

#include "/Kernel/I386/KbcInputCancel.HC"

#include "/Kernel/I386/WaitCancel.HC"

#include "/Kernel/I386/KbcInputRead.HC"
#include "/Kernel/I386/ScanSet1.HC"
#include "/Kernel/I386/ScanChar.HC"
#include "/Kernel/I386/ScanState.HC"
#include "/Kernel/I386/KeyboardEvent.HC"
#include "/Kernel/I386/KeyboardRead.HC"

#include "/Kernel/I386/KeyboardBreak.HC"
#define I386_TASK_BREAK_RELEASE DrvsRelease;BlkDevsRelease;
#include "/Kernel/I386/TaskBreak.HC"

U0 I386DocBreakPoll()
{
  console_config->compiler->break_poll();
}
#include "/Kernel/I386/DocLock.HC"

#include "/Kernel/I386/DocAccess.HC"

#include "/Kernel/I386/DocumentReport.HC"

#include "/Kernel/I386/TextRender.HC"
#include "/Kernel/I386/GraphicsFrame.HC"
#include "/Kernel/I386/WindowUpdateScope.HC"
#include "/Kernel/I386/WindowList.HC"

#include "/Kernel/I386/KeyboardMessages.HC"

#include "/Kernel/I386/Terminals.HC"

U0 NativePostMsg(CTask *task,I64 code,I64 a,I64 b,I64 flags=0)
{ (*native_post_msg)(task,code,a,b,flags); }
#define PostMsg NativePostMsg
#define TaskWait NativeTaskWait
#include "/Kernel/PostMsgWaitCore.HC"
#include "/Kernel/I386/ConsolePresent.HC"
#include "/Kernel/I386/MousePresent.HC"

#include "/Kernel/I386/ServantRuntime.HC"

#include "/Kernel/I386/WindowOrderRuntime.HC"

#include "/Kernel/I386/WindowManager.HC"
#include "/Kernel/I386/RefreshScope.HC"

#include "/Kernel/I386/PopupRuntime.HC"

//Original flagged/form sessions use native document/teardown scopes.
#define DOC_ED_FUNCTION NativeOriginalDocEd
#define DOC_VIEW_FUNCTION NativeOriginalView
#include "/Kernel/I386/DocEdScope.HC"

//Complete mutually dependent original actions and chooser wrappers.
U0 NativeActionMsg(I64 code,I64 a,I64 b,I64 flags=0)
{ (*native_output_msg)(code,a,b,flags); }
U0 NativeActionExit() { (*native_action_exit)(); }
#define Msg NativeActionMsg
#define Exit NativeActionExit
#define PopUp NativePopUp
#define PopUpPrint NativePopUpPrint
#define WinToTop NativeWinToTop
#include "/Adam/DolDoc/DocEntryRunCore.HC"
#include "/Adam/DolDoc/DocMenuCore.HC"
#include "/Adam/DolDoc/DocMenuPopupCore.HC"
#include "/Adam/DolDoc/TermRightMenuCore.HC"
#include "/Adam/DolDoc/DocPickLstCore.HC"
#include "/Adam/DolDoc/DocGetStrCore.HC"
#include "/Kernel/GetStrCore.HC"

//Complete original character, selection and cursor primitives for DocPutKey.
import I64 RoundI64(I64 num,I64 to);
#define char_bmp_printable native_doc_printable
#include "/Adam/DolDoc/DocChar.HC"

#include "/Adam/DolDoc/DocInsertDocumentCore.HC"
#include "/Adam/DolDoc/DocClipboardCore.HC"
U0 NativeClipboardInit()
{
  if(!sys_clip_doc)sys_clip_doc=DocNew(NULL,I386TaskSelf->owner->root);
}

#include "/Adam/DolDoc/DocLoadCore.HC"

#include "/Kernel/I386/Bits.HH"
#include "/Adam/DolDoc/DocPlainTextCore.HC"
#include "/Adam/DolDoc/DocSaveCore.HC"

#include "/Kernel/I386/TimeStampRuntime.HC"
#define GetTSC NativeTimeStamp
import CCntsGlbls cnts;
#include "/Adam/DolDoc/DocUndoCore.HC"

#include "/Kernel/KeyNameCore.HC"
#include "/Kernel/KeyDescriptionCore.HC"

#include "/Adam/DolDoc/DocTransformCore.HC"

#include "/Kernel/I386/EditorDispatch.HC"

#include "/Kernel/BlkDev/CFileSizeCore.HC"

#include "/Kernel/BlkDev/ClusToBlockCore.HC"
