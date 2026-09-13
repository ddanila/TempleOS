#ifndef I386_INBOX_INCLUDED
#define I386_INBOX_INCLUDED
#include "/Kernel/I386/Message.HH"
#include "/Kernel/I386/Heap.HH"
class CI386OwnedInbox { CI386MsgQueue queue; CI386Heap *heap; U32 signature; };
public extern CI386OwnedInbox *I386InboxAlloc(CI386Task *task,CI386Heap *heap);
public extern Bool I386InboxFree(CI386OwnedInbox *inbox);
#endif
