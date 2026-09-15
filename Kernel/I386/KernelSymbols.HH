#ifndef I386_KERNEL_SYMBOLS_INCLUDED
#define I386_KERNEL_SYMBOLS_INCLUDED
#include "/Kernel/SymbolTypes.HH"
//System exports share the public record; loader bindings additionally need kind.
class CI386KernelSymbol:CHashExport { U32 kind; };
#endif
