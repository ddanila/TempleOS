#ifndef I386_COMPILER_RUNTIME_INCLUDED
#define I386_COMPILER_RUNTIME_INCLUDED
#include "/Compiler/I386/LexInput.HH"
#define I386_COMPILER_SERVICES_VERSION 4
//ABI 4: caller-owned interface, borrowing code from the retained module image.
//Detach all users before unloading; the boot kernel retains it for its lifetime.
class CI386CompilerServices {
  U32 version,bytes;
  I64 (*string_chunk)(CI386Heap *heap,CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *compiled_lines);
  I64 (*number_token)(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines);
  I64 (*char_token)(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
  I64 (*punct_token)(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines);
  I64 (*ident_scan)(CI386Heap *heap,CCmpCtrl *cc,I64 ch,U8 *buf,I64 capacity,CHash **entry,I64 *compiled_lines);
};
#endif
