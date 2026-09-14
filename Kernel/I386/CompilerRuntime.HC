//Disk-loaded lexer/numerical runtime. This image remains owned by the boot kernel.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/CompilerRuntime.HH"
#include "/Compiler/I386/LexString.HH"
#include "/Compiler/I386/LexNumber.HH"
import I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
import I64 I386LexSourceRead(U8 *context,CCmpCtrl *cc);
import U32 char_bmp_hex_numeric[16];
import U32 char_bmp_dec_numeric[16];
U32 compiler_runtime_version=I386_COMPILER_SERVICES_VERSION;
#assert sizeof(CI386CompilerServices)==16
I64 Main(CI386CompilerServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386CompilerServices)) return 0;
  services->version=compiler_runtime_version;
  services->bytes=sizeof(CI386CompilerServices);
  services->string_chunk=&I386LexStringChunk;
  services->number_token=&I386LexNumber;
  return 1;
}
#include "/Compiler/I386/LexString.HC"
#include "/Kernel/I386/SoftF64.HC"
#include "/Kernel/I386/Pow10.HC"
#include "/Compiler/I386/LexNumber.HC"
