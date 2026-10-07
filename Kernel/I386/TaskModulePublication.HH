#ifndef I386_TASK_MODULE_PUBLICATION_INCLUDED
#define I386_TASK_MODULE_PUBLICATION_INCLUDED
#include "/Kernel/I386/TaskModuleStage.HH"
#include "/Kernel/I386/RedSeaPublication.HH"
class CI386TaskModulePublication {
  CI386RedSeaPublication publication;
  CI386TaskFileStage resource;
  CI386TaskModuleStage *stage;
};
extern CI386RedSeaPublication *I386TaskModulePublicationNew(CI386ModuleStage *unit);
extern Bool I386TaskModulePublicationCleanup(U8 *context);
#endif
