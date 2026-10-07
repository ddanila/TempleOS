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
#include "/Kernel/I386/BuildModule.HC"
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
  console_doc_exports[0].str="_DOC_LOCK";
  console_doc_exports[0].val=(&I386DocLock+0)(U64);
  console_doc_exports[1].str="_DOC_UNLOCK";
  console_doc_exports[1].val=(&I386DocUnlock+0)(U64);
  console_doc_exports[2].str="_DOC_PUT";
  console_doc_exports[2].val=(&DocPut+0)(U64);
  console_doc_exports[3].str="_DOC_DISPLAY";
  console_doc_exports[3].val=(&DocDisplay+0)(U64);
  console_doc_exports[4].str="_DOC_BORDER";
  console_doc_exports[4].val=(&DocBorder+0)(U64);
  console_doc_exports[5].str="_DOC_EDITABLE";
  console_doc_exports[5].val=(&IsEditableText+0)(U64);
  console_doc_exports[6].str="_DOC_ENTRY_BASE";
  console_doc_exports[6].val=(&DocEntryNewBase+0)(U64);
  console_doc_exports[7].str="_DOC_ENTRY_TAG";
  console_doc_exports[7].val=(&DocEntryNewTag+0)(U64);
  console_doc_exports[8].str="_DOC_ENTRY_SIZE";
  console_doc_exports[8].val=(&DocEntrySize+0)(U64);
  console_doc_exports[9].str="_DOC_ENTRY_COPY";
  console_doc_exports[9].val=(&DocEntryCopy+0)(U64);
  console_doc_exports[10].str="_DOC_FORM_FWD";
  console_doc_exports[10].val=(&DocFormFwd+0)(U64);
  console_doc_exports[11].str="_DOC_FORM_BWD";
  console_doc_exports[11].val=(&DocFormBwd+0)(U64);
  console_doc_exports[12].str="_DOC_DEFAULTS_INIT";
  console_doc_exports[12].val=(&DocDefaultsInit+0)(U64);
  console_doc_exports[13].str="_DOC_INIT";
  console_doc_exports[13].val=(&DocInit+0)(U64);
  console_doc_exports[14].str="_DOC_DICTIONARY_NEW";
  console_doc_exports[14].val=(&DocDictionaryNew+0)(U64);
  console_doc_exports[15].str="_DOC_DICTIONARY_DEL";
  console_doc_exports[15].val=(&DocDictionaryDel+0)(U64);
  console_doc_exports[16].str="_DOC_GLOBALS_INIT";
  console_doc_exports[16].val=(&DocGlobalsInit+0)(U64);
  console_doc_exports[17].str="_DOC_START";
  console_doc_exports[17].val=(&ConsoleDocumentStart+0)(U64);
  console_doc_exports[18].str="doldoc";
  console_doc_exports[18].val=(&doldoc+0)(U64);
  console_doc_exports[19].str="_DOC_REPORT_LITERAL";
  console_doc_exports[19].val=(&DocReportLiteral+0)(U64);
  console_doc_exports[20].str="_DOC_BIN_FIND_NUM";
  console_doc_exports[20].val=(&DocBinFindNum+0)(U64);
  console_doc_exports[21].str="_DOC_BIN_FIND_TAG";
  console_doc_exports[21].val=(&DocBinFindTag+0)(U64);
  console_doc_exports[22].str="_DOC_BINS_VALIDATE";
  console_doc_exports[22].val=(&DocBinsValidate+0)(U64);
  console_doc_exports[23].str="_DOC_BIN_DEL";
  console_doc_exports[23].val=(&DocBinDel+0)(U64);
  console_doc_exports[24].str="_DOC_ENTRY_DEL";
  console_doc_exports[24].val=(&DocEntryDel+0)(U64);
  console_doc_exports[25].str="_DOC_UNDO_DEL";
  console_doc_exports[25].val=(&DocUndoDel+0)(U64);
  console_doc_exports[26].str="_DOC_UNDO_COUNT";
  console_doc_exports[26].val=(&DocUndoCntSet+0)(U64);
  console_doc_exports[27].str="_DOC_REM_SOFT";
  console_doc_exports[27].val=(&DocRemSoftNewLines+0)(U64);
  console_doc_exports[28].str="_DOC_INS_ENTRY";
  console_doc_exports[28].val=(&DocInsEntry+0)(U64);
  NativeTextBaseInit;
  console_doc_exports[29].str="_TEXT_CHAR";
  console_doc_exports[29].val=(&TextChar+0)(U64);
  console_doc_exports[30].str="_TEXT_LEN_STR";
  console_doc_exports[30].val=(&TextLenStr+0)(U64);
  console_doc_exports[31].str="_TEXT_LEN_ATTR_STR";
  console_doc_exports[31].val=(&TextLenAttrStr+0)(U64);
  console_doc_exports[32].str="_TEXT_LEN_ATTR";
  console_doc_exports[32].val=(&TextLenAttr+0)(U64);
  console_doc_exports[33].str="i386_text_base";
  console_doc_exports[33].val=(&i386_text_base+0)(U64);
  console_doc_exports[34].str="_TEXT_BASE_PRESENT";
  console_doc_exports[34].val=(&NativeTextBasePresent+0)(U64);
  console_doc_exports[35].str="_TEXT_BASE_RESTORE";
  console_doc_exports[35].val=(&NativeTextBaseRestore+0)(U64);
  console_doc_exports[36].str="_LIST_SUB";
  console_doc_exports[36].val=(&LstSub+0)(U64);
  console_doc_exports[37].str="_LIST_MATCH";
  console_doc_exports[37].val=(&LstMatch+0)(U64);
  console_doc_exports[38].str="_DEFINE";
  console_doc_exports[38].val=(&Define+0)(U64);
  console_doc_exports[39].str="_DEFINE_SUB";
  console_doc_exports[39].val=(&DefineSub+0)(U64);
  console_doc_exports[40].str="_DEFINE_COUNT";
  console_doc_exports[40].val=(&DefineCnt+0)(U64);
  console_doc_exports[41].str="_DEFINE_MATCH";
  console_doc_exports[41].val=(&DefineMatch+0)(U64);
  console_doc_exports[42].str="_YEAR_START_DATE";
  console_doc_exports[42].val=(&YearStartDate+0)(U64);
  console_doc_exports[43].str="_STRUCT_TO_DATE";
  console_doc_exports[43].val=(&Struct2Date+0)(U64);
  console_doc_exports[44].str="_DAY_OF_WEEK";
  console_doc_exports[44].val=(&DayOfWeek+0)(U64);
  console_doc_exports[45].str="_DATE_TO_STRUCT";
  console_doc_exports[45].val=(&Date2Struct+0)(U64);
  console_doc_exports[46].str="_FIRST_DAY_MONTH";
  console_doc_exports[46].val=(&FirstDayOfMon+0)(U64);
  console_doc_exports[47].str="_LAST_DAY_MONTH";
  console_doc_exports[47].val=(&LastDayOfMon+0)(U64);
  console_doc_exports[48].str="_FIRST_DAY_YEAR";
  console_doc_exports[48].val=(&FirstDayOfYear+0)(U64);
  console_doc_exports[49].str="_LAST_DAY_YEAR";
  console_doc_exports[49].val=(&LastDayOfYear+0)(U64);
  console_doc_exports[50].str="_BCD_TO_BIN";
  console_doc_exports[50].val=(&Bcd2Bin+0)(U64);
  console_doc_exports[51].str="local_time_offset";
  console_doc_exports[51].val=(&local_time_offset+0)(U64);
  console_doc_exports[52].str="_MAT4X4MULXYZ";
  console_doc_exports[52].val=(&Mat4x4MulXYZ+0)(U64);
  console_doc_exports[53].str="_DCTRANSFORM";
  console_doc_exports[53].val=(&DCTransform+0)(U64);
  console_doc_exports[54].str="_MAT4X4IDENTEQU";
  console_doc_exports[54].val=(&Mat4x4IdentEqu+0)(U64);
  console_doc_exports[55].str="_MAT4X4IDENTNEW";
  console_doc_exports[55].val=(&Mat4x4IdentNew+0)(U64);
  console_doc_exports[56].str="_MAT4X4NORMSQR65536";
  console_doc_exports[56].val=(&Mat4x4NormSqr65536+0)(U64);
  console_doc_exports[57].str="_DCMAT4X4SET";
  console_doc_exports[57].val=(&DCMat4x4Set+0)(U64);
  console_doc_exports[58].str="_DCLIGHTING";
  console_doc_exports[58].val=(&DCLighting+0)(U64);
  console_doc_exports[59].str="_DCFILL";
  console_doc_exports[59].val=(&DCFill+0)(U64);
  console_doc_exports[60].str="_DCCLEAR";
  console_doc_exports[60].val=(&DCClear+0)(U64);
  console_doc_exports[61].str="_DCRST";
  console_doc_exports[61].val=(&DCRst+0)(U64);
  console_doc_exports[62].str="_DCEXTENTSINIT";
  console_doc_exports[62].val=(&DCExtentsInit+0)(U64);
  console_doc_exports[63].str="_DCALIAS";
  console_doc_exports[63].val=(&DCAlias+0)(U64);
  console_doc_exports[64].str="_DCNEW";
  console_doc_exports[64].val=(&DCNew+0)(U64);
  console_doc_exports[65].str="_DCDEL";
  console_doc_exports[65].val=(&DCDel+0)(U64);
  console_doc_exports[66].str="_DCSIZE";
  console_doc_exports[66].val=(&DCSize+0)(U64);
  console_doc_exports[67].str="_DCDEPTHBUFRST";
  console_doc_exports[67].val=(&DCDepthBufRst+0)(U64);
  console_doc_exports[68].str="_DCDEPTHBUFALLOC";
  console_doc_exports[68].val=(&DCDepthBufAlloc+0)(U64);
  console_doc_exports[69].str="gr";
  console_doc_exports[69].val=(&gr+0)(U64);
  console_doc_exports[70].str="gr_palette_std";
  console_doc_exports[70].val=(&gr_palette_std+0)(U64);
  console_doc_exports[71].str="_GRAPHICS_START";
  console_doc_exports[71].val=(&NativeGraphicsStart+0)(U64);
  console_doc_exports[72].str="_GRAPHICS_PRESENT";
  console_doc_exports[72].val=(&NativeGraphicsPresent+0)(U64);
  console_doc_exports[73].str="_TEXT_BORDER";
  console_doc_exports[73].val=(&TextBorder+0)(U64);
  console_doc_exports[74].str="_TEXT_RECT";
  console_doc_exports[74].val=(&TextRect+0)(U64);
  console_doc_exports[75].str="_WIN_SCROLL_NULL";
  console_doc_exports[75].val=(&WinScrollNull+0)(U64);
  console_doc_exports[76].str="_WIN_SCROLL_RESTORE";
  console_doc_exports[76].val=(&WinScrollRestore+0)(U64);
  console_doc_exports[77].str="_WIN_DERIVED_VALS_UPDATE";
  console_doc_exports[77].val=(&WinDerivedValsUpdate+0)(U64);
  console_doc_exports[78].str="text";
  console_doc_exports[78].val=(&text+0)(U64);
  console_doc_exports[79].str="_TASK_VALIDATE";
  console_doc_exports[79].val=(&TaskValidate+0)(U64);
  console_doc_exports[80].str="_TASK_DERIVED_VALS_UPDATE";
  console_doc_exports[80].val=(&TaskDerivedValsUpdate+0)(U64);
  console_doc_exports[81].str="_WIN_HORZ";
  console_doc_exports[81].val=(&WinHorz+0)(U64);
  console_doc_exports[82].str="_WIN_VERT";
  console_doc_exports[82].val=(&WinVert+0)(U64);
  console_doc_exports[83].str="_CTRL_FIND_UNIQUE";
  console_doc_exports[83].val=(&CtrlFindUnique+0)(U64);
  console_doc_exports[84].str="_CTRLS_UPDATE";
  console_doc_exports[84].val=(&CtrlsUpdate+0)(U64);
  console_doc_exports[85].str="_CTRL_INSIDE";
  console_doc_exports[85].val=(&CtrlInside+0)(U64);
  console_doc_exports[86].str="_WIN_Z_BUF_UPDATE";
  console_doc_exports[86].val=(&WinZBufUpdate+0)(U64);
  console_doc_exports[87].str="_WIN_INSIDE";
  console_doc_exports[87].val=(&WinInside+0)(U64);
  console_doc_exports[88].str="_DOC_NEW";
  console_doc_exports[88].val=(&DocNew+0)(U64);
  console_doc_exports[89].str="_DOC_RST";
  console_doc_exports[89].val=(&DocRst+0)(U64);
  console_doc_exports[90].str="_DOC_DEL";
  console_doc_exports[90].val=(&DocDel+0)(U64);
  console_doc_exports[91].str="_DOC_SIZE";
  console_doc_exports[91].val=(&DocSize+0)(U64);
  console_doc_exports[92].str="_DOC_PUT_KEY";
  console_doc_exports[92].val=(&DocPutKey+0)(U64);
  console_doc_exports[93].str="_DOC_SAVE";
  console_doc_exports[93].val=(&DocSave+0)(U64);
  console_doc_exports[94].str="_DOC_WRITE";
  console_doc_exports[94].val=(&DocWrite+0)(U64);
  console_doc_exports[95].str="_DOC_READ";
  console_doc_exports[95].val=(&DocRead+0)(U64);
  console_doc_exports[96].str="_DOC_ED";
  console_doc_exports[96].val=(&DocEd+0)(U64);
  console_doc_exports[97].str="_DOC_ALLOCATION_CHECK";
  console_doc_exports[97].val=(&DocAllocationCheck+0)(U64);
  console_doc_exports[98].str="_DOC_EXE";
  console_doc_exports[98].val=(&DocExe+0)(U64);
  console_doc_exports[99].str="_DIR_MK";
  console_doc_exports[99].val=(&DirMk+0)(U64);
  console_doc_exports[100].str="_ED";
  console_doc_exports[100].val=(&Ed+0)(U64);
  console_doc_exports[101].str="_DIR";
  console_doc_exports[101].val=(&Dir+0)(U64);
  console_doc_exports[102].str="_ED_DIR";
  console_doc_exports[102].val=(&EdDir+0)(U64);
  console_doc_exports[103].str="_FILE_DEL";
  console_doc_exports[103].val=(&FileDel+0)(U64);
  console_doc_exports[104].str="_FILE_RENAME";
  console_doc_exports[104].val=(&FileRename+0)(U64);
  console_doc_exports[105].str="_DIR_DEL";
  console_doc_exports[105].val=(&DirDel+0)(U64);
  console_doc_exports[106].str="_FILE_MOVE";
  console_doc_exports[106].val=(&FileMove+0)(U64);
  console_doc_exports[107].str="_HELP";
  console_doc_exports[107].val=(&Help+0)(U64);
  console_doc_exports[108].str="_SND";
  console_doc_exports[108].val=(&Snd+0)(U64);
  console_doc_exports[109].str="_SND_RST";
  console_doc_exports[109].val=(&SndRst+0)(U64);
  console_doc_exports[110].str="_MOUSE_GET";
  console_doc_exports[110].val=(&MouseGet+0)(U64);
  console_doc_exports[111].str="_I386_INSTALL_TREE";
  console_doc_exports[111].val=(&I386InstallTree+0)(U64);
  console_doc_exports[112].str="_I386_INSTALL_BOOT";
  console_doc_exports[112].val=(&I386InstallBoot+0)(U64);
  console_doc_exports[113].str="_I386_BUILD_MODULE";
  console_doc_exports[113].val=(&I386BuildModule+0)(U64);
  console_doc_exports[114].str="_I386_BUILD_BOOT_IMAGE";
  console_doc_exports[114].val=(&I386BuildBootImage+0)(U64);
  console_doc_exports[115].str="_I386_INSTALL_BOOT_IMAGE";
  console_doc_exports[115].val=(&I386InstallBootImage+0)(U64);
  console_doc_exports[116].str="_EXE_DOC";
  console_doc_exports[116].val=(&ExeDoc+0)(U64);
  console_doc_exports[117].str="_I386_JOB_SOURCE";
  console_doc_exports[117].val=(&NativeJobSource+0)(U64);
  console_doc_exports[118].str="_SYS_FOCUS_TASK";
  console_doc_exports[118].val=(&sys_focus_task+0)(U64);
  console_doc_exports[119].str="_DBG";
  console_doc_exports[119].val=(&NativeDebug+0)(U64);
  console_doc_exports[120].str="_DEBUG_GO";
  console_doc_exports[120].val=(&NativeDebugGo+0)(U64);
  console_doc_exports[121].str="_DBG_MODE";
  console_doc_exports[121].val=(&NativeDebugMode+0)(U64);
  console_doc_exports[122].str="_IS_DBG_MODE";
  console_doc_exports[122].val=(&NativeIsDebugMode+0)(U64);
  console_doc_exports[123].str="_USER_CMD_LINE";
  console_doc_exports[123].val=(&NativeUserCmdLine+0)(U64);
  console_doc_exports[124].str="_USER_TASK_CONT";
  console_doc_exports[124].val=(&NativeUserTaskCont+0)(U64);
  console_doc_exports[125].str="_WIN_FOCUS";
  console_doc_exports[125].val=(&NativeWinFocus+0)(U64);
  console_doc_exports[126].str="_IS_RAW";
  console_doc_exports[126].val=(&IsRaw+0)(U64);
  console_doc_exports[127].str="_STR_PRINT_JOIN";
  console_doc_exports[127].val=(&StrPrintJoin+0)(U64);
  console_doc_exports[128].str="_STR_PRINT";
  console_doc_exports[128].val=(&StrPrint+0)(U64);
  console_doc_exports[129].str="_CAT_PRINT";
  console_doc_exports[129].val=(&CatPrint+0)(U64);
  console_doc_exports[130].str="_MSTR_PRINT";
  console_doc_exports[130].val=(&MStrPrint+0)(U64);
  console_doc_exports[131].str="_USER";
  console_doc_exports[131].val=(&NativeUser+0)(U64);
  console_doc_exports[132].str="_XTALK";
  console_doc_exports[132].val=(&NativeXTalk+0)(U64);
  console_doc_exports[133].str="_TASK_WAIT";
  console_doc_exports[133].val=(&NativeTaskWait+0)(U64);
  console_doc_exports[134].str="_FILE_WRITE";
  console_doc_exports[134].val=(&FileWrite+0)(U64);
  console_doc_exports[135].str="_FILE_READ";
  console_doc_exports[135].val=(&NativePublicFileRead+0)(U64);
  console_doc_exports[136].str="_FILE_FIND";
  console_doc_exports[136].val=(&FileFind+0)(U64);
  console_doc_exports[137].str="_CD";
  console_doc_exports[137].val=(&Cd+0)(U64);
  console_doc_exports[138].str="_DEBUG_STEP";
  console_doc_exports[138].val=(&NativeDebugStep+0)(U64);
  console_doc_exports[139].str="_TASK_REG_ADDR";
  console_doc_exports[139].val=(&TaskRegAddr+0)(U64);
  console_doc_exports[140].str="_BPT_FIND";
  console_doc_exports[140].val=(&BptFind+0)(U64);
  console_doc_exports[141].str="_BPT_SET";
  console_doc_exports[141].val=(&BptS+0)(U64);
  console_doc_exports[142].str="_BPT_REMOVE";
  console_doc_exports[142].val=(&BptR+0)(U64);
  console_doc_exports[143].str="_BPT_TOGGLE";
  console_doc_exports[143].val=(&B+0)(U64);
  console_doc_exports[144].str="_BPT_CLEAR";
  console_doc_exports[144].val=(&B2+0)(U64);
  console_doc_exports[145].str="_DEBUG_GO_CLEAR";
  console_doc_exports[145].val=(&NativeDebugGoClear+0)(U64);
  console_doc_exports[146].str="_CALLER";
  console_doc_exports[146].val=(&NativeCaller+0)(U64);
  console_doc_exports[147].str="_SYS_MACRO_2_STR";
  console_doc_exports[147].val=(&SysMacro2Str+0)(U64);
  console_doc_exports[148].str="_SYS_MACRO_STRIP_KEY";
  console_doc_exports[148].val=(&SysMacroStripKey+0)(U64);
  console_doc_exports[149].str="_PRINT";
  console_doc_exports[149].val=(&NativePrint+0)(U64);
  console_doc_exports[150].str="_PUT_S";
  console_doc_exports[150].val=(&NativePutS+0)(U64);
  console_doc_exports[151].str="_PUT_CHARS";
  console_doc_exports[151].val=(&NativePutChars+0)(U64);
  console_doc_exports[152].str="_TASK_TEXT";
  console_doc_exports[152].val=(&NativeTaskText+0)(U64);
  console_doc_exports[153].str="_IN_STR";
  console_doc_exports[153].val=(&InStr+0)(U64);
  console_doc_exports[154].str="_XTALK_STR_WAIT";
  console_doc_exports[154].val=(&XTalkStrWait+0)(U64);
  console_doc_exports[155].str="_PLAY_SYS_MACRO";
  console_doc_exports[155].val=(&PlaySysMacro+0)(U64);
  console_doc_exports[156].str="_STR_SCAN";
  console_doc_exports[156].val=(&StrScan+0)(U64);
  console_doc_exports[157].str="_STR_TO_I64";
  console_doc_exports[157].val=(&Str2I64+0)(U64);
  console_doc_exports[158].str="_STR_TO_F64";
  console_doc_exports[158].val=(&Str2F64+0)(U64);
  console_doc_exports[159].str="_STR_TO_DATE";
  console_doc_exports[159].val=(&Str2Date+0)(U64);
  console_doc_exports[160].str="_DOC_DOLLAR";
  console_doc_exports[160].val=(&PrsDollarCmd+0)(U64);
  console_doc_exports[161].str="_DOC_DATA_FMT";
  console_doc_exports[161].val=(&DocDataFmt+0)(U64);
  console_doc_exports[162].str="_DOC_DATA_SCAN";
  console_doc_exports[162].val=(&DocDataScan+0)(U64);
  console_doc_exports[163].str="_DOC_PUT_S";
  console_doc_exports[163].val=(&DocPutS+0)(U64);
  console_doc_exports[164].str="_DOC_PRINT";
  console_doc_exports[164].val=(&DocPrint+0)(U64);
  console_doc_exports[165].str="_IN";
  console_doc_exports[165].val=(&In+0)(U64);
  console_doc_exports[166].str="_JOB_RES_SCAN";
  console_doc_exports[166].val=(&JobResScan+0)(U64);
  console_doc_exports[167].str="_JOB_DEL";
  console_doc_exports[167].val=(&JobDel+0)(U64);
  console_doc_exports[168].str="_TASK_EXE";
  console_doc_exports[168].val=(&NativeTaskExe+0)(U64);
  console_doc_exports[169].str="_SRV_TASK_CONT";
  console_doc_exports[169].val=(&NativeSrvTaskCont+0)(U64);
  console_doc_exports[170].str="_SRV_CMD_LINE";
  console_doc_exports[170].val=(&NativeSrvCmdLine+0)(U64);
  sys_winmgr_task=task;
  console_doc_exports[171].str="_WIN_TO_TOP";
  console_doc_exports[171].val=(&NativeWinToTop+0)(U64);
  console_doc_exports[172].str="_SYS_WINMGR_TASK";
  console_doc_exports[172].val=(&sys_winmgr_task+0)(U64);
  console_doc_exports[173].str="_DOC_BORDER_NEW";
  console_doc_exports[173].val=(&DocBorderNew+0)(U64);
  console_doc_exports[174].str="_ED_OVERSTRIKE_CB";
  console_doc_exports[174].val=(&EdOverStrikeCB+0)(U64);
  console_doc_exports[175].str="_ED_AUTO_SAVE_CB";
  console_doc_exports[175].val=(&EdAutoSaveCB+0)(U64);
  console_doc_exports[176].str="_ED_FILTER_CB";
  console_doc_exports[176].val=(&EdFilterCB+0)(U64);
  console_doc_exports[177].str="_ED_DOLLAR_CB";
  console_doc_exports[177].val=(&EdDollarCB+0)(U64);
  console_doc_exports[178].str="_ED_MORE_CB";
  console_doc_exports[178].val=(&EdMoreCB+0)(U64);
  console_doc_exports[179].str="_ED_DOLLAR_TYPE_CB";
  console_doc_exports[179].val=(&EdDollarTypeCB+0)(U64);
  console_doc_exports[180].str="_MENU_NEW";
  console_doc_exports[180].val=(&NativeMenuNew+0)(U64);
  console_doc_exports[181].str="_MENU_FILE";
  console_doc_exports[181].val=(&MenuFile+0)(U64);
  console_doc_exports[182].str="_MENU_ENTRY_FIND";
  console_doc_exports[182].val=(&MenuEntryFind+0)(U64);
  console_doc_exports[183].str="_MENU_SUB_ENTRY_FIND";
  console_doc_exports[183].val=(&MenuSubEntryFind+0)(U64);
  console_doc_exports[184].str="_MENU_DEL";
  console_doc_exports[184].val=(&MenuDel+0)(U64);
  console_doc_exports[185].str="_GR_RECT";
  console_doc_exports[185].val=(&GrRect+0)(U64);
  console_doc_exports[186].str="_RAND_U16";
  console_doc_exports[186].val=(&RandU16+0)(U64);
  console_doc_exports[187].str="_DIST_SQR_I64";
  console_doc_exports[187].val=(&DistSqrI64+0)(U64);
  console_doc_exports[188].str="_WIN_SCROLLS_INIT";
  console_doc_exports[188].val=(&WinScrollsInit+0)(U64);
  console_doc_exports[189].str="_RAW";
  console_doc_exports[189].val=(&Raw+0)(U64);
  console_doc_exports[190].str="_VGA_FLUSH";
  console_doc_exports[190].val=(&VGAFlush+0)(U64);
  console_doc_exports[191].str="_DOC_ENTRY_LINK";
  console_doc_exports[191].val=(&DocEntryLink+0)(U64);
  console_doc_exports[192].str="_FILE_NAME_ABS";
  console_doc_exports[192].val=(&FileNameAbs+0)(U64);
  console_doc_exports[193].str="_SRC_LINE_NUM";
  console_doc_exports[193].val=(&SrcLineNum+0)(U64);
  console_doc_exports[194].str="_SRC_FILE_NAME";
  console_doc_exports[194].val=(&SrcFileName+0)(U64);
  console_doc_exports[195].str="_SRC_ED_LINK";
  console_doc_exports[195].val=(&SrcEdLink+0)(U64);
  console_doc_exports[196].str="_EXE_PUTS";
  console_doc_exports[196].val=(&ExePutS+0)(U64);
  console_doc_exports[197].str="_EXE_PRINT";
  console_doc_exports[197].val=(&ExePrint+0)(U64);
  console_doc_exports[198].str="_DEFINE_LOAD";
  console_doc_exports[198].val=(&DefineLoad+0)(U64);
  console_doc_exports[199].str="_DEFINE_PRINT";
  console_doc_exports[199].val=(&DefinePrint+0)(U64);
  console_doc_exports[200].str="_BIBLE_INIT";
  console_doc_exports[200].val=(&BibleInit+0)(U64);
  console_doc_exports[201].str="_ED_LINK_CVT";
  console_doc_exports[201].val=(&EdLinkCvt+0)(U64);
  console_doc_exports[202].str="_DOC_LINK_FILE";
  console_doc_exports[202].val=(&DocLinkFile+0)(U64);
  console_doc_exports[203].str="_DRV_CHECK";
  console_doc_exports[203].val=(&DrvChk+0)(U64);
  console_doc_exports[204].str="_DRV_TO_LET";
  console_doc_exports[204].val=(&Drv2Let+0)(U64);
  console_doc_exports[205].str="_LET_TO_LET";
  console_doc_exports[205].val=(&Let2Let+0)(U64);
  console_doc_exports[206].str="_LET_TO_BLOCK_DEV_TYPE";
  console_doc_exports[206].val=(&Let2BlkDevType+0)(U64);
  console_doc_exports[207].str="_DRV_TEXT_ATTR_GET";
  console_doc_exports[207].val=(&DrvTextAttrGet+0)(U64);
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
