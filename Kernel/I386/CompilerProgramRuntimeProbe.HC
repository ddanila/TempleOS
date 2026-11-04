//All program/self-hosting vectors, in a separately reclaimable diagnostic image.
#include "/Kernel/I386/CompilerProbeImports.HC"
#include "/Compiler/SymbolInit.HC"
#include "/Kernel/I386/TaskStorage.HC"
#include "/Compiler/I386/SymbolDelete.HC"
#include "/Kernel/I386/CompilerProbeReportCore.HC"
#include "/Kernel/I386/CompilerProbeFindCore.HC"
#include "/Kernel/I386/CompilerProbeRemoveCore.HC"
#include "/Kernel/I386/CompilerProgramProbe.HC"
U32 compiler_probe_version=I386_COMPILER_PROBE_VERSION;
#assert sizeof(CI386CompilerProbe)==80
I64 Main(CI386CompilerProbe *probe,I64 bytes)
{
  CI386Task *task=I386TaskSelf;
  CI386Heap *heap=task->memory;
  CI386BackingCheck backing;
  CCmpCtrl *outer;
  I64 refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  if(!probe || bytes!=sizeof(CI386CompilerProbe) || probe->bytes!=bytes ||
      probe->version!=compiler_probe_version || probe->phase<0 || probe->phase>1 ||
      !probe->compiler || !probe->files || !probe->internal_types ||
      task->active_controls || task->last_cc!=&task->next_cc)return 0;
  if(!heap)heap=probe->heap;
  if(!I386BackingCheckSave(&backing,heap,task->code_heap))KernelStop;
  outer=probe->files->control_new("",CCF_DONT_FREE_BUF,"Probe/ProgramOuter.HC");
  if(!outer || !probe->compiler->control_enter(heap,outer,0,0))KernelStop;
  ProbePrograms(probe,heap,outer);
  if(!probe->compiler->control_leave(heap,outer) || task->active_controls ||
      task->last_cc!=&task->next_cc || !probe->compiler->control_del(heap,outer,0,0) ||
      task->lifetime_refs!=refs || (GetRFlags&0x200)!=(flags&0x200) ||
      !I386BackingCheckRestored(&backing))KernelStop;
  KernelLog("PROGRAM PROBE complete ");KernelHex(probe->phase);KernelLog("\n");
  return 1;
}
