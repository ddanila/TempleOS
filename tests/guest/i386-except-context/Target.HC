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
U32 removed,resume_requested;
extern U0 SysTry(U8 *catch_start,U8 *untry_start);
extern U0 SysUntry();
extern U0 Fire();
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
}
U0 SysUntry() { removed++; }
U0 Fire()
{
  (*active->invoke)(&registered);
  if(resume_requested) (*active->resume)(&registered);
}

#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Except.HC"
