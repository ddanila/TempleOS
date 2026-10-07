#ifndef I386_PUBLIC_DEBUG_TYPES_INCLUDED
#define I386_PUBLIC_DEBUG_TYPES_INCLUDED
//Canonical CBpt shape from Kernel/KernelA.HH.
class CBpt { CBpt *next; U8 *addr,val,pad[7]; };
#endif
