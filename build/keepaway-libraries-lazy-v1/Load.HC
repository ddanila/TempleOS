#help_index "Games"

Cd(__DIR__);;
if(!HashFind("AutoComplete",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;
if(!HashFind("SettingsPush",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/TaskSettings.HC",FALSE);;
#include "KeepAway"

#help_index ""
