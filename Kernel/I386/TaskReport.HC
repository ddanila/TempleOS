#include "/Adam/TaskMemAllocedCore.HC"
#include "/Adam/TaskRepCore.HC"

public U0 TaskRep()
{//Report the resident CPU's task tree.
  U32 flags=I386IrqSave;
  "$$PURPLE$$CPU%02X$$FG$$\n",0;
  TaskRepTask(Fs->gs->seth_task,2);
  I386IrqRestore(flags);
}
