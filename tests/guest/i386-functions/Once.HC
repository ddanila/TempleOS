#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
I64 case_number=0;
U0 EmitCase(U8 *body,I64 a,I64 b,I64 expected,U8 **cursor,
  U8 *prefix="",U8 *suffix="")
{
  I64 errors,log_size;
  CAOT *aot;
  CAOTImportExport *ie;
  U8 *line,*source=MStrPrint("#include \"/Kernel/Types.HH\"\n%s\nI64 Test(I64 a,I64 b) { %s }\n%s",prefix,body,suffix);
  Report("CASE "); Report(body); Report("\n");
  aot=CmpI386Buf(source,&errors);
  Free(source);
  if (!aot || errors) {
    source=DocSave(DocPut,&log_size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,log_size); Report(line);
    Report("FAIL function compile\n"); throw;
  }
  for (ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next) {
    if (ie->type==IET_REL32_EXPORT) {
      line=MStrPrint("RANGE %d %X\n",case_number,ie->rip);
      Report(line); Free(line);
    } else if (ie->type==IET_I386_DATA) {
      line=MStrPrint("DATA %d %X %X\n",case_number,ie->rip,ie->flags);
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
Bool switch_host_checked;
//Run the same integral switch body on the host compiler and native backend.
U0 EmitSwitchCase(U8 *body,I64 a,I64 b,I64 expected,U8 **cursor,U8 *prefix="")
{
  switch_host_checked=FALSE;
  ExePrint("I64 SwitchOracle%d(I64 a,I64 b) { %s }\n"
    "if (SwitchOracle%d(0x%X,0x%X)==0x%X) switch_host_checked=TRUE;",
    case_number,body,case_number,a,b,expected);
  if (!switch_host_checked) { Report("FAIL x64 switch\n"); throw; }
  EmitCase(body,a,b,expected,cursor,prefix);
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
  if (reverse) {
    modules[0]=CmpI386Module("#include \"/Kernel/Types.HH\"\nimport I64 Add(I64 a,...); I64 Main(I64 a,I64 b) { I64 (*fp)(I64 x,I64 y); fp=&Main; if (a) return (*fp)(0,Add(a,b)); return b; }",&sizes[0],&errors);
    if (!modules[0] || errors) { Report("FAIL caller module\n"); throw; }
    modules[1]=CmpI386Module("#include \"/Kernel/Types.HH\"\nI64 Add(I64 a,...) { return a+argv[0]; }",&sizes[1],&errors);
    if (!modules[1] || errors) { Report("FAIL provider module\n"); throw; }
  } else {
    modules[0]=CmpI386Module("#include \"/Kernel/Types.HH\"\nimport I64 Add(I64 a,I64 b); I64 Main(I64 a,I64 b) { I64 (*fp)(I64 x,I64 y); fp=&Main; if (a) return (*fp)(0,Add(a,b)); return b; }",&sizes[0],&errors);
    if (!modules[0] || errors) { Report("FAIL caller module\n"); throw; }
    modules[1]=CmpI386Module("#include \"/Kernel/Types.HH\"\nI64 Add(I64 a,I64 b) { return a+b; }",&sizes[1],&errors);
    if (!modules[1] || errors) { Report("FAIL provider module\n"); throw; }
  }
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
  U8 *data=MAlloc(131072),*cursor=data,*line;
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
  EmitCase("return 0<a<=b<100;",42,43,1,&cursor);
  EmitCase("return 0<a<=b<100;",0,43,0,&cursor);
  EmitCase("return (0<a<b)<(b<a<100)<=1;",42,43,0,&cursor);
  EmitCase("return (0<a<b)<(b<a<100)<=1;",43,42,1,&cursor);
  EmitCase("return (a<b<a+10)+(b<a<b+10);",42,43,1,&cursor);
  EmitCase("return a==b!=0;",42,42,1,&cursor);
  EmitCase("return a==b!=0;",0,0,0,&cursor);
  EmitCase("return a>=b>0;",42,42,1,&cursor);
  EmitCase("return a<Add(a,b)<a+b+1;",42,1,1,&cursor,
    "extern I64 Add(I64 a,I64 b);", "I64 Add(I64 a,I64 b) { return a+b; }");
  EmitCase("return ToBool(a);",0,0,0,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(a);",1,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(a);",256,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(a);",0x100000000,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(a);",0x8000000000000000,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(a);",-1,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(ToBool(a));",0x100000000,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("I64 c=a; b=ToBool(c++); return c+10*b;",0,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("I64 c=a; b=ToBool(c++); return c+10*b;",1,0,12,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("Bool c=ToBool(a); return c;",256,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(0.0)+2*ToBool(-0.0)+4*ToBool(0.5)+8*ToBool(-0.5);",0,0,14,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(0)+2*ToBool(0x100000000);",0,0,2,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(a&b);",0x100000000,0x100000000,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return ToBool(a(U8 *));",0x80000000,0,1,&cursor,
    "#include \"/Kernel/I386/Bool.HH\"");
  EmitCase("return a&&b;",0x100000000,42,1,&cursor);
  EmitCase("return a||b;",0,0x100000000,1,&cursor);
  EmitCase("return a&&b;",42,0,0,&cursor);
  EmitCase("return a||b;",0,0,0,&cursor);
  EmitCase("return a^^b;",0x100000000,1,0,&cursor);
  EmitCase("return a^^b;",0,0x100000000,1,&cursor);
  EmitCase("a&&b++; return b;",0,42,43,&cursor);
  EmitCase("a||b++; return b;",1,42,43,&cursor);
  EmitCase("a&&b++; return b;",1,42,43,&cursor);
  EmitCase("a||b++; return b;",0,42,43,&cursor);
  EmitCase("if (a&&(1/b)) return 1; return 0;",0,0,0,&cursor);
  EmitCase("if (a||(1/b)) return 1; return 0;",1,0,1,&cursor);
  EmitCase("return (a&&b)||(!a&&b);",0,42,1,&cursor);
  EmitCase("if (a&&b) return 7; return 9;",1,1,7,&cursor);
  EmitCase("if (a||b) return 7; return 9;",0,0,9,&cursor);
  EmitCase("return a||(Add(a,b)&&b);",0,2,1,&cursor,
    "extern I64 Add(I64 a,I64 b);", "I64 Add(I64 a,I64 b) { return a+b; }");
  EmitCase("I64 (*fp)(I64 x,I64 y); fp=&Test; if (a<=1) return b; return (*fp)(a-1,a*b);",5,1,120,&cursor);
  EmitCase("I64 (*fp)(I64 x,I64 y); fp=&Test; if (!a) return b; return b+(*fp)(0,b);",1,0x100000001,0x200000002,&cursor);
  EmitCase("I64 (*fp)(I64 x,I64 y); fp=&Test; if (!a) return b; return (*fp)(0,(*fp)(0,b));",1,42,42,&cursor);
  EmitCase("if (!a) return b; return Invoke(&Test,0,b);",1,0x10000002A,0x10000002A,&cursor,
    "extern I64 Invoke(I64 (*fp)(I64 x,I64 y),I64 a,I64 b);",
    "I64 Invoke(I64 (*fp)(I64 x,I64 y),I64 a,I64 b) { return (*fp)(a,b); }");
  EmitCase("class P { I64 (*fp)(I64 x,I64 y); }; P p; p.fp=&Test; if (!a) return b; return (*p.fp)(0,b);",1,42,42,&cursor);
  EmitCase("I64 (*fp)(I64 x,I64 y); fp=&Add; return (*fp)(a,b);",0xFFFFFFFF,1,0x100000000,&cursor,
    "extern I64 Add(I64 x,I64 y);", "I64 Add(I64 x,I64 y) { return x+y; }");
  EmitCase("return Invoke(a);",255,0,-1,&cursor,
    "extern I64 Invoke(I64 a);",
    "I64 Slot(I8 a) { return a(I64); } I64 Invoke(I64 a) { I64 (*fp)(I8 x); fp=&Slot; return (*fp)(a); }");
  EmitCase("return Invoke();",0,0,42,&cursor,
    "extern I64 Invoke();",
    "I64 Value() { return 42; } I64 Invoke() { I64 (*fp)(); fp=&Value; return (*fp)(); }");
  EmitCase("U0 (*fp)(I64 *p,I64 x); fp=&Store; (*fp)(&a,b); return a;",0,0x123456789ABCDEF0,0x123456789ABCDEF0,&cursor,
    "extern U0 Store(I64 *p,I64 x);", "U0 Store(I64 *p,I64 x) { *p=x; }");
  EmitCase("I8 (*fp)(I64 x); fp=&Byte; return (*fp)(a);",255,0,-1,&cursor,
    "extern I8 Byte(I64 x);", "I8 Byte(I64 x) { return x; }");
  EmitCase("class P { I64 (*fp)(I64 x,I64 y); }; P p[2]; p[0].fp=&Add; p[1].fp=&Sub; return (*p[1].fp)(a,b)+(*p[0].fp)(a,b);",0x100000000,3,0x200000000,&cursor,
    "extern I64 Add(I64 x,I64 y); extern I64 Sub(I64 x,I64 y);",
    "I64 Add(I64 x,I64 y) { return x+y; } I64 Sub(I64 x,I64 y) { return x-y; }");
  EmitCase("I64 (*fp)(I64 x,I64 y=7); fp=&Add; return (*fp)(a);",35,0,42,&cursor,
    "extern I64 Add(I64 x,I64 y);", "I64 Add(I64 x,I64 y) { return x+y; }");
  EmitCase("P p; P *ptr=&p; p.value=a; return (ptr)->value+b;",0x100000000,3,0x100000003,&cursor,
    "class P { I64 value; P *next; U8 bytes[4]; };");
  EmitCase("P p; P *ptr=&p,**pp=&ptr; p.value=a; (*pp)->value+=b; return p.value;",0x100000000,3,0x100000003,&cursor,
    "class P { I64 value; P *next; U8 bytes[4]; };");
  EmitCase("P p,q; P *ptr=&p,**pp=&ptr,**link; p.value=a; p.next=&q; q.value=b; link=&(*pp)->next; *link=&p; return p.next->value;",0x100000005,9,0x100000005,&cursor,
    "class P { I64 value; P *next; U8 bytes[4]; };");
  EmitCase("P p; (&p)->bytes[2]=a; return (&p)->bytes[2];",0x1FE,0,254,&cursor,
    "class P { I64 value; P *next; U8 bytes[4]; };");
  EmitCase("P p; p.value=a; return (Get(&p))->value+b;",0x100000000,3,0x100000003,&cursor,
    "class P { I64 value; P *next; U8 bytes[4]; }; extern P *Get(P *p);",
    "P *Get(P *p) { return p; }");
  //Variadic callers own all slots, including hidden argc; argv retains raw values.
  EmitCase("return Sum(a);",42,0,42,&cursor,
    "extern I64 Sum(I64 base,...);",
    "I64 Sum(I64 base,...) { I64 i; for(i=0;i<argc;i++) base+=argv[i]; return base; }");
  EmitCase("return Sum(a,b);",4294967296,42,4294967338,&cursor,
    "extern I64 Sum(I64 base,...);",
    "I64 Sum(I64 base,...) { I64 i; for(i=0;i<argc;i++) base+=argv[i]; return base; }");
  EmitCase("return Sum(a,1,2,3,b);",30,6,42,&cursor,
    "extern I64 Sum(I64 base,...);",
    "I64 Sum(I64 base,...) { I64 i; for(i=0;i<argc;i++) base+=argv[i]; return base; }");
  EmitCase("return a+Sum(1,Sum(2,3,b),4);",10,22,42,&cursor,
    "extern I64 Sum(I64 base,...);",
    "I64 Sum(I64 base,...) { I64 i; for(i=0;i<argc;i++) base+=argv[i]; return base; }");
  EmitCase("I64 i,c=0; for(i=0;i<100;i++) c+=Sum(a,i,b); return c;",1,2,5250,&cursor,
    "extern I64 Sum(I64 base,...);",
    "I64 Sum(I64 base,...) { I64 i; for(i=0;i<argc;i++) base+=argv[i]; return base; }");
  EmitCase("return Sum(a++,a++,a++);",1,0,6,&cursor,
    "extern I64 Sum(I64 base,...);",
    "I64 Sum(I64 base,...) { I64 i; for(i=0;i<argc;i++) base+=argv[i]; return base; }");
  EmitCase("I64 (*fp)(I64 base,...); fp=&Sum; return (*fp)(a,b,2);",30,10,42,&cursor,
    "extern I64 Sum(I64 base,...);",
    "I64 Sum(I64 base,...) { I64 i; for(i=0;i<argc;i++) base+=argv[i]; return base; }");
  EmitCase("I64 (*fp)(I64 base,...); fp=&Sum; return a+(*fp)(2,(*fp)(3,b),4);",10,23,42,&cursor,
    "extern I64 Sum(I64 base,...);",
    "I64 Sum(I64 base,...) { I64 i; for(i=0;i<argc;i++) base+=argv[i]; return base; }");
  EmitCase("return Count();",0,0,0,&cursor,
    "extern I64 Count(...);",
    "I64 Count(...) { return argc; }");
  EmitCase("return Count(a,b,1,2,3);",0,0,5,&cursor,
    "extern I64 Count(...);",
    "I64 Count(...) { return argc; }");
  EmitCase("return Small(a,b);",255,43,42,&cursor,
    "extern I64 Small(I8 a,...);",
    "I64 Small(I8 a,...) { return a+argv[0]; }");
  EmitCase("return Bits(1.5);",0,0,4609434218613702656,&cursor,
    "extern I64 Bits(...);",
    "I64 Bits(...) { return argv[0]; }");
  EmitCase("return Address(&a);",42,0,42,&cursor,
    "extern I64 Address(...);",
    "I64 Address(...) { I64 *p=argv[0]; return *p; }");
  EmitCase("return Sum();",0,0,7,&cursor,
    "extern I64 Sum(I64 base=7,...);",
    "I64 Sum(I64 base=7,...) { return base+argc; }");
  EmitCase("return Recur(a,b);",5,37,42,&cursor,
    "extern I64 Recur(I64 n,...);",
    "I64 Recur(I64 n,...) { if (!n) return argv[0]; return Recur(n-1,argv[0])+argc; }");
  EmitCase("return Keep(a,b);",1,41,42,&cursor,
    "extern I64 Keep(I64 n,...);",
    "I64 Keep(I64 n,...) { if (!n) return argv[0]; argv[0]+=Keep(0,n); return argv[0]; }");
  //Native try registration/cleanup lowering; these providers do not unwind.
  EmitCase("try { a++; } catch { State(3); } return State(0);",0,0,101,&cursor,
    "extern U0 SysTry(U8 *c,U8 *u); extern U0 SysUntry(); extern I64 State(I64 action);",
    "I64 State(I64 action) { static I64 entered=0,exited=0,bad=0; if(action==1) entered++; if(action==2) exited++; if(action==3) bad++; return entered*100+exited+bad*10000; } U0 SysTry(U8 *c,U8 *u) { State(1); if(!c||!u||c==u) State(3); } U0 SysUntry() { State(2); }");
  EmitCase("try { try { a++; } catch { State(3); } } catch { State(3); } return State(0);",0,0,202,&cursor,
    "extern U0 SysTry(U8 *c,U8 *u); extern U0 SysUntry(); extern I64 State(I64 action);",
    "I64 State(I64 action) { static I64 entered=0,exited=0,bad=0; if(action==1) entered++; if(action==2) exited++; if(action==3) bad++; return entered*100+exited+bad*10000; } U0 SysTry(U8 *c,U8 *u) { State(1); if(!c||!u||c==u) State(3); } U0 SysUntry() { State(2); }");
  EmitCase("return Inner()+State(0);",0,0,143,&cursor,
    "extern U0 SysTry(U8 *c,U8 *u); extern U0 SysUntry(); extern I64 State(I64 action); extern I64 Inner();",
    "I64 State(I64 action) { static I64 entered=0,exited=0,bad=0; if(action==1) entered++; if(action==2) exited++; if(action==3) bad++; return entered*100+exited+bad*10000; } U0 SysTry(U8 *c,U8 *u) { State(1); if(!c||!u||c==u) State(3); } U0 SysUntry() { State(2); } I64 Inner() { try { return 42; } catch { State(3); } return 0; }");
  EmitCase("return Inner()+State(0);",0,0,244,&cursor,
    "extern U0 SysTry(U8 *c,U8 *u); extern U0 SysUntry(); extern I64 State(I64 action); extern I64 Inner();",
    "I64 State(I64 action) { static I64 entered=0,exited=0,bad=0; if(action==1) entered++; if(action==2) exited++; if(action==3) bad++; return entered*100+exited+bad*10000; } U0 SysTry(U8 *c,U8 *u) { State(1); if(!c||!u||c==u) State(3); } U0 SysUntry() { State(2); } I64 Inner() { try { try { return 42; } catch { State(3); } } catch { State(3); } return 0; }");
  EmitCase("I64 i; for(i=0;i<3;i++) { try { a++; } catch { State(3); } } return State(0);",0,0,303,&cursor,
    "extern U0 SysTry(U8 *c,U8 *u); extern U0 SysUntry(); extern I64 State(I64 action);",
    "I64 State(I64 action) { static I64 entered=0,exited=0,bad=0; if(action==1) entered++; if(action==2) exited++; if(action==3) bad++; return entered*100+exited+bad*10000; } U0 SysTry(U8 *c,U8 *u) { State(1); if(!c||!u||c==u) State(3); } U0 SysUntry() { State(2); }");
  //Frame-pointer ABI and bounded traversal for exception/diagnostic consumers.
  EmitCase("return (&a+0)(U64)-(GetRBP+0)(U64);",0x100000000,42,8,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("return (&b+0)(U64)-(GetRBP+0)(U64);",0x100000000,42,16,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("CI386Frame f[2]; return I386FrameValid(&f[0],f,sizeof(f))+2*I386FrameValid(&f[1],f,sizeof(f));",0x100000000,42,3,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("CI386Frame f[2]; f[0].parent=&f[1]; return I386FrameParent(f,f,sizeof(f))==&f[1];",0x100000000,42,1,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("CI386Frame f[2]; f[1].parent=&f[0]; return I386FrameParent(&f[1],f,sizeof(f))==NULL;",0x100000000,42,1,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("CI386Frame f; f.parent=&f; return I386FrameParent(&f,&f,sizeof(f))==NULL;",0x100000000,42,1,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("CI386Frame f; return I386FrameValid(&f,&f,7)+I386FrameValid(&f,&f,-1);",0x100000000,42,0,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("CI386Frame f[2]; return I386FrameValid((f(U8 *)+1)(CI386Frame *),f,sizeof(f));",0x100000000,42,0,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("return I386FrameValid(0xFFFFFFF8,0xFFFFFFF8,8)+2*I386FrameValid(0xFFFFFFF8,0xFFFFFFF8,9);",0x100000000,42,1,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("return I386FrameParent(NULL,NULL,0)==NULL && I386FrameReturn(NULL,NULL,0)==NULL;",0x100000000,42,1,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("CI386Frame f; f.parent=NULL; f.return_address=0xFEDCBA98; return (I386FrameReturn(&f,&f,sizeof(f))+0)(U64);",0x100000000,42,4275878552,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  EmitCase("return Probe(a,b);",0x100000000,42,4294967338,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0\nextern I64 Probe(I64 x,I64 y);",
    "#include \"/Kernel/I386/Frame.HC\"\nI64 Probe(I64 x,I64 y) { CI386Frame *me=GetRBP,*parent=me->parent,*found; I64 size=(parent(U8 *)+8)-me(U8 *); found=I386FrameParent(me,me,size); if(found!=parent || !I386FrameReturn(me,me,size)) return -1; return (found(U8 *)+8)(I64 *)[0]+(found(U8 *)+16)(I64 *)[0]; }");
  EmitCase("CI386Frame f[2]; f[0].parent=(f(U8 *)+4)(CI386Frame *); return I386FrameParent(f,f,sizeof(f))==NULL;",0,0,1,&cursor,
    "#include \"/Kernel/I386/Frame.HH\"\n#define TRUE 1\n#define FALSE 0\n#define NULL 0",
    "#include \"/Kernel/I386/Frame.HC\"");
  //Switch tables must retain 64-bit selectors and HolyC prefix/footer semantics.
  EmitSwitchCase("switch(a) { case 1: return 11; case 3: return 33; default: return 99; }",1,0,11,&cursor);
  EmitSwitchCase("switch(a) { case 1: return 11; case 3: return 33; default: return 99; }",3,0,33,&cursor);
  EmitSwitchCase("switch(a) { case 1: return 11; case 3: return 33; default: return 99; }",2,0,99,&cursor);
  EmitSwitchCase("switch(a) { case 1: return 11; case 3: return 33; default: return 99; }",0,0,99,&cursor);
  EmitSwitchCase("switch(a) { case 1: return 11; case 3: return 33; default: return 99; }",-1,0,99,&cursor);
  EmitSwitchCase("switch(a) { case 1: return 11; case 3: return 33; default: return 99; }",4294967297,0,99,&cursor);
  EmitSwitchCase("switch(a) { case -3...-1: return 7; default: return 9; }",-2,0,7,&cursor);
  EmitSwitchCase("switch(a) { case 0x100000000...0x100000002: return 7; default: return 9; }",4294967297,0,7,&cursor);
  EmitSwitchCase("switch(a) { case 0x100000000...0x100000002: return 7; default: return 9; }",1,0,9,&cursor);
  EmitSwitchCase("switch(a) { case 0x7FFFFFFFFFFFFFFF...0x7FFFFFFFFFFFFFFF: return 17; default: return 23; }",0x7FFFFFFFFFFFFFFF,0,17,&cursor);
  EmitSwitchCase("switch(a) { case 5...3: return 7; default: return 9; }",4,0,7,&cursor);
  EmitSwitchCase("switch(a) { case: return 7; case: return 8; default: return 9; }",1,0,8,&cursor);
  EmitSwitchCase("switch(a) { case 1: b+=10; case 2: b+=20; break; default: b=99; } return b;",1,0,30,&cursor);
  EmitSwitchCase("switch(a) { case 1: b+=10; break; } return b;",2,42,42,&cursor);
  EmitSwitchCase("switch(a++) { case 1: b=10; break; default: b=20; } return a+b;",1,0,12,&cursor);
  EmitSwitchCase("switch[a] { case 2: return 12; case 3: return 13; } return 99;",3,0,13,&cursor);
  EmitSwitchCase("switch(a) { case 1: switch(b) { case 2: return 42; default: return 7; } default: return 9; }",1,2,42,&cursor);
  EmitSwitchCase("switch(a) { start: b+=100; case 1: b+=1; break; case 2: b+=2; break; end: b+=1000; } return b;",1,0,1101,&cursor);
  EmitSwitchCase("switch(a) { start: b+=100; case 1: b+=1; case 2: b+=2; break; end: b+=1000; } return b;",1,0,1103,&cursor);
  //Returning from a prefix has a native frame-restoration test.
  EmitCase("switch(a) { start: if(b) return b+5; case 1: b+=1; break; end: b+=1000; } return b;",1,37,42,&cursor);
  EmitSwitchCase("switch(a) { start: b+=100; start: b+=10; case 1: b+=1; break; end: b+=1000; end: b+=10000; } return b;",1,0,11111,&cursor);
  //Reserved expected value tells the isolated runner to require vector 0.
  //QEMU unassigned ports test input widths; VGA sequencer tests actual writes.
  EmitCase("return InU8(a);",1280,0,255,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("return InU16(a);",1280,0,65535,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("return InU32(a);",1280,0,4294967295,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("OutU8(a,b); return InU8(a);",1280,-1,255,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("OutU16(a,b); return InU16(a);",1280,-1,65535,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("OutU32(a,b); return InU32(a);",1280,-1,4294967295,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("OutU8(a,2); OutU8(a+1,b); return InU8(a+1);",1099511628740,4294967301,5,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("OutU16(a,b); return InU8(a+1)+InU8(a+1);",964,3842,30,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("OutU8(a,InU8(a)); return b+InU8(a);",0x500,0x100000000,0x1000000FF,&cursor,
    "#include \"/Kernel/I386/Ports.HH\"\n");
  EmitCase("U64 quotient=a; return ModU64(&quotient,b);",42,0,0xDEADBEEFCAFEBABE,&cursor,
    "#include \"/Kernel/I386/Math.HH\"");
  EmitCase("return a/b;",42,0,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a%b;",42,0,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a/b;",0x8000000000000000,-1,0xDEADBEEFCAFEBABE,&cursor);
  EmitCase("return a%b;",0x8000000000000000,-1,0xDEADBEEFCAFEBABE,&cursor);
  Reject("#include \"/Kernel/Types.HH\"\nF64 Test(F64 a,I64 b) { return a+b; }");
  Reject("#include \"/Kernel/Types.HH\"\nextern I64 Missing(I64 a,I64 b); I64 Test(I64 a,I64 b) { return Missing(a,b); }");
  Reject("#include \"/Kernel/Types.HH\"\nextern I64 Missing(); I64 Test() { I64 (*fp)(); fp=&Missing; return (*fp)(); }");
  Reject("#exe { 1+2; }");
  EmitLinkedCase(0xFFFFFFFF,1,0x100000000,&cursor,FALSE);
  EmitLinkedCase(0x100000000,42,0x10000002A,&cursor,TRUE);
  EmitCase("return DimProbe(0,0)+DimProbe(1,0)+DimProbe(3,0)+DimProbe(1,1)+DimProbe(3,1);",0,0,5,&cursor,
    "extern I64 DimProbe(I64 count,I64 empty_first);", "#include \"/ArrayDims.HC\"\n");
  EmitSwitchCase("switch(a){case 89-1:return 42;default:return 0;}",88,0,42,&cursor);
  EmitCase("I64 values[2+3];return sizeof(values);",0,0,40,&cursor);
  EmitCase("return DefaultValue;",0,0,42,&cursor,
    "extern I64 DefaultValue(I64 n=(89-1)/2-2);",
    "I64 DefaultValue(I64 n){return n;}");
  //Original x64 execution is the oracle for these public string intrinsics.
  EmitSwitchCase("return StrLen(\"\");",0,0,0,&cursor,"_intern 0x84 I64 StrLen(U8 *st);");
  EmitSwitchCase("return StrLen(\"VGA\")+StrLen(\"adapter\"+2);",0,0,8,&cursor,"_intern 0x84 I64 StrLen(U8 *st);");
  EmitSwitchCase("U8 s[4];s[0]=128;s[1]=255;s[2]=0;s[3]=1;return StrLen(s);",0,0,2,&cursor,"_intern 0x84 I64 StrLen(U8 *st);");
  EmitSwitchCase("U8 s[3];s[0]=65;s[1]=66;s[2]=0;U8 *p=s;return StrLen(p++)*10+(p-s);",0,0,21,&cursor,"_intern 0x84 I64 StrLen(U8 *st);");
  EmitSwitchCase("U8 s[1025];I64 i;for(i=0;i<1024;i++)s[i]=255;s[1024]=0;return StrLen(s)+StrLen(s+1024);",0,0,1024,&cursor,"_intern 0x84 I64 StrLen(U8 *st);");
  EmitSwitchCase("U8 s[3];s[0]=65;s[1]=0;s[2]=66;return 0x100000000+StrLen(s+StrLen(s));",0,0,0x100000000,&cursor,"_intern 0x84 I64 StrLen(U8 *st);");
  *cursor(U32 *)=0; cursor+=4;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",data,cursor-data);
  Report(line);
  Report("DONE i386 functions\n");
}
CompileTests;
