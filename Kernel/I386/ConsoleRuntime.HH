#ifndef I386_CONSOLE_RUNTIME_INCLUDED
#define I386_CONSOLE_RUNTIME_INCLUDED
#include "/Kernel/I386/CompilerRuntime.HH"
#include "/Kernel/I386/FileRuntime.HH"
#include "/Kernel/I386/KeyboardRead.HH"
//Native task extensions include public heap ownership callbacks.
#define I386_CONSOLE_VERSION 8
class CI386ConsoleConfig {
  CI386Heap *heap;
  CI386CompilerServices *compiler;
  CI386FileServices *files;
  CI386LexIncludeService *includes;
  CHashClass **types;
  CI386KeyboardReader *reader;
  I64 (*read)(CI386KeyboardReader *reader,CI386KeyEvent *event,Bool wait);
};
class CI386ConsoleServices {
  U32 version,bytes;
  Bool (*init)(CI386ConsoleConfig *config);
  Bool (*display)();
  U0 (*keys)(I64 unused);
};
#endif
