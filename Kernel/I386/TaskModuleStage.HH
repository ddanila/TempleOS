#ifndef I386_TASK_MODULE_STAGE_INCLUDED
#define I386_TASK_MODULE_STAGE_INCLUDED
#include "/Kernel/I386/ModuleStage.HH"
#include "/Kernel/I386/TaskFiles.HH"
class CI386TaskModuleStage {
  CI386ModuleStage unit;
  CI386TaskFileStage resource;
  CI386TaskFiles *owner;
  CI386RedSea *volume;
  I64 block,blocks;
  Bool active;
};
extern CI386ModuleStage *I386TaskModuleStageNew(U8 *target,I64 bytes);
extern Bool I386TaskModuleStageCleanup(U8 *context);
#endif
