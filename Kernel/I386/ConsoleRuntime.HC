//Retained single-owner VGA console and native command input.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/ConsoleRuntime.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/TextVga.HH"
#include "/Kernel/I386/Vga.HH"
#include "/Kernel/I386/Cpu.HH"
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
CI386Text console_text;
U8 *console_planes;
extern U0 ConsolePresent();
extern Bool DocExe(CDoc *doc,I64 flags=0);
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
#include "/Kernel/I386/SoundRuntime.HC"
#include "/Kernel/I386/TextBase.HC"
#include "/Kernel/I386/Window.HC"
U8 *console_title="TempleOS i386\nHolyC console\n\n";
CI386KeyboardState console_hotkeys;
CI386Task *console_break_task;
CI386KernelSymbol console_doc_exports[111];
U32 console_version=I386_CONSOLE_VERSION;
extern Bool NativeGraphicsStart();
extern Bool NativeGraphicsPresent(U0 (*draw)(CDC *dc)=NULL,Bool blink=FALSE);
extern Bool NativeTextBasePresent(Bool blink=FALSE,I64 pan_x=0,I64 pan_y=0,Bool hide_col=FALSE,Bool hide_row=FALSE);
extern U0 NativeTextBaseRestore();
extern Bool ConsoleDisplay();
extern U0 ConsoleKeys(I64 unused);
extern U0 ConsoleSubmit(U8 *line);
extern Bool ConsoleSource(U8 *source,U8 *filename,I64 flags=0);
Bool ConsoleInit(CI386ConsoleConfig *config)
{
  CI386Task *task=I386TaskSelf;
  I64 i;
  if(!task || !task->hash_table || console_config || !config || !config->heap || !config->compiler ||
      config->compiler->version!=I386_COMPILER_SERVICES_VERSION ||
      config->compiler->bytes!=sizeof(CI386CompilerServices) || !config->compiler->input || !config->compiler->break_poll ||
      config->pit_divisor<2 || config->pit_divisor>65536 || !config->files || !config->includes || !config->types || !config->reader || !config->input) return FALSE;
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
  for(i=0;i<111;i++) {
    console_doc_exports[i].type=HTT_EXPORT_SYS_SYM;
    console_doc_exports[i].kind=1;
    if(i==18 || i==33 || i==51 || i==69 || i==70 || i==78) console_doc_exports[i].kind=3;
    HashAdd(&console_doc_exports[i],task->hash_table);
  }
  console_config=config; return TRUE;
}
Bool ConsoleCancelRead(CI386Task *task)
{
  if(!console_config || !console_config->reader) return FALSE;
  return I386KbcInputCancel(console_config->reader->input,task);
}
Bool ConsoleKeyIrq(U8 data,U8 status)
{//Called with IF clear; request only, never allocate, switch or throw here.
  if(!I386KeyboardBreakKey(&console_hotkeys,data,status) || !console_break_task) return FALSE;
  return I386TaskBreakRequest(console_break_task);
}
I64 Main(CI386ConsoleServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386ConsoleServices)) return 0;
  services->version=console_version; services->bytes=bytes;
  services->init=&ConsoleInit; services->display=&ConsoleDisplay; services->keys=&ConsoleKeys;
  services->cancel_read=&ConsoleCancelRead;
  services->cancel_wait=&I386TaskCancelWait; services->key_irq=&ConsoleKeyIrq;
  return 1;
}
Bool ConsoleDisplay()
{
  U8 palette[48];
  I64 color;
  if(!console_config || console_planes) return FALSE;
  console_planes=I386HeapAlloc(console_config->heap,153600,TRUE);
  if(!console_planes) KernelStop;
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
  ConsolePresent;
  return TRUE;
}
U0 ConsoleKeys(I64 unused)
{//Single console/input owner. Each complete line is a recoverable compiler input.
  CI386KeyEvent event;
  U8 line[256];
  I64 length=0,decoded,ch,spaces,header_used,
      mouse_x=0,mouse_y=0,mouse_buttons=0,mouse_packets=0,
      next_mouse_x,next_mouse_y,next_mouse_buttons,next_mouse_packets;
  Bool mouse_visible=FALSE;
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
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
  I386TextWrite(&console_text,"> "); ConsolePresent;
  KernelLog("DONE native kernel startup\n");
  MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets);
  while(1) {
    decoded=I386KeyboardRead(console_config->reader,&event,FALSE);
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
        while(spaces-- && length<255) {
          line[length++]=32; I386TextPut(&console_text,32);
        }
      } else if(ch>=32 && ch<=255 && length<255) {
        line[length++]=ch; I386TextPut(&console_text,ch);
      }
      ConsolePresent;
    }
    if(MouseGet(&next_mouse_x,&next_mouse_y,&next_mouse_buttons,&next_mouse_packets) &&
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
    if(!decoded) { I386SchedYield(I386TaskSelf->owner); I386TaskBreakPoll; }
  }
}


#include "/Kernel/I386/Vga.HC"
#include "/Kernel/I386/Text.HC"
#include "/Kernel/I386/TextVga.HC"
#include "/Kernel/I386/ConsoleNumbers.HC"
#include "/Kernel/I386/ConsoleInput.HC"

U0 ConsolePresent()
{
  I64 rows=I386TextPresent(&console_text),i;
  U8 message[13],*prefix="VGA ROWS ";
  if(rows<0) KernelStop;
  if(rows) {
    for(i=0;i<9;i++) message[i]=prefix[i];
    message[9]='0'+rows/10; message[10]='0'+rows%10;
    message[11]=10; message[12]=0; KernelLog(message);
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
