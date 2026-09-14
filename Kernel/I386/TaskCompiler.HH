#ifndef I386_TASK_COMPILER_INCLUDED
#define I386_TASK_COMPILER_INCLUDED
#include "/Kernel/I386/CompilerRuntime.HH"
#include "/Kernel/I386/TaskFiles.HH"
class CI386TaskCompilerConfig {
  CI386CompilerServices *compiler;
  U8 *tmp_filename;
  U32 *alpha_numeric,*alpha_numeric_no_at;
};
//Root-only setup; configuration, callbacks, filename and bitmaps remain borrowed/live.
public extern Bool I386TaskCompilerInit(CI386TaskCompilerConfig *config,CI386CompilerServices *compiler,
  U8 *tmp_filename,U32 *alpha_numeric,U32 *alpha_numeric_no_at);
//Current-task factory. NULL on failure; owned input transfers only on success.
public extern CCmpCtrl *I386TaskCmpCtrlNew(CI386TaskCompilerConfig *config,U8 *buffer=0,I64 flags=0,U8 *filename=0);
#endif
