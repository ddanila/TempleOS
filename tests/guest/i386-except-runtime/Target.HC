#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/ExceptRuntime.HH"
#include "/Kernel/I386/Debug.HH"
class CExceptControl {
  U0 (*save)(CI386ExceptCapture *out,U8 *catch_start,U8 *untry_start);
  U0 (*invoke)(CI386ExceptCapture *capture);
  U0 (*resume)(CI386ExceptCapture *capture);
  I64 (*test)();
  U8 *register_try;
  I64 (*segments)(I64 callback);
  U8 *descriptor;
};
CI386Scheduler scheduler;
CI386Task tasks[2];
CI386Heap heaps[2];
U32 reports[2],failures,current_id,recover_expected,recovered;
CI386ExceptCapture recovery;
CExceptControl *active;
extern Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size);
extern I64 Run();
extern U0 Report(CI386Task *task,I64 ch);
extern U0 Fatal(CI386Task *task,I64 status,I64 ch);
extern U0 NestedThrow();
extern I64 ReturnCatch();
I64 Main(CExceptControl *control,I64 unused)
{
  CI386ExceptServices services;
  U8 *frame=GetRBP;
  I64 result;
  active=control;
  services.invoke=control->invoke; services.resume=control->resume;
  services.report=&Report; services.fatal=0;
  if(I386ExceptInstall(0) || I386ExceptInstall(&services)) return 1;
  services.fatal=&Fatal;
  if(!I386ExceptInstall(&services) || I386ExceptInstall(&services)) return 2;
  for(current_id=0;current_id<2;current_id++) {
    if(!I386HeapInit(&heaps[current_id],0x40000+current_id*8192,4096)) return 3;
    tasks[current_id].addr=&tasks[current_id];
    tasks[current_id].owner=&scheduler;
    tasks[current_id].memory=&heaps[current_id];
    tasks[current_id].stk=frame-8192-offset(CTaskStk.stk_base);
    tasks[current_id].stk->next_stk=0; tasks[current_id].stk->stk_ptr=0;
    tasks[current_id].stk->stk_size=8200;
    scheduler.current=&tasks[current_id];
    if(!I386DataSegment(control->descriptor,&tasks[current_id],sizeof(CI386Task)))
      return 4;
    result=(*control->segments)((&Run+0)(U64));
    if(result) return result;
    if(heaps[current_id].used || heaps[current_id].allocations ||
        tasks[current_id].except_top || !I386HeapValid(&heaps[current_id])) return 5;
  }
  if(failures || reports[0]!=5 || reports[1]!=5 || recovered!=2) return 6;
  return 0;
}
I64 Run()
{
  CI386Task *task=I386TaskSelf;
  I64 value=0x1234567800000000,i;
  U8 *full;
  if(task!=&tasks[current_id]) return 10;
  try { throw(0x1122334455667788); failures++; }
  catch {
    if(task->except_ch!=0x1122334455667788) failures++;
    value+=3; task->catch_except=TRUE;
  }
  if(value!=0x1234567800000003 || reports[current_id]!=1) return 11;
  try { throw(99,TRUE); failures++; }
  catch {
    if(task->except_ch!=99) failures++;
    task->catch_except=TRUE;
  }
  if(reports[current_id]!=1) return 12;
  try { NestedThrow; failures++; }
  catch {
    if(task->except_ch!=42) failures++;
    value+=7; task->catch_except=TRUE;
  }
  if(value!=0x123456780000000A || reports[current_id]!=2) return 13;
  try { throw; failures++; }
  catch {
    if(task->except_ch) failures++;
    task->catch_except=TRUE;
  }
  if(reports[current_id]!=3) return 14;
  //An allocation failure during inner registration must reach the outer catch.
  try {
    full=I386HeapAlloc(task->memory,4016);
    if(!full) failures++;
    try { failures++; } catch { failures++; }
    failures++;
  } catch {
    if(task->except_ch!='OutMem') failures++;
    task->catch_except=TRUE;
  }
  if(!I386HeapFree(task->memory,full) || reports[current_id]!=3) return 15;
  if(ReturnCatch()!=0x123456789ABCDEF0 || reports[current_id]!=4 ||
      task->except_top || task->memory->used || failures) return 16;
  //Unhandled dispatch reaches the installed debugger/recovery hook.
  try {
    for(i=0;i<8;i++) (&recovery)(U32 *)[i]=(&task->except_top->capture)(U32 *)[i];
    recover_expected=1;
    throw(0xBADF00D);
    failures++;
  } catch { }
  if(recover_expected || recovered!=current_id+1 || task->except_top ||
      task->memory->used || reports[current_id]!=5 || failures) return 17;
  return 0;
}
U0 NestedThrow()
{
  I64 local=0x9876543210ABCDEF;
  try { throw(42); failures++; }
  catch { if(local!=0x9876543210ABCDEF) failures++; }
  failures++;
}
I64 ReturnCatch()
{
  try { throw(7); failures++; }
  catch { return 0x123456789ABCDEF0; }
  return 0;
}
U0 Report(CI386Task *task,I64 ch)
{
  I64 i;
  for(i=0;i<I386_EXCEPT_CALLERS;i++)
    if(task->except_callers[i]!=Caller(i+2)) failures++;
  if(task!=I386TaskSelf || task!=&tasks[current_id] || task->except_ch!=ch)
    failures++;
  reports[current_id]++;
}
U0 Fatal(CI386Task *task,I64 status,I64 ch)
{
  if(recover_expected && status==I386_EXCEPT_UNHANDLED && ch==0xBADF00D &&
      task==I386TaskSelf && !task->except_top && !task->memory->used) {
    //Test recovery recreates the cleanup record before restoring its frame.
    if(I386ExceptPush(task,task->memory,&recovery)) {
      recover_expected=0; recovered++;
      (*active->resume)(&task->except_top->capture);
    }
  }
  failures++;
  while(1) {}
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Except.HC"
#include "/Kernel/I386/ExceptRuntime.HC"
#include "/Kernel/I386/Segments.HC"

#include "/Kernel/I386/Debug.HC"
