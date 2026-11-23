#help_index "Games"

Cd(__DIR__);;
if(!HashFind("ACInit",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;
#include "VocabQuiz"

#help_index ""
