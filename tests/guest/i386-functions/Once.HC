#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
I64 case_number=0;
U0 EmitCase(U8 *body,I64 a,I64 b,I64 expected,U8 **cursor,
  U8 *prefix="",U8 *suffix="")
{
  I64 errors;
  CAOT *aot;
  CAOTImportExport *ie;
  U8 *line,*source=MStrPrint("#include \"/Kernel/Types.HH\"\n%s\nI64 Test(I64 a,I64 b) { %s }\n%s",prefix,body,suffix);
  Report("CASE "); Report(body); Report("\n");
  aot=CmpI386Buf(source,&errors);
  Free(source);
  if (!aot || errors) { Report("FAIL function compile\n"); throw; }
  for (ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next) {
    if (ie->type==IET_REL32_EXPORT) {
      line=MStrPrint("RANGE %d %X\n",case_number,ie->rip);
      Report(line); Free(line);
    }
  }
  case_number++;
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
U0 ModuleRejectTests(U8 *consumer,I64 consumer_size,U8 *provider,I64 provider_size)
{
  U8 *bad=MAlloc(consumer_size),*modules[3],*res;
  I64 sizes[3],size,i,import_index=-1,j;
  CI386ModuleHeader *h=consumer;
  CI386ModuleRecord *r=consumer+h->records_offset;
  for (j=0;j<h->record_count;j++)
    if (r[j].kind==I386_MODULE_REL32) import_index=j;
  if (import_index<0) { Report("FAIL missing import record\n"); throw; }
  sizes[0]=consumer_size; sizes[1]=sizes[2]=provider_size;
  modules[0]=bad; modules[1]=modules[2]=provider;
  for (i=0;i<19;i++) {
    MemCpy(bad,consumer,consumer_size);
    h=bad; r=bad+h->records_offset; r+=import_index;
    switch (i) {
      case 0: h->magic^=1; break;
      case 1: h->version++; break;
      case 2: h->cpu=6; break;
      case 3: h->pointer_size=8; break;
      case 4: h->abi++; break;
      case 5: h->total_size--; break;
      case 6: h->code_size=U32_MAX; break;
      case 7: h->record_count=U32_MAX; break;
      case 8: h->records_offset=0; break;
      case 9: h->strings_offset=U32_MAX; break;
      case 10: r->kind=99; break;
      case 11: r->offset=h->code_size-2; break;
      case 12: r->name_offset=U32_MAX; break;
      case 13: r->name_length=0; break;
      case 14: bad[r->name_offset+r->name_length]=1; break;
      case 15: bad[32+r->offset-1]=0x90; break;
      case 16: bad[32+r->offset]=1; break;
      case 17: h->code_size=0xFFFFFFF8; h->records_offset=24; break;
      case 18: h->record_count=0x10000000; h->strings_offset=h->records_offset; break;
    }
    if (I386ModuleValid(bad,consumer_size)) { Report("FAIL accepted malformed module\n"); throw; }
    res=I386Link(modules,sizes,2,&size);
    if (res || size) { Report("FAIL linked malformed module\n"); throw; }
  }
  modules[0]=consumer;
  res=I386Link(modules,sizes,1,&size);
  if (res || size) { Report("FAIL unresolved import\n"); throw; }
  res=I386Link(modules,sizes,3,&size);
  if (res || size) { Report("FAIL duplicate export\n"); throw; }
  res=I386Link(modules,sizes,2,&size,"Missing");
  if (res || size) { Report("FAIL missing entry\n"); throw; }
  if (I386ModuleValid(consumer,consumer_size-1) || I386ModuleValid(NULL,consumer_size)) {
    Report("FAIL truncated/null module\n"); throw;
  }
  Free(bad);
  Report("PASS module validation\n");
}

U0 EmitLinkedCase(I64 a,I64 b,I64 expected,U8 **cursor,Bool reverse)
{
  U8 *modules[2],*snapshots[2],*image,*again,*line,*saved;
  I64 sizes[2],size,size2,errors,i,j,base=8;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  modules[0]=CmpI386Module("#include \"/Kernel/Types.HH\"\nimport I64 Add(I64 a,I64 b); I64 Main(I64 a,I64 b) { return Add(a,b); }",&sizes[0],&errors);
  if (!modules[0] || errors) { Report("FAIL caller module\n"); throw; }
  modules[1]=CmpI386Module("#include \"/Kernel/Types.HH\"\nI64 Add(I64 a,I64 b) { return a+b; }",&sizes[1],&errors);
  if (!modules[1] || errors) { Report("FAIL provider module\n"); throw; }
  if (!reverse) ModuleRejectTests(modules[0],sizes[0],modules[1],sizes[1]);
  if (reverse) {
    saved=modules[0]; modules[0]=modules[1]; modules[1]=saved;
    i=sizes[0]; sizes[0]=sizes[1]; sizes[1]=i;
  }
  for (i=0;i<2;i++) { snapshots[i]=MAlloc(sizes[i]); MemCpy(snapshots[i],modules[i],sizes[i]); }
  image=I386Link(modules,sizes,2,&size);
  again=I386Link(modules,sizes,2,&size2);
  if (!image || !again || size!=size2 || MemCmp(image,again,size)) {
    Report("FAIL module link\n"); throw;
  }
  Free(again);
  line=MStrPrint("LINKED %d\n",case_number); Report(line); Free(line);
  for (i=0;i<2;i++) {
    if (MemCmp(modules[i],snapshots[i],sizes[i]) || !I386ModuleValid(modules[i],sizes[i])) { Report("FAIL mutated module\n"); throw; }
    Free(snapshots[i]);
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++)
      if (r->kind==I386_MODULE_EXPORT) {
        line=MStrPrint("RANGE %d %X\n",case_number,base+r->offset);
        Report(line); Free(line);
      }
    base+=h->code_size;
  }
  (*cursor)(U32 *)[0]=size; *cursor+=4;
  (*cursor)(I64 *)[0]=expected; *cursor+=8;
  (*cursor)(I64 *)[0]=a; *cursor+=8;
  (*cursor)(I64 *)[0]=b; *cursor+=8;
  MemCpy(*cursor,image,size); *cursor+=size;
  case_number++;
  //Keep module buffers live for host artifact extraction.
  for (i=0;i<2;i++) {
    line=MStrPrint("EXPORT module-%d-%d.t32m %X %X\n",reverse,i,modules[i],sizes[i]);
    Report(line); Free(line);
  }
  Free(image);
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
  EmitCase("return Add(a,b);",0xFFFFFFFF,1,0x100000000,&cursor,
    "extern I64 Add(I64 a,I64 b);", "I64 Add(I64 a,I64 b) { return a+b; }");
  EmitCase("return a+Add(a,Add(b,3));",10,2,25,&cursor,
    "extern I64 Add(I64 a,I64 b);", "I64 Add(I64 a,I64 b) { return a+b; }");
  EmitCase("if (a<=1) return b; return Test(a-1,a*b);",5,1,120,&cursor);
  EmitCase("return Twice(a,b);",0x100000000,3,0x200000006,&cursor,
    "extern I64 Twice(I64 a,I64 b); extern I64 Add(I64 a,I64 b);",
    "I64 Add(I64 a,I64 b) { return a+b; } I64 Twice(I64 a,I64 b) { return Add(a,b)*2; }");
  EmitCase("Store(&a,b); return a;",1,0x123456789ABCDEF0,0x123456789ABCDEF0,&cursor,
    "extern U0 Store(I64 *p,I64 b);", "U0 Store(I64 *p,I64 b) { *p=b; }");
  EmitCase("return Byte(a,b);",0x12345678FF,0,255,&cursor,
    "extern U8 Byte(I64 a,I64 b);", "U8 Byte(I64 a,I64 b) { return a; }");
  EmitCase("return Byte(a,b);",255,0,-1,&cursor,
    "extern I8 Byte(I64 a,I64 b);", "I8 Byte(I64 a,I64 b) { return a; }");
  EmitCase("return Add(a);",35,0,42,&cursor,
    "extern I64 Add(I64 a,I64 b=7);", "I64 Add(I64 a,I64 b) { return a+b; }");
  EmitCase("return Slot(a,b);",255,0,-1,&cursor,
    "extern I64 Slot(I8 a,I64 b);", "I64 Slot(I8 a,I64 b) { return a(I64); }");
  EmitCase("return Slot(a,b);",0x10000002A,0,42,&cursor,
    "extern I64 Slot(U8 *p,I64 b);", "I64 Slot(U8 *p,I64 b) { return p(I64); }");
  EmitCase("return a+Value();",7,0,49,&cursor,
    "extern I64 Value();", "I64 Value() { return 42; }");
  EmitCase("return Sum(a,b,3);",10,20,33,&cursor,
    "extern I64 Sum(I64 a,I64 b,I64 c);", "I64 Sum(I64 a,I64 b,I64 c) { return a+b+c; }");
  EmitCase("return a&&b;",0x100000000,42,1,&cursor);
  EmitCase("return a||b;",0,0x100000000,1,&cursor);
  EmitCase("return a&&b;",42,0,0,&cursor);
  EmitCase("return a||b;",0,0,0,&cursor);
  EmitCase("return a^^b;",0x100000000,1,0,&cursor);
  EmitCase("return a^^b;",0,0x100000000,1,&cursor);
  EmitCase("a&&b++; return b;",0,42,42,&cursor);
  EmitCase("a||b++; return b;",1,42,42,&cursor);
  EmitCase("a&&b++; return b;",1,42,43,&cursor);
  EmitCase("a||b++; return b;",0,42,43,&cursor);
  EmitCase("return a&&(1/b);",0,0,0,&cursor);
  EmitCase("return a||(1/b);",1,0,1,&cursor);
  EmitCase("return (a&&b)||(!a&&b);",0,42,1,&cursor);
  EmitCase("if (a&&b) return 7; return 9;",1,1,7,&cursor);
  EmitCase("if (a||b) return 7; return 9;",0,0,9,&cursor);
  EmitCase("return a||(Add(a,b)&&b);",0,2,1,&cursor,
    "extern I64 Add(I64 a,I64 b);", "I64 Add(I64 a,I64 b) { return a+b; }");
  //Reserved expected value tells the isolated runner to require vector 0.
  EmitCase("return a/b;",42,0,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a%b;",42,0,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a/b;",0x8000000000000000,-1,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a%b;",0x8000000000000000,-1,0xDEADBEEFCAFEBABE,&cursor);
  Reject("#include \"/Kernel/Types.HH\"\nF64 Test(I64 a,I64 b) { return 1.5; }");
  Reject("#include \"/Kernel/Types.HH\"\nextern I64 Missing(I64 a,I64 b); I64 Test(I64 a,I64 b) { return Missing(a,b); }");
  Reject("#exe { 1+2; }");
  EmitLinkedCase(0xFFFFFFFF,1,0x100000000,&cursor,FALSE);
  EmitLinkedCase(0x100000000,42,0x10000002A,&cursor,TRUE);
  *cursor(U32 *)=0; cursor+=4;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",data,cursor-data);
  Report(line);
  Report("DONE i386 functions\n");
}
CompileTests;
