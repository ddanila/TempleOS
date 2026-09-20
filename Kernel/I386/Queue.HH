#ifndef I386_PUBLIC_QUEUE_INCLUDED
#define I386_PUBLIC_QUEUE_INCLUDED
#include "/Kernel/QueueTypes.HH"
#help_index "Data Types/Circular Queue"
#help_file "::/Doc/Que"
public _intern 0x80 U0 QueInit(CQue *head);
public _intern 0x81 U0 QueIns(CQue *entry,CQue *pred);
public _intern 0x82 U0 QueInsRev(CQue *entry,CQue *succ);
public _intern 0x83 U0 QueRem(CQue *entry);
#endif
