#ifndef KERNEL_DEBUG_GLOBALS_TYPES_INCLUDED
#define KERNEL_DEBUG_GLOBALS_TYPES_INCLUDED
#include "/Kernel/FunSegTypes.HH"
class CMPCrash
{
  I64	cpu_num;
  CTask *task;
  I64	rip;
  U8	*msg;
  I64	msg_num;
};

public class CDbgGlbls
{
  CTask *focus_task;
  U8	*msg;
  I64	msg_num;
  CMPCrash *mp_crash;
  U8	*int_fault_code,
	*fix_file_line;
  CFunSegCache *fun_seg_cache;
  I64	fun_seg_cache_index;
  Bool	panic;
};

#endif
