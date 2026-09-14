#ifndef I386_PUBLISH_CLASSES_INCLUDED
#define I386_PUBLISH_CLASSES_INCLUDED
#include "/Compiler/I386/Control.HH"
//Completed private acyclic class graphs; borrowed references must remain live.
//False leaves source ownership/table contents intact, including scratch OOM.
extern Bool I386PublishClasses(CI386Heap *heap,CCmpCtrl *cc,CHashTable *source);
#endif
