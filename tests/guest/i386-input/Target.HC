#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/Kbc.HH"
#include "/Kernel/I386/KbcInput.HH"
#include "/Kernel/I386/Irq.HH"
#include "/Kernel/I386/ScanSet1.HH"
#include "/Kernel/I386/ScanChar.HH"
#include "/Kernel/I386/KeyboardSetup.HH"
#include "/Kernel/I386/ScanState.HH"
#include "/Kernel/I386/KeyboardEvent.HH"
extern I64 EventTest();
extern I64 StateTest();
extern Bool StateCheck(U32 raw,U32 expected);
CI386ScanState key_state;
U8 char_oracle[2560];
extern I64 CharTest();
extern U8 *StringTestValue();
extern I64 ScanTest();
extern I64 LiveKeys();
extern U0 LiveReader(I64 unused);
U32 live_events;
extern U0 I386PicInit();
extern U0 I386PicMask(U16 mask);
extern Bool I386PicAccept(I64 irq);
extern Bool I386PicEoi(I64 irq);
class CDispatch { U0 (*handler)(CI386IrqFrame *frame); };
class CControl {
  CDispatch *irq; U0 (*idle)(); I64 (*segments)(I64 callback);
  U0 (*reload)(U16 fs,U16 gs); U8 *task_descriptor,*cpu_descriptor;
};
CI386Scheduler scheduler;
CI386Task tasks[3];
CI386KbcInput input,uninitialized;
CControl *control;
U32 errors,received,interrupts,competitors;
extern U0 Reader(I64 id);
extern U0 EndTask();
extern U0 OnKeyboard(CI386IrqFrame *frame);
I64 Main(I64 a,I64 b)
{
  U0 (*swap)(CI386Context *old,CI386Context *next);
  U8 config,data=0x55,status=0xAA;
  I64 i,result;
  control=a; swap=b;
  result=ScanTest;
  if (result) return 100+result;
  result=CharTest;
  if (result) return result;
  result=StateTest;
  if (result) return result;
  result=EventTest;
  if (result) return result;
  I386PicInit;
  if (!I386SchedInit(&scheduler,&tasks[0],swap) ||
      I386KbcInputInit(0,&scheduler) || I386KbcInputInit(&input,0) ||
      !I386KbcInputInit(&input,&scheduler) || I386KbcInputInit(&input,&scheduler)) return 1;
  if (I386KbcInputPut(&uninitialized,1,1) ||
      I386KbcInputRead(&uninitialized,&data,&status) ||
      I386KbcInputRead(&input,&data,&status) || data!=0x55 || status!=0xAA) return 2;
  if (!I386KbcInputPut(&input,0x33,0xE1) ||
      I386KbcInputRead(&input,0,&status) || I386KbcInputRead(&input,&data,0) ||
      I386KbcInputRead(&input,&data,&data) || input.queue.count!=1) return 3;
  for (i=1;i<=2;i++)
    if (!I386ContextInit(&tasks[i].context,0x50000+i*8192,8192,&Reader,i,&EndTask) ||
        !I386SchedAdd(&scheduler,&tasks[i])) return 4;
  if (!I386SchedYield(&scheduler) || errors || !tasks[1].blocked ||
      !tasks[2].finished || competitors!=1 || input.waiter!=&tasks[1]) return 5;
  //An unrelated wake must return to waiting without consuming phantom data.
  if (!I386SchedWake(&scheduler,&tasks[1]) || !I386SchedYield(&scheduler) ||
      !tasks[1].blocked || received || errors) return 6;
  if (!I386KbcDrain || !I386KbcWrite(TRUE,0x20) ||
      !I386KbcReadWait(&config,&status) || (status&0xE0)) return 7;
  if (I386KeyboardSetup(0) || I386KeyboardSetup(-1) || I386KeyboardSetup(100001) ||
      I386KeyboardCommand(0xF5,0) || I386KeyboardCommand(0xF5,100001) ||
      I386KeyboardCommand(0xF5,100000,0) || I386KeyboardCommand(0xF5,100000,4)) return 15;
  if (!I386KeyboardSetup || !I386KbcWrite(TRUE,0x20) ||
      !I386KbcReadWait(&data,&status) || (status&0xE0) || (data&0x73)!=0x61) return 16;
  //Query scan set 2: translation maps the returned 02 byte to 41.
  if (!I386KeyboardCommand(0xF0) || !I386KeyboardCommand(0) ||
      !I386KbcReadWait(&data,&status) || (status&0xE0) || data!=0x41) return 17;
  //QEMU answers unsupported command 05 with RESEND; echo is not an ACK.
  if (I386KeyboardCommand(0x05) || I386KeyboardCommand(0xEE) ||
      !I386KeyboardCommand(0xF4) || (GetRFlags&0x200)) return 18;
  I386PicInit; control->irq->handler=&OnKeyboard;
  for (i=0;i<4;i++) {
    if (!tasks[1].blocked || !I386KbcWrite(FALSE,0xEE)) return 8;
    I386PicMask(0xFFFD);
    if (!I386SchedIdle(&scheduler,control->idle) || (GetRFlags&0x200)) return 9;
    I386PicMask(0xFFFF);
    if (tasks[1].blocked || scheduler.current!=&tasks[0] ||
        interrupts!=i+1 || input.queue.count!=1 || received!=i) return 10;
    //A second publication while the reader is runnable must remain queued.
    if (!I386KbcInputPut(&input,0x40+i,0xA1) || input.queue.count!=2) return 14;
    //Root cannot steal a byte reserved for the registered reader.
    data=0x55; status=0xAA;
    if (I386KbcInputRead(&input,&data,&status,FALSE) || data!=0x55 || status!=0xAA ||
        !I386SchedYield(&scheduler) || received!=i+1 || errors) return 11;
  }
  if (!tasks[1].finished || input.waiter || input.queue.count || input.queue.dropped ||
      !I386SchedReap(&scheduler,&tasks[1]) || !I386SchedReap(&scheduler,&tasks[2])) return 12;
  result=LiveKeys;
  if (result) return result;
  if (!I386KbcWrite(TRUE,0x60) || !I386KbcWrite(FALSE,config) ||
      !I386KbcWrite(TRUE,0x20) || !I386KbcReadWait(&data,&status) || data!=config ||
      (status&0xE0)) return 13;
  return errors;
}
U0 Reader(I64 id)
{
  U8 data=0x55,status=0xAA;
  I64 i;
  SetRFlags(GetRFlags|0x200);
  if (id==2) {
    if (I386KbcInputRead(&input,&data,&status) || data!=0x55 || status!=0xAA ||
        !(GetRFlags&0x200)) errors++;
    competitors++; return;
  }
  if (!I386KbcInputRead(&input,&data,&status) || data!=0x33 || status!=0xE1 ||
      I386KbcInputRead(&input,&data,&status,FALSE) || !(GetRFlags&0x200)) errors++;
  for (i=0;i<4;i++) {
    if (!I386KbcInputRead(&input,&data,&status) || data!=0xEE || (status&0xE0) ||
        !(GetRFlags&0x200) || scheduler.current!=&tasks[1] || input.waiter) errors++;
    if (!I386KbcInputRead(&input,&data,&status) || data!=0x40+i || status!=0xA1 ||
        !(GetRFlags&0x200)) errors++;
    received++;
  }
}
U0 EndTask() { I386SchedFinish(&scheduler); while (TRUE) {} }
I64 LiveKeys()
{
  I64 i;
  U8 *p;
  if (!I386ContextInit(&tasks[1].context,0x52000,8192,&LiveReader,0,&EndTask) ||
      !I386SchedAdd(&scheduler,&tasks[1]) || !I386SchedYield(&scheduler) ||
      !tasks[1].blocked) return 20;
  for (i=0;i<9;i++) {
    p="KEY "; while (*p) OutU8(0xE9,*p++);
    OutU8(0xE9,'0'+i); OutU8(0xE9,10);
    while (live_events==i && !tasks[1].finished) {
      I386PicMask(0xFFFD);
      I386SchedIdle(&scheduler,control->idle);
      I386PicMask(0xFFFF);
      if (!I386SchedYield(&scheduler) || (GetRFlags&0x200)) return 21;
    }
    if (live_events!=i+1 || errors) return 22;
  }
  if (!tasks[1].finished || input.waiter || input.queue.count || input.queue.dropped ||
      !I386SchedReap(&scheduler,&tasks[1])) return 23;
  return 0;
}
U0 LiveReader(I64 unused)
{
  CI386KeyboardState state;
  CI386KeyEvent event;
  U32 scan,expected[9];
  U8 data,status,ch;
  I64 decoded;
  expected[0]=0x1E; expected[1]=0x11E; expected[2]=0x1C; expected[3]=0x11C;
  expected[4]=0xC8; expected[5]=0x1C8; expected[6]=0xB7; expected[7]=0x1B7;
  expected[8]=0x61;
  I386KeyboardReset(&state);
  SetRFlags(GetRFlags|0x200);
  while (live_events<9) {
    if (!I386KbcInputRead(&input,&data,&status) || !(GetRFlags&0x200)) { errors++; return; }
    decoded=I386KeyboardFeed(&state,data,status,&event);
    if (decoded<0) { errors++; return; }
    if (decoded) {
      scan=expected[live_events];
      if ((event.scan>>32)!=scan || (event.scan&0x0000800000008000) ||
          event.type!=2+((scan>>8)&1)) { errors++; return; }
      ch=event.ch;
      if (live_events<2) { if (ch!='a') errors++; }
      else if (live_events<4) { if (ch!=10) errors++; }
      else if (ch) errors++;
      live_events++;
    }
  }
}
U0 OnKeyboard(CI386IrqFrame *frame)
{
  U8 data,status;
  if (!I386PicAccept(frame->irq)) return;
  if (frame->irq!=1 || (GetRFlags&0x600) || !(frame->eflags&0x200) ||
      scheduler.current!=&tasks[0]) errors++;
  if (!I386KbcRead(&data,&status) || !I386KbcInputPut(&input,data,status) ||
      scheduler.current!=&tasks[0] || (GetRFlags&0x200)) errors++;
  interrupts++; I386PicEoi(frame->irq);
}
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/KbcQueue.HC"
#include "/Kernel/I386/KbcInput.HC"
#include "/Kernel/I386/Kbc.HC"
#include "/Kernel/I386/PicPit.HC"
#include "/Kernel/I386/ScanSet1.HC"
#include "/Kernel/I386/ScanChar.HC"
#include "/Kernel/I386/KeyboardSetup.HC"
#include "/Kernel/I386/ScanState.HC"
#include "/Kernel/I386/KeyboardEvent.HC"

I64 EventTest()
{
  CI386KeyboardState state;
  CI386KeyEvent event;
  I386KeyboardReset(&state);
  event.type=99; event.ch=98; event.scan=97;
  if (I386KeyboardFeed(0,1,1,&event)!=-1 || I386KeyboardFeed(&state,1,1,0)!=-1 ||
      I386KeyboardFeed(&state,0xE0,1,&event) || event.type!=99 || event.ch!=98 || event.scan!=97)
    return 170;
  I386KeyboardReset(&state);
  if (I386KeyboardFeed(&state,0x2A,1,&event)!=1 || event.type!=2 || event.ch ||
      event.scan!=0x22A0000022A) return 171;
  if (I386KeyboardFeed(&state,0x2A,1,&event) || event.scan!=0x22A0000022A ||
      I386KeyboardFeed(&state,0x1E,1,&event)!=1 || event.ch!='A' || event.type!=2 ||
      event.scan!=0x21E0000021E) return 172;
  if (I386KeyboardFeed(&state,0x9E,1,&event)!=1 || event.ch!='A' || event.type!=3 ||
      event.scan!=0x31E0000031E) return 173;
  if (I386KeyboardFeed(&state,0x1E,0x81,&event)!=-1 || event.scan!=0x31E0000031E ||
      state.keys.down[0x2A] || I386KeyboardFeed(&state,0x1E,1,&event)!=1 || event.ch!='a')
    return 174;
  if (I386KeyboardFeed(&state,0x1D,1,&event)!=1 ||
      I386KeyboardFeed(&state,0x2E,1,&event)!=1 || event.ch!=3 || event.type!=2) return 175;
  return 0;
}

Bool StateCheck(U32 raw,U32 expected)
{
  I64 event;
  if (!I386ScanStateApply(&key_state,raw,&event)) return FALSE;
  return (event&0xFFFFFFFF)==expected && (event>>32)==((expected&~0x1FF)|raw);
}
I64 StateTest()
{
  I64 i,event=0x123456789ABCDEF0;
  for (i=0;i<256;i++)
    if (I386ScanMap(i)!=char_oracle[2048+i] ||
        I386ScanMap(i,TRUE)!=char_oracle[2304+i]) return 150;
  I386ScanStateReset(&key_state);
  if (!StateCheck(0x2A,0x822A) || !StateCheck(0x36,0x022A) ||
      !StateCheck(0x12A,0x832A) || !StateCheck(0x1E,0x821E) ||
      !StateCheck(0x136,0x812A) || !StateCheck(0x1D,0x841D) ||
      !StateCheck(0x9D,0x041D) || !StateCheck(0x11D,0x851D) ||
      !StateCheck(0x1E,0x841E) || !StateCheck(0x19D,0x811D)) return 151;
  I386ScanStateReset(&key_state);
  if (!StateCheck(0x3A,0x803A) || !StateCheck(0x3A,0x803A) ||
      !StateCheck(0x13A,0x913A) || !StateCheck(0x13A,0x913A) ||
      !StateCheck(0x3A,0x903A) || !StateCheck(0x13A,0x813A)) return 152;
  if (!StateCheck(0x45,0x8045)) return 160;
  if (!StateCheck(0x145,0xA145)) return 161;
  if (!StateCheck(0x47,0xA008)) return 162;
  if (!StateCheck(0x45,0xA045)) return 163;
  if (!StateCheck(0x145,0x8145)) return 164;
  if (!StateCheck(0x47,0x8008)) return 165;
  if (!StateCheck(0x147,0x8108)) return 166;
  if (!StateCheck(0x47,0x8047)) return 167;
  if (!StateCheck(0x147,0x8147)) return 168;
  if (!StateCheck(0xD3,0x48053) || !StateCheck(0x1D3,0x8153) ||
      !StateCheck(0xD2,0x88052) || !StateCheck(0x1D2,0x8152) ||
      !StateCheck(0x61,0x8061) || key_state.down[0x61]) return 154;
  if (!StateCheck(0x38,0x8838) || !StateCheck(0xB8,0x0838) ||
      !StateCheck(0x138,0x8938) || !StateCheck(0x1B8,0x8138) ||
      !StateCheck(0x46,0x8046) || !StateCheck(0x146,0xC146)) return 156;
  if (I386ScanStateApply(0,1,&event) || I386ScanStateApply(&key_state,1,0) ||
      I386ScanStateApply(&key_state,0x200,&event) || I386ScanStateApply(&key_state,0,&event) ||
      event!=0x123456789ABCDEF0) return 155;
  return 0;
}

I64 CharTest()
{
  I64 i;
  U8 *p;
  p=StringTestValue;
  if (p[0]!='A' || p[1] || p[2]!='B' || p[3] || (p+0)(U64)>>32) return 190;
  p="";
  if (*p) return 191;
  //The x64 guest fills this array from its existing ScanCode2Char implementation.
  for (i=0;i<32768;i++)
    if (I386ScanCode2Char(i)!=char_oracle[(i&255)+(((i>>9)&3)|((i>>10)&4))*256] ||
        I386ScanCode2Char(i|0xFFFFFFFF00000000)!=char_oracle[(i&255)+(((i>>9)&3)|((i>>10)&4))*256]) return 200+i;
  return 0;
}
U8 *StringTestValue() { return "A\x00B"; }

I64 ScanTest()
{
  CI386ScanSet1 state;
  U32 scan=0x12345678;
  U8 pause[6];
  I64 i;
  I386ScanSet1Reset(&state);
  //All ordinary baseline codes, including both physical Shift keys.
  for (i=1;i<0x60;i++) {
    if (I386ScanSet1Feed(&state,i,1,&scan)!=1 || scan!=i ||
        I386ScanSet1Feed(&state,i|0x80,1,&scan)!=1 || scan!=(i|0x100)) return 1;
    if (I386ScanSet1Feed(&state,0xE0,1,&scan) ||
        I386ScanSet1Feed(&state,i,1,&scan)!=(i!=0x2A && i!=0x36)) return 2;
    if (i!=0x2A && i!=0x36 && scan!=(i|0x80)) return 3;
    if (I386ScanSet1Feed(&state,0xE0,1,&scan) ||
        I386ScanSet1Feed(&state,i|0x80,1,&scan)!=(i!=0x2A && i!=0x36)) return 4;
    if (i!=0x2A && i!=0x36 && scan!=(i|0x180)) return 5;
  }
  pause[0]=0xE1; pause[1]=0x1D; pause[2]=0x45;
  pause[3]=0xE1; pause[4]=0x9D; pause[5]=0xC5;
  scan=0x12345678;
  for (i=0;i<5;i++)
    if (I386ScanSet1Feed(&state,pause[i],1,&scan) || scan!=0x12345678) return 6;
  if (I386ScanSet1Feed(&state,pause[5],1,&scan)!=1 || scan!=0x61 || state.pause) return 7;
  //Print Screen make/break, including fake shifts on either side.
  if (I386ScanSet1Feed(&state,0xE0,1,&scan) || I386ScanSet1Feed(&state,0x2A,1,&scan) ||
      I386ScanSet1Feed(&state,0xE0,1,&scan) || I386ScanSet1Feed(&state,0x37,1,&scan)!=1 ||
      scan!=0xB7 || I386ScanSet1Feed(&state,0xE0,1,&scan) ||
      I386ScanSet1Feed(&state,0xB7,1,&scan)!=1 || scan!=0x1B7 ||
      I386ScanSet1Feed(&state,0xE0,1,&scan) || I386ScanSet1Feed(&state,0xAA,1,&scan)) return 8;
  //Auxiliary bytes do not destroy a pending keyboard prefix.
  if (I386ScanSet1Feed(&state,0xE0,1,&scan) || I386ScanSet1Feed(&state,0xAA,0xE1,&scan) ||
      I386ScanSet1Feed(&state,0xAA,0,&scan) ||
      I386ScanSet1Feed(&state,0x48,1,&scan)!=1 || scan!=0xC8) return 9;
  scan=0x12345678;
  if (I386ScanSet1Feed(&state,0xE1,1,&scan) ||
      I386ScanSet1Feed(&state,0x20,1,&scan)!=-1 || scan!=0x12345678 || state.pause ||
      I386ScanSet1Feed(&state,0xE0,1,&scan) ||
      I386ScanSet1Feed(&state,0x1E,0x81,&scan)!=-1 || state.extended ||
      I386ScanSet1Feed(&state,0x1E,0x41,&scan)!=-1 ||
      I386ScanSet1Feed(&state,0,1,&scan)!=-1 ||
      I386ScanSet1Feed(&state,255,1,&scan)!=-1 || scan!=0x12345678) return 10;
  if (I386ScanSet1Feed(&state,0xFA,1,&scan) || I386ScanSet1Feed(&state,0xFE,1,&scan) ||
      I386ScanSet1Feed(&state,0xEE,1,&scan) || scan!=0x12345678 ||
      I386ScanSet1Feed(0,0x1E,1,&scan)!=-1 ||
      I386ScanSet1Feed(&state,0x1E,1,0)!=-1 ||
      I386ScanSet1Feed(&state,0x1E,1,&scan)!=1 || scan!=0x1E) return 11;
  I386ScanSet1Feed(&state,0xE0,1,&scan); I386ScanSet1Reset(&state);
  if (I386ScanSet1Feed(&state,0x48,1,&scan)!=1 || scan!=0x48) return 12;
  return 0;
}
