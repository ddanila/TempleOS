#ifndef I386_GDT_INCLUDED
#define I386_GDT_INCLUDED
public extern Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size);
//Five entries: null, flat code/data, task FS and CPU GS (selectors 0x18/0x20).
public extern Bool I386GdtInit(U8 *table,U8 *task,I64 task_size,U8 *cpu,I64 cpu_size);
//IF must be clear. Existing cached CS/SS/DS/ES must match the new flat entries.
public extern Bool I386GdtLoad(U8 *table,I64 count);
public extern Bool I386GdtRead(U8 *descriptor);
#endif
