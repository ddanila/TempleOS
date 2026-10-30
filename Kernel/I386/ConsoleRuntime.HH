#ifndef I386_CONSOLE_RUNTIME_INCLUDED
#define I386_CONSOLE_RUNTIME_INCLUDED
#include "/Kernel/I386/CompilerRuntime.HH"
#include "/Kernel/I386/FileRuntime.HH"
#include "/Kernel/I386/KeyboardRead.HH"
#include "/Kernel/I386/Mouse.HH"
//Native task extensions include public heap ownership callbacks.
#include "/Kernel/I386/DocDiagnostic.HH"
#include "/Kernel/I386/EditorRuntime.HH"
#define I386_CONSOLE_VERSION 171
class CI386ConsoleConfig {
  CI386Heap *heap;
  CI386CompilerServices *compiler;
  CI386FileServices *files;
  //Borrowed kernel-lifetime canonical drive table, including unused slots.
  CDrv *drive_records;
  CDrv **drive_map;
  CBlkDev *block_records;
  //Shared kernel-lifetime state for future block I/O and cache integration.
  CBlkDevGlbls *block_globals;
  CI386LexIncludeService *includes;
  CHashClass **types;
  CI386KeyboardReader *reader;
  CI386KbcInput *input;
  CI386MouseState *mouse;
  I64 *jiffies;
  U32 pit_divisor;
  U64 *pit_ticks;
  Bool (*editor_load)(CI386EditorServices *services,U8 **owned,I64 *image_bytes,CI386EditorContext *context);
  Bool defer_root_headers;
  Bool (*input_poll)();
  Bool (*doc_diagnostic_load)(CI386DocDiagnosticServices *services,U8 **image,I64 *bytes);
};
class CI386ConsoleServices {
  U32 version,bytes;
  Bool (*init)(CI386ConsoleConfig *config);
  Bool (*display)();
  U0 (*keys)(I64 unused);
  Bool (*cancel_read)(CI386Task *task);
  Bool (*cancel_wait)(CI386Task *task);
  Bool (*key_irq)(U8 data,U8 status);
  Bool (*cpu_capture)(CI386ExceptionFrame *frame);
  U0 (*cpu_debug)(CI386ExceptionFrame *frame);
  Bool (*root_headers)();
  U0 (*window_ensure)();
};
#endif
