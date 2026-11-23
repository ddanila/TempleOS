#help_index "Games"

Cd(__DIR__);;
#ifdef I386_PUBLIC_USER_INCLUDED
if(!HashFind("ODEsUpdate",adam_task->hash_table,HTT_FUN))
  AdamFile("/Kernel/I386/NativeODE.HC",FALSE);;
if(!HashFind("ACInit",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;
if(!HashFind("SettingsPush",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/TaskSettings.HC",FALSE);;
#include "/Kernel/I386/NativeXCaliber.HC"
#endif
#include "XCCtrls"
#include "X-Caliber"

#help_index ""
