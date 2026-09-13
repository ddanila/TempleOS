#include "/Compiler/I386/Expr.HC"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 EmitCase(U8 *expression,I64 expected,U8 **cursor)
{
  I64 size;
  U8 *code;
  code=I386Expr(expression,&size);
  if (!code) { Report("FAIL i386 compiler\n"); throw; }
  (*cursor)(U32 *)[0]=size;
  *cursor+=4;
  (*cursor)(I64 *)[0]=expected;
  *cursor+=8;
  MemCpy(*cursor,code,size);
  *cursor+=size;
  Free(code);
}
U0 CompileTests()
{
  U8 *data=MAlloc(65536),*cursor=data,*line,*invalid;
  I64 size;
  Report("START i386 compile\n");
  EmitCase("0xFFFFFFFF+1",0x100000000,&cursor);
  EmitCase("0x100000000-1",0xFFFFFFFF,&cursor);
  EmitCase("(0x123456789+0xFFFFFFFF)*3",0x669D03698,&cursor);
  EmitCase("0x100000003*0x200000005",0xB0000000F,&cursor);
  EmitCase("-0x100000001",-0x100000001,&cursor);
  EmitCase("~0x123456789ABCDEF0",0xEDCBA9876543210F,&cursor);
  EmitCase("(0x123456789ABCDEF0^0xFF00FF00FF00FF00)&0xFFFFFFFF00000000",
    0xED34A97800000000,&cursor);
  EmitCase("0x8000000000000000-1",0x7FFFFFFFFFFFFFFF,&cursor);
  EmitCase("0xFFFFFFFFFFFFFFFF+1",0,&cursor);
  invalid=I386Expr("1.5+2.0",&size);
  if (invalid || size) { Report("FAIL accepted F64\n"); return; }
  invalid=I386Expr("0x100(I8)",&size);
  if (invalid || size) { Report("FAIL accepted narrow cast\n"); return; }
  invalid=I386Expr("1/0",&size);
  if (invalid || size) { Report("FAIL accepted division\n"); return; }
  *cursor(U32 *)=0; cursor+=4;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",data,cursor-data);
  Report(line);
  Report("DONE i386 compile\n");
}
CompileTests;
