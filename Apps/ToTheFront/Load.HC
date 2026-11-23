#help_index "Games"

Cd(__DIR__);;
#ifdef I386_PUBLIC_USER_INCLUDED
#include "/Kernel/I386/NativeTTFGeometry.HC"
#include "/Adam/DolDoc/DocIntegerPromptCore.HC"
#include "/Adam/AngleWrapCore.HC"
#endif
#include "TTFGlbls"
#include "TTFLib"
#include "TTFInit"
#include "TTFVis"
#include "TTFFire"
#include "TTFMove"
#ifdef I386_PUBLIC_USER_INCLUDED
#include "/Kernel/I386/NativeTTFCurves.HC"
#endif
#include "TTFDraw"
#ifdef I386_PUBLIC_USER_INCLUDED
#include "/Adam/DolDoc/DocFloatRangeCore.HC"
#include "/Kernel/SerialDev/KeyCharPollCore.HC"
if(!HashFind("ACInit",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;
if(!HashFind("SettingsPush",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/TaskSettings.HC",FALSE);;
#endif
#include "ToTheFront"

#help_index ""
