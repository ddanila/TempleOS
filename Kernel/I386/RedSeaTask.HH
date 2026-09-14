#ifndef I386_REDSEA_TASK_INCLUDED
#define I386_REDSEA_TASK_INCLUDED
#include "/Kernel/I386/RedSea.HH"
#include "/Kernel/I386/AtaTask.HH"
//Root-only setup, IF clear, mounted volume and idle canonical channel required.
//The caller owns stable initially zeroed I/O storage. Share it across volumes
//on either drive of the channel. No unbind/rebind while published to tasks.
public extern Bool I386RedSeaTaskIoInit(CI386RedSeaIo *io,CI386AtaChannel *channel);
public extern Bool I386RedSeaTaskBind(CI386RedSea *volume,CI386RedSeaIo *io);
#endif
