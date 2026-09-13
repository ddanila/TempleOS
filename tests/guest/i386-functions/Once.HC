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
  EmitCase("return a<b;",-1,0,1,&cursor);
  EmitCase("return a<b;",0x100000000,0xFFFFFFFF,0,&cursor);
  EmitCase("return a>b;",0xFFFFFFFF,1,1,&cursor);
  EmitCase("return a>=b;",0x100000000,0x100000000,1,&cursor);
  EmitCase("return a<=b;",1,0x100000000,1,&cursor);
  EmitCase("return a==b;",0,0x100000000,0,&cursor);
  EmitCase("return a!=b;",0,0x100000000,1,&cursor);
  EmitCase("return a(U64)<b(U64);",-1,1,0,&cursor);
  EmitCase("if (a) return b; else return 7;",0x100000000,42,42,&cursor);
  EmitCase("if (a<b) return a; return b;",5,2,2,&cursor);
  EmitCase("I64 c; c=1; while (a>1) { c=c*a; a=a-1; } return c;",5,0,120,&cursor);
  EmitCase("do { a=a-1; } while (a); return a+b;",3,42,42,&cursor);
  EmitCase("I64 c; c=0; for (a=0;a<b;a=a+1) { c=c+a; } return c;",0,10,45,&cursor);
  EmitCase("return -a;",0x100000001,0,-0x100000001,&cursor);
  EmitCase("return ~a;",0x123456789ABCDEF0,0,0xEDCBA9876543210F,&cursor);
  EmitCase("return !a;",0x100000000,0,0,&cursor);
  EmitCase("return a++;",0xFFFFFFFF,0,0xFFFFFFFF,&cursor);
  EmitCase("return ++a;",0xFFFFFFFF,0,0x100000000,&cursor);
  EmitCase("return --a;",0x100000000,0,0xFFFFFFFF,&cursor);
  EmitCase("I64 c; c=a--; return c+a;",0x100000000,0,0x1FFFFFFFF,&cursor);
  EmitCase("U8 c; c=a; return ++c;",255,0,0,&cursor);
  EmitCase("U8 **p; p=a(U8 **); p++; return p;",0xFFFFFFFC,0,0,&cursor);
  EmitCase("a+=b; return a;",0xFFFFFFFF,1,0x100000000,&cursor);
  EmitCase("a-=b; return a;",0x100000000,1,0xFFFFFFFF,&cursor);
  EmitCase("a*=b; return a;",0x100000003,0x200000005,0xB0000000F,&cursor);
  EmitCase("a&=b; return a;",0x123456789ABCDEF0,0xFFFFFFFF00000000,0x1234567800000000,&cursor);
  EmitCase("a|=b; return a;",0x100000000,42,0x10000002A,&cursor);
  EmitCase("a^=b; return a;",-1,0x100000001,0xFFFFFFFEFFFFFFFE,&cursor);
  EmitCase("I64 c; c=0; for (a=0;a<b;a++) c+=a; return c;",0,10,45,&cursor);
  EmitCase("class P { U32 lo; U32 hi; }; P p; p.lo=a; p.hi=b; return p.lo(I64);",0x89ABCDEF,0x12345678,0x1234567889ABCDEF,&cursor);
  EmitCase("U8 *p[2]; return (&p[1])(U32)-(&p[0])(U32);",0,0,4,&cursor);
  EmitCase("return a<<b;",0x123456789ABCDEF0,0,0x123456789ABCDEF0,&cursor);
  EmitCase("return a<<b;",1,31,0x80000000,&cursor);
  EmitCase("return a<<b;",0x123456789,32,0x2345678900000000,&cursor);
  EmitCase("return a<<b;",1,63,0x8000000000000000,&cursor);
  EmitCase("return a<<b;",42,64,42,&cursor);
  EmitCase("return a>>b;",0x8000000000000000,31,0xFFFFFFFF00000000,&cursor);
  EmitCase("return a>>b;",0x8000000000000000,32,0xFFFFFFFF80000000,&cursor);
  EmitCase("return a>>b;",0x8000000000000000,63,-1,&cursor);
  EmitCase("return a(U64)>>b;",0x8000000000000000,31,0x100000000,&cursor);
  EmitCase("return a(U64)>>b;",0x8000000000000000,32,0x80000000,&cursor);
  EmitCase("return a(U64)>>b;",0x8000000000000000,63,1,&cursor);
  EmitCase("return a>>b;",-42,64,-42,&cursor);
  EmitCase("return a<<32;",0x123456789,0,0x2345678900000000,&cursor);
  EmitCase("return a>>32;",0x8000000000000000,0,0xFFFFFFFF80000000,&cursor);
  EmitCase("return a(U64)>>32;",0x8000000000000000,0,0x80000000,&cursor);
  EmitCase("a<<=b; return a;",0x123456789,32,0x2345678900000000,&cursor);
  EmitCase("a>>=b; return a;",0x8000000000000000,32,0xFFFFFFFF80000000,&cursor);
  EmitCase("U32 c; c=a; c<<=b; return c;",0xFFFFFFFF,1,0xFFFFFFFE,&cursor);
  EmitCase("return a/b;",100,3,33,&cursor);
  EmitCase("return a%b;",100,3,1,&cursor);
  EmitCase("return a/b;",-100,3,-33,&cursor);
  EmitCase("return a%b;",-100,3,-1,&cursor);
  EmitCase("return a/b;",100,-3,-33,&cursor);
  EmitCase("return a%b;",100,-3,1,&cursor);
  EmitCase("return a/b;",-100,-3,33,&cursor);
  EmitCase("return a(U64)/b(U64);",-1,0x100000000,0xFFFFFFFF,&cursor);
  EmitCase("return a(U64)%b(U64);",-1,0x100000000,0xFFFFFFFF,&cursor);
  EmitCase("return a(U64)/b(U64);",-1,0x8000000000000000,1,&cursor);
  EmitCase("return a(U64)%b(U64);",-1,0x8000000000000000,0x7FFFFFFFFFFFFFFF,&cursor);
  EmitCase("return a/b;",0x8000000000000000,1,0x8000000000000000,&cursor);
  EmitCase("return a/2;",-3,0,-1,&cursor);
  EmitCase("a/=b; return a;",-100,3,-33,&cursor);
  EmitCase("a%=b; return a;",-100,3,-1,&cursor);
  EmitCase("a/=2; return a;",-3,0,-1,&cursor);
  EmitCase("return a/b(U64);",-1,0x100000000,0xFFFFFFFF,&cursor);
  EmitCase("return a%b(U64);",-1,0x100000000,0xFFFFFFFF,&cursor);
  EmitCase("return a/b;",0x8000000000000000,0x8000000000000000,1,&cursor);
  EmitCase("return a%b;",0x8000000000000000,0x8000000000000001,-1,&cursor);
  EmitCase("return a/b;",0,0x100000000,0,&cursor);
  EmitCase("return a/b;",42,0x100000000,0,&cursor);
  EmitCase("return a%b;",42,0x100000000,42,&cursor);
  EmitCase("return a(U64)/b(U64);",0xFFFFFFFFFFFFFFFF,0x3,0x5555555555555555,&cursor);
  EmitCase("return a(U64)%b(U64);",0xFFFFFFFFFFFFFFFF,0x3,0x0,&cursor);
  EmitCase("return a(U64)/b(U64);",0xFEDCBA9876543210,0x123456789,0xE0000000,&cursor);
  EmitCase("return a(U64)%b(U64);",0xFEDCBA9876543210,0x123456789,0x96543210,&cursor);
  EmitCase("return a(U64)/b(U64);",0x80000000FFFFFFFF,0xFFFFFFFF,0x80000001,&cursor);
  EmitCase("return a(U64)%b(U64);",0x80000000FFFFFFFF,0xFFFFFFFF,0x80000000,&cursor);
  EmitCase("return a/b;",-320255973501901,4886718345,-65536,&cursor);
  EmitCase("return a%b;",-320255973501901,4886718345,-43981,&cursor);
  //Reserved expected value tells the isolated runner to require vector 0.
  EmitCase("return a/b;",42,0,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a%b;",42,0,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a/b;",0x8000000000000000,-1,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a%b;",0x8000000000000000,-1,0xDEADBEEFCAFEBABE,&cursor);
  Reject("#include \"/Kernel/Types.HH\"\nF64 Test(I64 a,I64 b) { return 1.5; }");
  Reject("#exe { 1+2; }");
  *cursor(U32 *)=0; cursor+=4;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",data,cursor-data);
  Report(line);
  Report("DONE i386 functions\n");
}
CompileTests;
