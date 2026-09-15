//Shared public records; callers provide their declared dependencies.
public class CCPU //The Gs segment reg points to current CCPU.
{
  CCPU	*addr; //Self-addressed ptr
  I64	num,cpu_flags,
	startup_rip,
	idle_pt_hits;
  F64	idle_factor;
  I64	total_jiffies;
  CTask *seth_task,*idle_task;
  I64	tr,   //task reg
	swap_cnter;
  U0	(*profiler_timer_irq)(CTask *task);
  CTaskDying *next_dying,*last_dying;
  I64	kill_jiffy;
  CTSS	*tss;
  I64	start_stk[16];
  $$=($$+7)&~7;
#assert !($$&7)
};
