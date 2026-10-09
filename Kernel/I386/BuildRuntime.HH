#ifndef I386_BUILD_RUNTIME_INCLUDED
#define I386_BUILD_RUNTIME_INCLUDED
#include "/Kernel/I386/FileRuntime.HH"
#include "/Kernel/I386/TaskModuleStage.HH"
#define I386_BUILD_SERVICES_VERSION 2
class CI386BuildContext {
  CI386CompilerServices *compiler;
  CI386FileServices *files;
  CI386LexIncludeService *includes;
  CHashClass **types;
};
class CI386BuildServices {
  U32 version,bytes;
  CI386ModuleStage *(*stage_new)(U8 *target,I64 bytes);
  Bool (*stage_cleanup)(U8 *context);
  Bool (*publish)(CI386ModuleStage *unit,U8 *target);
  I64 (*build)(CI386BuildContext *config,U8 *source,U8 *target,Bool boot_module);
};
extern CI386BuildServices *I386BuildRuntimeAcquire();
extern I64 I386TaskBuildModule(CI386BuildContext *config,U8 *source,U8 *target,Bool boot_module);
#endif
