#help_index "Games"

Cd(__DIR__);;
#ifdef I386_PUBLIC_USER_INCLUDED
if(!HashFind("ACInit",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;
if(!HashFind("SettingsPush",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/TaskSettings.HC",FALSE);;
#include "/Kernel/I386/NativeModelGeometry.HC"
#include "/Adam/AngleWrapCore.HC"
#endif
#include "Titanium"

#help_index ""
