#ifndef I386_IDT_INCLUDED
#define I386_IDT_INCLUDED
//Same-ring 32-bit interrupt gates. Caller owns writable/live table storage.
public extern Bool I386IdtInit(U8 *table,I64 count,U8 *fallback,U16 selector);
public extern Bool I386IdtSet(U8 *table,I64 count,I64 vector,U8 *handler,U16 selector);
//Load only with IF clear. Table/handlers must outlive all uses of the IDTR.
public extern Bool I386IdtLoad(U8 *table,I64 count);
//Caller supplies six writable bytes for the current limit/base descriptor.
public extern Bool I386IdtRead(U8 *descriptor);
#endif
