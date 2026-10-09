//Retained task-owned VGA consoles and native command input.
#include "/Kernel/Types.HH"
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/MathConstants.HH"
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
I64 (*native_servant_flush)(CTask *task);
extern U0 NativeUserCmdLine(I64 dummy=0);
extern CTask *NativeWinFocus(CTask *task=0);
extern I64 *NativeTerminalLossSeen();
extern U0 NativeTerminalDiscardKeyboard();
extern Bool NativeTerminalFocusKey(CI386KeyEvent *event);
extern U0 NativeUserHotkey(U8 *data);
extern U8 *NativeTerminalLine(I64 required);
extern I64 NativeTerminalInputKey(CI386KeyEvent *event);
extern CTask *NativeUser(U8 *fmt=0,...);
extern U0 NativeXTalk(CTask *task,U8 *fmt,...);
extern U0 NativeTaskWait(CTask *task=0,Bool cmd_line_pmt=FALSE);
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
extern Bool NativeKeyboardStart();
extern I64 NativeReadKey(CI386KeyboardReader *reader,CI386KeyEvent *event,Bool wait=TRUE);
extern I64 NativeJobSource(U8 *text);
CTask *sys_focus_task,*sys_winmgr_task;
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
#include "/Kernel/I386/DocumentRuntime.HC"
#include "/Kernel/I386/InstallTree.HC"
#include "/Kernel/I386/BuildModuleDispatch.HC"
#include "/Kernel/I386/BuildBootImage.HC"
#include "/Kernel/I386/SoundRuntime.HC"
#include "/Kernel/I386/TextBase.HC"
#include "/Kernel/I386/Window.HC"
#include "/Kernel/I386/RasterRuntime.HC"
#include "/Kernel/IsRawCore.HC"
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
U0 NativeWinRefreshCommit()
{//Only completed physical presentation advances refresh observations.
  U32 flags=I386IrqSave;
  WinMgrRefreshTime(&winmgr,tS);
  winmgr.updates++;
  I386IrqRestore(flags);
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
#include "/Kernel/DefineLoadCore.HC"
#include "/Kernel/DefinePrintCore.HC"
#include "/Adam/God/BibleTypes.HH"
#include "/Kernel/I386/ScannerRuntime.HC"
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
#include "/Kernel/BlkDev/DriveClassCore.HC"
#include "/Kernel/BlkDev/DriveTextAttrCore.HC"
#include "/Kernel/FileMaskTypes.HH"
#include "/Kernel/WildMatchCore.HC"
#include "/Kernel/BlkDev/FilesFindMatchCore.HC"
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
#include "/Kernel/BitFieldExtractCore.HC"
#include "/Adam/Gr/SpriteRenderCore.HC"
//Song strings use the existing scheduler-root-owned provider defined below.
extern U8 *NativeAStrNew(U8 *text);
#define AStrNew NativeAStrNew
#include "/Adam/DolDoc/DocRecalcCore.HC"
#include "/Kernel/StrIMatchCore.HC"
#include "/Adam/DolDoc/DocFindCore.HC"

#include "/Kernel/JobResScanCore.HC"
extern U0 NativePrint(U8 *fmt,...);
extern U0 NativePutS(U8 *text);
extern U0 NativePutChars(U64 chars);
U0 (*native_output_msg)(I64 msg_code,I64 arg1,I64 arg2,I64 flags);
#include "/Kernel/I386/InputFilterRuntime.HC"
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
CI386KernelSymbol console_doc_exports[208];
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
U0 ConsoleDocExportSet(I64 index,U8 *name,U64 value)
{//Share export setup code across the complete public document binding table.
  console_doc_exports[index].str=name;
  console_doc_exports[index].val=value;
}

Bool ConsoleInit(CI386ConsoleConfig *config)
{
  U8 *display_planes;
  CI386Task *task=I386TaskSelf;
  I64 i;
  CI386KernelSymbol *provider;
  if(!task || !task->hash_table || console_config || !config || !config->heap || !config->compiler ||
      config->compiler->version!=I386_COMPILER_SERVICES_VERSION ||
      config->compiler->bytes!=sizeof(CI386CompilerServices) || !config->compiler->input || !config->compiler->break_poll ||
      config->pit_divisor<2 || config->pit_divisor>65536 || !config->files || !config->includes || !config->types || !config->reader || !config->input) return FALSE;
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
  provider=HashFind("_JOBS_HNDLR",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_input_jobs=provider->val;
  provider=HashFind("_YIELD",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_input_yield=provider->val;
  provider=HashFind("_FLUSH_MSGS",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!provider || provider->kind!=1 || !provider->val) return FALSE;
  native_servant_flush=provider->val;
  if(!I386KeyboardReadInit(config->reader,config->input)) return FALSE;
  I386KeyboardReset(&console_hotkeys);
  ConsoleDocExportSet(0,"_DOC_LOCK",(&I386DocLock+0)(U64));
  ConsoleDocExportSet(1,"_DOC_UNLOCK",(&I386DocUnlock+0)(U64));
  ConsoleDocExportSet(2,"_DOC_PUT",(&DocPut+0)(U64));
  ConsoleDocExportSet(3,"_DOC_DISPLAY",(&DocDisplay+0)(U64));
  ConsoleDocExportSet(4,"_DOC_BORDER",(&DocBorder+0)(U64));
  ConsoleDocExportSet(5,"_DOC_EDITABLE",(&IsEditableText+0)(U64));
  ConsoleDocExportSet(6,"_DOC_ENTRY_BASE",(&DocEntryNewBase+0)(U64));
  ConsoleDocExportSet(7,"_DOC_ENTRY_TAG",(&DocEntryNewTag+0)(U64));
  ConsoleDocExportSet(8,"_DOC_ENTRY_SIZE",(&DocEntrySize+0)(U64));
  ConsoleDocExportSet(9,"_DOC_ENTRY_COPY",(&DocEntryCopy+0)(U64));
  ConsoleDocExportSet(10,"_DOC_FORM_FWD",(&DocFormFwd+0)(U64));
  ConsoleDocExportSet(11,"_DOC_FORM_BWD",(&DocFormBwd+0)(U64));
  ConsoleDocExportSet(12,"_DOC_DEFAULTS_INIT",(&DocDefaultsInit+0)(U64));
  ConsoleDocExportSet(13,"_DOC_INIT",(&DocInit+0)(U64));
  ConsoleDocExportSet(14,"_DOC_DICTIONARY_NEW",(&DocDictionaryNew+0)(U64));
  ConsoleDocExportSet(15,"_DOC_DICTIONARY_DEL",(&DocDictionaryDel+0)(U64));
  ConsoleDocExportSet(16,"_DOC_GLOBALS_INIT",(&DocGlobalsInit+0)(U64));
  ConsoleDocExportSet(17,"_DOC_START",(&ConsoleDocumentStart+0)(U64));
  ConsoleDocExportSet(18,"doldoc",(&doldoc+0)(U64));
  ConsoleDocExportSet(19,"_DOC_REPORT_LITERAL",(&DocReportLiteral+0)(U64));
  ConsoleDocExportSet(20,"_DOC_BIN_FIND_NUM",(&DocBinFindNum+0)(U64));
  ConsoleDocExportSet(21,"_DOC_BIN_FIND_TAG",(&DocBinFindTag+0)(U64));
  ConsoleDocExportSet(22,"_DOC_BINS_VALIDATE",(&DocBinsValidate+0)(U64));
  ConsoleDocExportSet(23,"_DOC_BIN_DEL",(&DocBinDel+0)(U64));
  ConsoleDocExportSet(24,"_DOC_ENTRY_DEL",(&DocEntryDel+0)(U64));
  ConsoleDocExportSet(25,"_DOC_UNDO_DEL",(&DocUndoDel+0)(U64));
  ConsoleDocExportSet(26,"_DOC_UNDO_COUNT",(&DocUndoCntSet+0)(U64));
  ConsoleDocExportSet(27,"_DOC_REM_SOFT",(&DocRemSoftNewLines+0)(U64));
  ConsoleDocExportSet(28,"_DOC_INS_ENTRY",(&DocInsEntry+0)(U64));
  NativeTextBaseInit;
  ConsoleDocExportSet(29,"_TEXT_CHAR",(&TextChar+0)(U64));
  ConsoleDocExportSet(30,"_TEXT_LEN_STR",(&TextLenStr+0)(U64));
  ConsoleDocExportSet(31,"_TEXT_LEN_ATTR_STR",(&TextLenAttrStr+0)(U64));
  ConsoleDocExportSet(32,"_TEXT_LEN_ATTR",(&TextLenAttr+0)(U64));
  ConsoleDocExportSet(33,"i386_text_base",(&i386_text_base+0)(U64));
  ConsoleDocExportSet(34,"_TEXT_BASE_PRESENT",(&NativeTextBasePresent+0)(U64));
  ConsoleDocExportSet(35,"_TEXT_BASE_RESTORE",(&NativeTextBaseRestore+0)(U64));
  ConsoleDocExportSet(36,"_LIST_SUB",(&LstSub+0)(U64));
  ConsoleDocExportSet(37,"_LIST_MATCH",(&LstMatch+0)(U64));
  ConsoleDocExportSet(38,"_DEFINE",(&Define+0)(U64));
  ConsoleDocExportSet(39,"_DEFINE_SUB",(&DefineSub+0)(U64));
  ConsoleDocExportSet(40,"_DEFINE_COUNT",(&DefineCnt+0)(U64));
  ConsoleDocExportSet(41,"_DEFINE_MATCH",(&DefineMatch+0)(U64));
  ConsoleDocExportSet(42,"_YEAR_START_DATE",(&YearStartDate+0)(U64));
  ConsoleDocExportSet(43,"_STRUCT_TO_DATE",(&Struct2Date+0)(U64));
  ConsoleDocExportSet(44,"_DAY_OF_WEEK",(&DayOfWeek+0)(U64));
  ConsoleDocExportSet(45,"_DATE_TO_STRUCT",(&Date2Struct+0)(U64));
  ConsoleDocExportSet(46,"_FIRST_DAY_MONTH",(&FirstDayOfMon+0)(U64));
  ConsoleDocExportSet(47,"_LAST_DAY_MONTH",(&LastDayOfMon+0)(U64));
  ConsoleDocExportSet(48,"_FIRST_DAY_YEAR",(&FirstDayOfYear+0)(U64));
  ConsoleDocExportSet(49,"_LAST_DAY_YEAR",(&LastDayOfYear+0)(U64));
  ConsoleDocExportSet(50,"_BCD_TO_BIN",(&Bcd2Bin+0)(U64));
  ConsoleDocExportSet(51,"local_time_offset",(&local_time_offset+0)(U64));
  ConsoleDocExportSet(52,"_MAT4X4MULXYZ",(&Mat4x4MulXYZ+0)(U64));
  ConsoleDocExportSet(53,"_DCTRANSFORM",(&DCTransform+0)(U64));
  ConsoleDocExportSet(54,"_MAT4X4IDENTEQU",(&Mat4x4IdentEqu+0)(U64));
  ConsoleDocExportSet(55,"_MAT4X4IDENTNEW",(&Mat4x4IdentNew+0)(U64));
  ConsoleDocExportSet(56,"_MAT4X4NORMSQR65536",(&Mat4x4NormSqr65536+0)(U64));
  ConsoleDocExportSet(57,"_DCMAT4X4SET",(&DCMat4x4Set+0)(U64));
  ConsoleDocExportSet(58,"_DCLIGHTING",(&DCLighting+0)(U64));
  ConsoleDocExportSet(59,"_DCFILL",(&DCFill+0)(U64));
  ConsoleDocExportSet(60,"_DCCLEAR",(&DCClear+0)(U64));
  ConsoleDocExportSet(61,"_DCRST",(&DCRst+0)(U64));
  ConsoleDocExportSet(62,"_DCEXTENTSINIT",(&DCExtentsInit+0)(U64));
  ConsoleDocExportSet(63,"_DCALIAS",(&DCAlias+0)(U64));
  ConsoleDocExportSet(64,"_DCNEW",(&DCNew+0)(U64));
  ConsoleDocExportSet(65,"_DCDEL",(&DCDel+0)(U64));
  ConsoleDocExportSet(66,"_DCSIZE",(&DCSize+0)(U64));
  ConsoleDocExportSet(67,"_DCDEPTHBUFRST",(&DCDepthBufRst+0)(U64));
  ConsoleDocExportSet(68,"_DCDEPTHBUFALLOC",(&DCDepthBufAlloc+0)(U64));
  ConsoleDocExportSet(69,"gr",(&gr+0)(U64));
  ConsoleDocExportSet(70,"gr_palette_std",(&gr_palette_std+0)(U64));
  ConsoleDocExportSet(71,"_GRAPHICS_START",(&NativeGraphicsStart+0)(U64));
  ConsoleDocExportSet(72,"_GRAPHICS_PRESENT",(&NativeGraphicsPresent+0)(U64));
  ConsoleDocExportSet(73,"_TEXT_BORDER",(&TextBorder+0)(U64));
  ConsoleDocExportSet(74,"_TEXT_RECT",(&TextRect+0)(U64));
  ConsoleDocExportSet(75,"_WIN_SCROLL_NULL",(&WinScrollNull+0)(U64));
  ConsoleDocExportSet(76,"_WIN_SCROLL_RESTORE",(&WinScrollRestore+0)(U64));
  ConsoleDocExportSet(77,"_WIN_DERIVED_VALS_UPDATE",(&WinDerivedValsUpdate+0)(U64));
  ConsoleDocExportSet(78,"text",(&text+0)(U64));
  ConsoleDocExportSet(79,"_TASK_VALIDATE",(&TaskValidate+0)(U64));
  ConsoleDocExportSet(80,"_TASK_DERIVED_VALS_UPDATE",(&TaskDerivedValsUpdate+0)(U64));
  ConsoleDocExportSet(81,"_WIN_HORZ",(&WinHorz+0)(U64));
  ConsoleDocExportSet(82,"_WIN_VERT",(&WinVert+0)(U64));
  ConsoleDocExportSet(83,"_CTRL_FIND_UNIQUE",(&CtrlFindUnique+0)(U64));
  ConsoleDocExportSet(84,"_CTRLS_UPDATE",(&CtrlsUpdate+0)(U64));
  ConsoleDocExportSet(85,"_CTRL_INSIDE",(&CtrlInside+0)(U64));
  ConsoleDocExportSet(86,"_WIN_Z_BUF_UPDATE",(&WinZBufUpdate+0)(U64));
  ConsoleDocExportSet(87,"_WIN_INSIDE",(&WinInside+0)(U64));
  ConsoleDocExportSet(88,"_DOC_NEW",(&DocNew+0)(U64));
  ConsoleDocExportSet(89,"_DOC_RST",(&DocRst+0)(U64));
  ConsoleDocExportSet(90,"_DOC_DEL",(&DocDel+0)(U64));
  ConsoleDocExportSet(91,"_DOC_SIZE",(&DocSize+0)(U64));
  ConsoleDocExportSet(92,"_DOC_PUT_KEY",(&DocPutKey+0)(U64));
  ConsoleDocExportSet(93,"_DOC_SAVE",(&DocSave+0)(U64));
  ConsoleDocExportSet(94,"_DOC_WRITE",(&DocWrite+0)(U64));
  ConsoleDocExportSet(95,"_DOC_READ",(&DocRead+0)(U64));
  ConsoleDocExportSet(96,"_DOC_ED",(&DocEd+0)(U64));
  ConsoleDocExportSet(97,"_DOC_ALLOCATION_CHECK",(&DocAllocationCheck+0)(U64));
  ConsoleDocExportSet(98,"_DOC_EXE",(&DocExe+0)(U64));
  ConsoleDocExportSet(99,"_DIR_MK",(&DirMk+0)(U64));
  ConsoleDocExportSet(100,"_ED",(&Ed+0)(U64));
  ConsoleDocExportSet(101,"_DIR",(&Dir+0)(U64));
  ConsoleDocExportSet(102,"_ED_DIR",(&EdDir+0)(U64));
  ConsoleDocExportSet(103,"_FILE_DEL",(&FileDel+0)(U64));
  ConsoleDocExportSet(104,"_FILE_RENAME",(&FileRename+0)(U64));
  ConsoleDocExportSet(105,"_DIR_DEL",(&DirDel+0)(U64));
  ConsoleDocExportSet(106,"_FILE_MOVE",(&FileMove+0)(U64));
  ConsoleDocExportSet(107,"_HELP",(&Help+0)(U64));
  ConsoleDocExportSet(108,"_SND",(&Snd+0)(U64));
  ConsoleDocExportSet(109,"_SND_RST",(&SndRst+0)(U64));
  ConsoleDocExportSet(110,"_MOUSE_GET",(&MouseGet+0)(U64));
  ConsoleDocExportSet(111,"_I386_INSTALL_TREE",(&I386InstallTree+0)(U64));
  ConsoleDocExportSet(112,"_I386_INSTALL_BOOT",(&I386InstallBoot+0)(U64));
  ConsoleDocExportSet(113,"_I386_BUILD_MODULE",(&I386BuildModule+0)(U64));
  ConsoleDocExportSet(114,"_I386_BUILD_BOOT_IMAGE",(&I386BuildBootImage+0)(U64));
  ConsoleDocExportSet(115,"_I386_INSTALL_BOOT_IMAGE",(&I386InstallBootImage+0)(U64));
  ConsoleDocExportSet(116,"_EXE_DOC",(&ExeDoc+0)(U64));
  ConsoleDocExportSet(117,"_I386_JOB_SOURCE",(&NativeJobSource+0)(U64));
  ConsoleDocExportSet(118,"_SYS_FOCUS_TASK",(&sys_focus_task+0)(U64));
  ConsoleDocExportSet(119,"_DBG",(&NativeDebug+0)(U64));
  ConsoleDocExportSet(120,"_DEBUG_GO",(&NativeDebugGo+0)(U64));
  ConsoleDocExportSet(121,"_DBG_MODE",(&NativeDebugMode+0)(U64));
  ConsoleDocExportSet(122,"_IS_DBG_MODE",(&NativeIsDebugMode+0)(U64));
  ConsoleDocExportSet(123,"_USER_CMD_LINE",(&NativeUserCmdLine+0)(U64));
  ConsoleDocExportSet(124,"_USER_TASK_CONT",(&NativeUserTaskCont+0)(U64));
  ConsoleDocExportSet(125,"_WIN_FOCUS",(&NativeWinFocus+0)(U64));
  ConsoleDocExportSet(126,"_IS_RAW",(&IsRaw+0)(U64));
  ConsoleDocExportSet(127,"_STR_PRINT_JOIN",(&StrPrintJoin+0)(U64));
  ConsoleDocExportSet(128,"_STR_PRINT",(&StrPrint+0)(U64));
  ConsoleDocExportSet(129,"_CAT_PRINT",(&CatPrint+0)(U64));
  ConsoleDocExportSet(130,"_MSTR_PRINT",(&MStrPrint+0)(U64));
  ConsoleDocExportSet(131,"_USER",(&NativeUser+0)(U64));
  ConsoleDocExportSet(132,"_XTALK",(&NativeXTalk+0)(U64));
  ConsoleDocExportSet(133,"_TASK_WAIT",(&NativeTaskWait+0)(U64));
  ConsoleDocExportSet(134,"_FILE_WRITE",(&FileWrite+0)(U64));
  ConsoleDocExportSet(135,"_FILE_READ",(&NativePublicFileRead+0)(U64));
  ConsoleDocExportSet(136,"_FILE_FIND",(&FileFind+0)(U64));
  ConsoleDocExportSet(137,"_CD",(&Cd+0)(U64));
  ConsoleDocExportSet(138,"_DEBUG_STEP",(&NativeDebugStep+0)(U64));
  ConsoleDocExportSet(139,"_TASK_REG_ADDR",(&TaskRegAddr+0)(U64));
  ConsoleDocExportSet(140,"_BPT_FIND",(&BptFind+0)(U64));
  ConsoleDocExportSet(141,"_BPT_SET",(&BptS+0)(U64));
  ConsoleDocExportSet(142,"_BPT_REMOVE",(&BptR+0)(U64));
  ConsoleDocExportSet(143,"_BPT_TOGGLE",(&B+0)(U64));
  ConsoleDocExportSet(144,"_BPT_CLEAR",(&B2+0)(U64));
  ConsoleDocExportSet(145,"_DEBUG_GO_CLEAR",(&NativeDebugGoClear+0)(U64));
  ConsoleDocExportSet(146,"_CALLER",(&NativeCaller+0)(U64));
  ConsoleDocExportSet(147,"_SYS_MACRO_2_STR",(&SysMacro2Str+0)(U64));
  ConsoleDocExportSet(148,"_SYS_MACRO_STRIP_KEY",(&SysMacroStripKey+0)(U64));
  ConsoleDocExportSet(149,"_PRINT",(&NativePrint+0)(U64));
  ConsoleDocExportSet(150,"_PUT_S",(&NativePutS+0)(U64));
  ConsoleDocExportSet(151,"_PUT_CHARS",(&NativePutChars+0)(U64));
  ConsoleDocExportSet(152,"_TASK_TEXT",(&NativeTaskText+0)(U64));
  ConsoleDocExportSet(153,"_IN_STR",(&InStr+0)(U64));
  ConsoleDocExportSet(154,"_XTALK_STR_WAIT",(&XTalkStrWait+0)(U64));
  ConsoleDocExportSet(155,"_PLAY_SYS_MACRO",(&PlaySysMacro+0)(U64));
  ConsoleDocExportSet(156,"_STR_SCAN",(&StrScan+0)(U64));
  ConsoleDocExportSet(157,"_STR_TO_I64",(&Str2I64+0)(U64));
  ConsoleDocExportSet(158,"_STR_TO_F64",(&Str2F64+0)(U64));
  ConsoleDocExportSet(159,"_STR_TO_DATE",(&Str2Date+0)(U64));
  ConsoleDocExportSet(160,"_DOC_DOLLAR",(&PrsDollarCmd+0)(U64));
  ConsoleDocExportSet(161,"_DOC_DATA_FMT",(&DocDataFmt+0)(U64));
  ConsoleDocExportSet(162,"_DOC_DATA_SCAN",(&DocDataScan+0)(U64));
  ConsoleDocExportSet(163,"_DOC_PUT_S",(&DocPutS+0)(U64));
  ConsoleDocExportSet(164,"_DOC_PRINT",(&DocPrint+0)(U64));
  ConsoleDocExportSet(165,"_IN",(&In+0)(U64));
  ConsoleDocExportSet(166,"_JOB_RES_SCAN",(&JobResScan+0)(U64));
  ConsoleDocExportSet(167,"_JOB_DEL",(&JobDel+0)(U64));
  ConsoleDocExportSet(168,"_TASK_EXE",(&NativeTaskExe+0)(U64));
  ConsoleDocExportSet(169,"_SRV_TASK_CONT",(&NativeSrvTaskCont+0)(U64));
  ConsoleDocExportSet(170,"_SRV_CMD_LINE",(&NativeSrvCmdLine+0)(U64));
  sys_winmgr_task=task;
  ConsoleDocExportSet(171,"_WIN_TO_TOP",(&NativeWinToTop+0)(U64));
  ConsoleDocExportSet(172,"_SYS_WINMGR_TASK",(&sys_winmgr_task+0)(U64));
  ConsoleDocExportSet(173,"_DOC_BORDER_NEW",(&DocBorderNew+0)(U64));
  ConsoleDocExportSet(174,"_ED_OVERSTRIKE_CB",(&EdOverStrikeCB+0)(U64));
  ConsoleDocExportSet(175,"_ED_AUTO_SAVE_CB",(&EdAutoSaveCB+0)(U64));
  ConsoleDocExportSet(176,"_ED_FILTER_CB",(&EdFilterCB+0)(U64));
  ConsoleDocExportSet(177,"_ED_DOLLAR_CB",(&EdDollarCB+0)(U64));
  ConsoleDocExportSet(178,"_ED_MORE_CB",(&EdMoreCB+0)(U64));
  ConsoleDocExportSet(179,"_ED_DOLLAR_TYPE_CB",(&EdDollarTypeCB+0)(U64));
  ConsoleDocExportSet(180,"_MENU_NEW",(&NativeMenuNew+0)(U64));
  ConsoleDocExportSet(181,"_MENU_FILE",(&MenuFile+0)(U64));
  ConsoleDocExportSet(182,"_MENU_ENTRY_FIND",(&MenuEntryFind+0)(U64));
  ConsoleDocExportSet(183,"_MENU_SUB_ENTRY_FIND",(&MenuSubEntryFind+0)(U64));
  ConsoleDocExportSet(184,"_MENU_DEL",(&MenuDel+0)(U64));
  ConsoleDocExportSet(185,"_GR_RECT",(&GrRect+0)(U64));
  ConsoleDocExportSet(186,"_RAND_U16",(&RandU16+0)(U64));
  ConsoleDocExportSet(187,"_DIST_SQR_I64",(&DistSqrI64+0)(U64));
  ConsoleDocExportSet(188,"_WIN_SCROLLS_INIT",(&WinScrollsInit+0)(U64));
  ConsoleDocExportSet(189,"_RAW",(&Raw+0)(U64));
  ConsoleDocExportSet(190,"_VGA_FLUSH",(&VGAFlush+0)(U64));
  ConsoleDocExportSet(191,"_DOC_ENTRY_LINK",(&DocEntryLink+0)(U64));
  ConsoleDocExportSet(192,"_FILE_NAME_ABS",(&FileNameAbs+0)(U64));
  ConsoleDocExportSet(193,"_SRC_LINE_NUM",(&SrcLineNum+0)(U64));
  ConsoleDocExportSet(194,"_SRC_FILE_NAME",(&SrcFileName+0)(U64));
  ConsoleDocExportSet(195,"_SRC_ED_LINK",(&SrcEdLink+0)(U64));
  ConsoleDocExportSet(196,"_EXE_PUTS",(&ExePutS+0)(U64));
  ConsoleDocExportSet(197,"_EXE_PRINT",(&ExePrint+0)(U64));
  ConsoleDocExportSet(198,"_DEFINE_LOAD",(&DefineLoad+0)(U64));
  ConsoleDocExportSet(199,"_DEFINE_PRINT",(&DefinePrint+0)(U64));
  ConsoleDocExportSet(200,"_BIBLE_INIT",(&BibleInit+0)(U64));
  ConsoleDocExportSet(201,"_ED_LINK_CVT",(&EdLinkCvt+0)(U64));
  ConsoleDocExportSet(202,"_DOC_LINK_FILE",(&DocLinkFile+0)(U64));
  ConsoleDocExportSet(203,"_DRV_CHECK",(&DrvChk+0)(U64));
  ConsoleDocExportSet(204,"_DRV_TO_LET",(&Drv2Let+0)(U64));
  ConsoleDocExportSet(205,"_LET_TO_LET",(&Let2Let+0)(U64));
  ConsoleDocExportSet(206,"_LET_TO_BLOCK_DEV_TYPE",(&Let2BlkDevType+0)(U64));
  ConsoleDocExportSet(207,"_DRV_TEXT_ATTR_GET",(&DrvTextAttrGet+0)(U64));
  for(i=0;i<208;i++) {
    console_doc_exports[i].type=HTT_EXPORT_SYS_SYM;
    console_doc_exports[i].kind=1;
    if(i==172 || i==18 || i==33 || i==51 || i==69 || i==70 || i==78 || i==118) console_doc_exports[i].kind=3;
    HashAdd(&console_doc_exports[i],task->hash_table);
  }
  display_planes=I386HeapAlloc(config->heap,153600,TRUE);
  if(!display_planes)return FALSE;
  if(!NativeGraphicsStorageReserve) {
    I386HeapFree(config->heap,display_planes);return FALSE;
  }
  console_planes=display_planes;
  console_config=config; dbg.fun_seg_cache=native_fun_seg_cache;
  MusicSettingsRst;
  winmgr.fps=WINMGR_FPS;
  winmgr.ideal_refresh_tS=tS;
  winmgr.last_refresh_tS=winmgr.ideal_refresh_tS;
  NativeBreakpointInstall;
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
  U8 *line=NativeTerminalLine(256);
  I64 length=0,decoded,ch,spaces,
      mouse_x=0,mouse_y=0,mouse_buttons=0,mouse_packets=0,
      next_mouse_x,next_mouse_y,next_mouse_buttons,next_mouse_packets;
  Bool mouse_visible=FALSE;
  I386TextWrite(&console_text,"> "); ConsolePresent;
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
      I386TextWrite(&console_text,"\nInput reset\n> ");
      ConsolePresent;
      KernelLog("INPUT RESET\n");
    } else if(decoded && event.type==2) {
      ch=event.ch;
      if(ch==3) {
        length=0; I386TextWrite(&console_text,"^C\n> ");
        KernelLog("INPUT CANCEL\n");
      } else if(ch==8) {
        if(length) { length--; I386TextPut(&console_text,8); }
      } else if(ch==10) {
        line[length]=0;
        KernelLog("INPUT LINE "); KernelLog(line); KernelLog("\n");
        I386TextPut(&console_text,10); ConsoleSubmit(line);
        length=0; I386TextWrite(&console_text,"> ");
      } else if(ch==9) {
        spaces=8-length%8;
        line=NativeTerminalLine(length+spaces+1);
        while(spaces--) {
          line[length++]=32; I386TextPut(&console_text,32);
        }
      } else if(ch>=32 && ch<=255) {
        line=NativeTerminalLine(length+2);
        line[length++]=ch; I386TextPut(&console_text,ch);
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
#include "/Kernel/I386/ConsoleNumbers.HC"
#include "/Kernel/I386/ConsoleInput.HC"
#include "/Kernel/I386/Debugger.HC"

U0 ConsolePresentText(CI386Text *surface)
{
  I64 rows=I386TextPresent(surface),i;
  U8 message[13],*prefix="VGA ROWS ";
  if(rows<0) KernelStop;
  if(rows) {
    NativeWinRefreshCommit;
    for(i=0;i<9;i++) message[i]=prefix[i];
    message[9]='0'+rows/10; message[10]='0'+rows%10;
    message[11]=10; message[12]=0; KernelLog(message);
  }
}

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

#include "/Kernel/I386/KeyboardMessages.HC"

#include "/Kernel/I386/Terminals.HC"

#include "/Kernel/I386/ServantRuntime.HC"

#include "/Kernel/I386/WindowOrderRuntime.HC"
