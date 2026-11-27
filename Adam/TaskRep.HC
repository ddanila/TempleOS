#help_index "Info;Task"
#include "/Adam/TaskRepCore.HC"

public U0 TaskRep()
{//Report current tasks on all cores.
  I64 i;
  CCPU *c;
  PUSHFD
  CLI
  for (i=0;i<mp_cnt;i++) {
    c=&cpu_structs[i];
    "$$PURPLE$$CPU%02X$$FG$$\n",i;
    TaskRepTask(c->seth_task,2);
  }
  POPFD
}
