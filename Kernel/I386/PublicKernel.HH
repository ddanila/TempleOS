#ifndef I386_PUBLIC_KERNEL_INCLUDED
#define I386_PUBLIC_KERNEL_INCLUDED
//Load with I386_INPUT_ATOMIC_DEFINES so failed headers remain retryable.
#include "/Kernel/I386/PublicTaskTypes.HH"
#include "/Kernel/I386/PublicMemory.HH"
public _intern 0x15 CTask *Fs();
public _intern 0x17 CCPU *Gs();
#endif
