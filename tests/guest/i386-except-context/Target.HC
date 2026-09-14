#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Except.HH"
class CExceptControl {
  U0 (*save)(CI386ExceptCapture *out,U8 *catch_start,U8 *untry_start);
  U0 (*invoke)(CI386ExceptCapture *capture);
  U0 (*resume)(CI386ExceptCapture *capture);
  I64 (*test)();
  CI386Except *(*register_try)(CI386Task *task,CI386Heap *heap,U8 *catch_start,
    U8 *untry_start,CI386Except *(*provider)(CI386Task *task,CI386Heap *heap,
      CI386ExceptCapture *capture));
};
CI386Scheduler scheduler;
CI386Task task;
CI386Heap heap;
CExceptControl *active;
CI386ExceptCapture registered;
U32 removed,resume_requested,failures,trace;
extern U0 SysTry(U8 *catch_start,U8 *untry_start);
extern U0 SysUntry();
extern U0 Fire();
extern U0 NestedThrow();
extern U0 Reject();
extern U0 Accept();
extern U0 BadResume(CI386ExceptCapture *capture);
extern U0 RemoveSelected();
I64 Main(CExceptControl *control,I64 unused)
{
  CI386ExceptCapture capture;
  CI386Except *first,*second;
  U8 *full;
  U8 *frame=GetRBP;
  I64 local=0x1234567800000001,before;
  if((*control->test)()) return 1;
  (*control->save)(&capture,&Main,&Main);
  if(capture.ebp!=(frame+0)(U64) || capture.esp>capture.ebp ||
      capture.esp&3 || capture.catch_start!=&Main || capture.untry_start!=&Main)
    return 2;
  if(!I386HeapInit(&heap,0x40000,4096)) return 5;
  task.owner=&scheduler; scheduler.current=&task;
  task.stack_base=frame-4096; task.stack_size=4104;
  first=(*control->register_try)(&task,&heap,&Main,&Main,&I386ExceptPush);
  if(!first || task.except_top!=first || first->capture.ebp!=(frame+0)(U64) ||
      first->capture.esp>first->capture.ebp || first->capture.esp&3 ||
      first->capture.catch_start!=&Main || first->capture.untry_start!=&Main)
    return 6;
  second=(*control->register_try)(&task,&heap,&Main,&Main,&I386ExceptPush);
  if(!second || second->previous!=first || heap.allocations!=2) return 7;
  full=I386HeapAlloc(&heap,3952);
  if(!full || (*control->register_try)(&task,&heap,&Main,&Main,&I386ExceptPush) ||
      task.except_top!=second || heap.allocations!=3) return 8;
  if(!I386HeapFree(&heap,full) || !I386ExceptClear(&task) ||
      heap.used || !I386HeapValid(&heap)) return 9;
  active=control;
  try { Fire; local+=10; }
  catch { local+=0x100000007; }
  if(local!=0x1234567900000012 || removed!=1) return 3;
  before=local; resume_requested=1;
  try { Fire; local+=100; }
  catch { local+=0x200000003; }
  if(local!=before+0x200000003 || removed!=2) return 4;
  if(task.except_top || heap.used || failures) return 10;
  resume_requested=2; before=local;
  try {
    try { Fire; failures++; }
    catch { local+=3; }
    failures++;
  } catch { local+=7; task.catch_except=TRUE; }
  if(local!=before+10 || task.except_top || heap.used || failures ||
      task.except_ch!=0x123456789ABCDEF0) return 11;
  before=local;
  try { NestedThrow; failures++; }
  catch { local+=0x300000005; task.catch_except=TRUE; }
  if(local!=before+0x300000005 || trace!=1 || task.except_top || heap.used ||
      failures) return 12;
  try {
    try { Fire; failures++; }
    catch { task.catch_except=TRUE; }
    trace++;
  } catch { failures++; }
  if(trace!=2 || failures || task.except_top || heap.used) return 13;
  if(I386ExceptDispatch(&task,99,control->invoke,control->resume)!=
      I386_EXCEPT_UNHANDLED || task.except_ch!=99) return 14;
  capture.catch_start=&Reject;
  first=I386ExceptPush(&task,&heap,&capture);
  if(!first || I386ExceptDispatch(&task,77,control->invoke,control->resume)!=
      I386_EXCEPT_UNHANDLED || trace!=3 || task.except_top || heap.used) return 15;
  //Malformed records must be rejected before entering a handler.
  first=I386ExceptPush(&task,&heap,&capture);
  if(!first) return 16;
  first->signature=0;
  if(I386ExceptDispatch(&task,88,control->invoke,control->resume)!=
      I386_EXCEPT_INVALID || task.except_top!=first || trace!=3) return 17;
  first->signature=I386_EXCEPT_MAGIC;
  if(!I386ExceptClear(&task) || heap.used || !I386HeapValid(&heap)) return 18;
  capture.catch_start=&Accept;
  first=I386ExceptPush(&task,&heap,&capture);
  if(!first || I386ExceptDispatch(&task,123,control->invoke,&BadResume)!=
      I386_EXCEPT_RESUME_RETURNED || task.except_top!=first || trace!=4)
    return 19;
  if(!I386ExceptClear(&task)) return 20;
  capture.catch_start=&RemoveSelected;
  first=I386ExceptPush(&task,&heap,&capture);
  if(!first || I386ExceptDispatch(&task,124,control->invoke,control->resume)!=
      I386_EXCEPT_INVALID || task.except_top || heap.used) return 21;
  scheduler.current=0;
  if(I386ExceptDispatch(&task,125,control->invoke,control->resume)!=
      I386_EXCEPT_INVALID || task.except_ch!=124) return 22;
  scheduler.current=&task;
  if(I386ExceptDispatch(&task,125,0,control->resume)!=I386_EXCEPT_INVALID ||
      I386ExceptDispatch(&task,125,control->invoke,0)!=I386_EXCEPT_INVALID ||
      task.except_ch!=124 || failures || removed!=6 || !I386HeapValid(&heap))
    return 23;
  return 0;
}
//Fixture registration only: retain the real enclosing frame and compiler labels.
//This does not supply the production SysTry entry or its register capture.
U0 SysTry(U8 *catch_start,U8 *untry_start)
{
  U8 *frame=GetRBP;
  registered.ebp=*frame(U32 *);
  registered.esp=frame+24;
  registered.catch_start=catch_start; registered.untry_start=untry_start;
  registered.eflags=2;
  if(!I386ExceptPush(&task,&heap,&registered)) failures++;
}
U0 SysUntry() { if(!I386ExceptPop(&task)) failures++; removed++; }
U0 Fire()
{
  if(resume_requested==2) {
    I386ExceptDispatch(&task,0x123456789ABCDEF0,active->invoke,active->resume);
    failures++;
  } else {
    (*active->invoke)(&task.except_top->capture);
    if(resume_requested) (*active->resume)(&task.except_top->capture);
  }
}

U0 NestedThrow()
{
  I64 inner=0x1234567800000000;
  try { Fire; failures++; }
  catch { if(inner!=0x1234567800000000) failures++; trace++; }
  failures++;
}
U0 Reject() { trace++; }
U0 Accept() { task.catch_except=TRUE; }
U0 BadResume(CI386ExceptCapture *capture) { trace++; }
U0 RemoveSelected() { if(!I386ExceptPop(&task)) failures++; }
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Except.HC"
