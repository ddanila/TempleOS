U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 EmitCase(U8 *body,I64 a,I64 b,I64 expected,U8 **cursor)
{
  I64 errors;
  CAOT *aot;
  U8 *source=MStrPrint("#include \"/Kernel/Types.HH\"\nI64 Test(I64 a,I64 b) { %s }",body);
  Report("CASE "); Report(body); Report("\n");
  aot=CmpI386Buf(source,&errors);
  Free(source);
  if (!aot || errors) { Report("FAIL function compile\n"); throw; }
  (*cursor)(U32 *)[0]=aot->aot_U8s; *cursor+=4;
  (*cursor)(I64 *)[0]=expected; *cursor+=8;
  (*cursor)(I64 *)[0]=a; *cursor+=8;
  (*cursor)(I64 *)[0]=b; *cursor+=8;
  MemCpy(*cursor,aot->buf,aot->aot_U8s); *cursor+=aot->aot_U8s;
  // Keep AOT metadata alive until the isolated test VM exits.
}
U0 Reject(U8 *source)
{
  I64 errors;
  CAOT *aot;
  Report("REJECT "); Report(source); Report("\n");
  aot=CmpI386Buf(source,&errors);
  if (aot || !errors) { Report("FAIL accepted unsupported source\n"); throw; }
}
U0 CompileTests()
{
  U8 *data=MAlloc(65536),*cursor=data,*line;
  Report("START i386 functions\n");
  EmitCase("return a+b;",0xFFFFFFFF,1,0x100000000,&cursor);
  EmitCase("return a-b;",0x100000000,1,0xFFFFFFFF,&cursor);
  EmitCase("return a*b;",0x100000003,0x200000005,0xB0000000F,&cursor);
  EmitCase("return a^b;",0x123456789ABCDEF0,0xFF00FF00FF00FF00,0xED34A97865BC21F0,&cursor);
  EmitCase("I64 c; c=a+b; return c*b;",0xFFFFFFFF,2,0x200000002,&cursor);
  EmitCase("I8 c; c=a; return c+b;",0xFF,2,1,&cursor);
  EmitCase("U32 c; c=a; return c+b;",0x1FFFFFFFF,1,0x100000000,&cursor);
  EmitCase("return sizeof(U8 *);",0,0,4,&cursor);
  EmitCase("return sizeof(I64);",0,0,8,&cursor);
  EmitCase("I64 *p; p=&a; return p[1];",1,0x123456789ABCDEF0,0x123456789ABCDEF0,&cursor);
  EmitCase("U8 **p; p=a(U8 **); return (p+1)(I64);",0x12340000,0,0x12340004,&cursor);
  EmitCase("U8 *p[2]; return sizeof(p);",0,0,8,&cursor);
  EmitCase("class P { U8 *x; U8 y; }; return sizeof(P);",0,0,5,&cursor);
  EmitCase("return (a(U8 **)+1)(I64);",0xFFFFFFFC,0,0,&cursor);
  EmitCase("return 0xFF(I8);",0,0,-1,&cursor);
  Reject("#include \"/Kernel/Types.HH\"\nI64 Test(I64 a,I64 b) { return a/b; }");
  Reject("#include \"/Kernel/Types.HH\"\nF64 Test(I64 a,I64 b) { return 1.5; }");
  Reject("#exe { 1+2; }");
  *cursor(U32 *)=0; cursor+=4;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",data,cursor-data);
  Report(line);
  Report("DONE i386 functions\n");
}
CompileTests;
