#help_index "Games"

Cd(__DIR__);;
#ifdef I386_PUBLIC_USER_INCLUDED
if(!HashFind("ODEsUpdate",adam_task->hash_table,HTT_FUN))
  AdamFile("/Kernel/I386/NativeODE.HC",FALSE);;
if(!HashFind("ACInit",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;
if(!HashFind("SettingsPush",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/TaskSettings.HC",FALSE);;
if(!HashFind("PopUpFileName",adam_task->hash_table,HTT_FUN))
  AdamFile("/Kernel/I386/NativeFileNameForm.HC",FALSE);;
if(!HashFind("Play",adam_task->hash_table,HTT_FUN))
  AdamFile("/Kernel/I386/NativeMusicPlay.HC",FALSE);;
#ifndef I386_BUTTON_CONTROLS_INCLUDED
#define I386_BUTTON_CONTROLS_INCLUDED
#include "/Adam/Ctrls/CtrlsBttn.HC"
#endif
#endif
#include "Span.HH"
#include "SpanDerive"
#include "SpanBridge"
#include "SpanNew"
#include "SpanMain"

#help_index ""
