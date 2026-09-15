#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
I64 case_number=0;
U0 EmitData(U8 *source,I64 expected,U8 **cursor,U8 *provider=NULL,Bool reverse=FALSE)
{
  U8 *modules[2],*image,*line,*text,*saved;
  I64 sizes[2],size,errors,count=1,i,j,base=8;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("CASE "); Report(source); Report("\n");
  text=MStrPrint("#include \"/Kernel/Types.HH\"\n%s",source);
  modules[0]=CmpI386Module(text,&sizes[0],&errors); Free(text);
  if (!modules[0] || errors) {
    text=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",text,size); Report(line);
    Report("FAIL data compile\n"); return;
  }
  if (provider) {
    text=MStrPrint("#include \"/Kernel/Types.HH\"\n%s",provider);
    modules[1]=CmpI386Module(text,&sizes[1],&errors); Free(text);
    if (!modules[1] || errors) { Report("FAIL provider compile\n"); return; }
    count=2;
    if (reverse) {
      saved=modules[0]; modules[0]=modules[1]; modules[1]=saved;
      i=sizes[0]; sizes[0]=sizes[1]; sizes[1]=i;
    }
  }
  image=I386Link(modules,sizes,count,&size,"Main",0x40000);
  if (!image) { Report("FAIL data link\n"); return; }
  line=MStrPrint("LINKED %d\n",case_number); Report(line); Free(line);
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++) {
      line=NULL;
      if (r->kind==I386_MODULE_EXPORT)
        line=MStrPrint("RANGE %d %X\n",case_number,base+r->offset);
      else if (r->kind==I386_MODULE_DATA_RANGE)
        line=MStrPrint("DATA %d %X %X\n",case_number,base+r->offset,r->name_offset);
      if (line) { Report(line); Free(line); }
    }
    base+=h->code_size;
    line=MStrPrint("EXPORT data-%d-%d.t32m %X %X\n",case_number,i,modules[i],sizes[i]);
    Report(line); Free(line);
  }
  (*cursor)(U32 *)[0]=size; *cursor+=4;
  (*cursor)(I64 *)[0]=expected; *cursor+=8;
  (*cursor)(I64 *)[0]=0; *cursor+=8;
  (*cursor)(I64 *)[0]=0; *cursor+=8;
  MemCpy(*cursor,image,size); *cursor+=size; Free(image);
  case_number++;
}
U0 RejectLink(U8 *source,U8 *provider=NULL)
{
  U8 *modules[2],*text,*image;
  I64 sizes[2],size,errors,count=1;
  text=MStrPrint("#include \"/Kernel/Types.HH\"\n%s",source);
  modules[0]=CmpI386Module(text,&sizes[0],&errors); Free(text);
  if (!modules[0] || errors) { Report("FAIL rejection fixture\n"); return; }
  if (provider) {
    text=MStrPrint("#include \"/Kernel/Types.HH\"\n%s",provider);
    modules[1]=CmpI386Module(text,&sizes[1],&errors); Free(text);
    if (!modules[1] || errors) { Report("FAIL rejection provider\n"); return; }
    count=2;
  }
  image=I386Link(modules,sizes,count,&size);
  if (image || size) { Report("FAIL accepted invalid data link\n"); return; }
  Free(modules[0]); if (count==2) Free(modules[1]);
}
U0 RejectSource(U8 *source)
{
  U8 *text=MStrPrint("#include \"/Kernel/Types.HH\"\n%s",source);
  I64 errors;
  CAOT *aot=CmpI386Buf(text,&errors);
  Free(text);
  if (aot || !errors) Report("FAIL accepted unsupported initializer\n");
}
Bool host_global_fill_checked;
U0 CheckHostGlobalFill()
{
  U8 old_flag=sys_var_init_flag,old_value=sys_var_init_val;
  host_global_fill_checked=FALSE;
  sys_var_init_flag=TRUE; sys_var_init_val=0xA5;
  try {
    ExePrint("I64 HostGlobalFillRows[2][2]={{1,2},{3,4}}; "
      "if(sizeof(HostGlobalFillRows)==32 && HostGlobalFillRows[0][0]==1 && "
      "HostGlobalFillRows[0][1]==2 && HostGlobalFillRows[1][0]==3 && "
      "HostGlobalFillRows[1][1]==4) host_global_fill_checked=TRUE;");
  } catch {
    sys_var_init_flag=old_flag; sys_var_init_val=old_value;
  }
  sys_var_init_flag=old_flag; sys_var_init_val=old_value;
  if(!host_global_fill_checked) { Report("FAIL host global fill\n"); throw; }
  Report("PASS host global fill\n");
}
U0 CheckPointerPlacement()
{
  U8 *module,*image;
  CI386ModuleHeader *header;
  CI386ModuleRecord *record;
  I64 bytes,size,errors,i,address,pointers=0;
  module=CmpI386Module("#include \"/Kernel/Types.HH\"\nU8 *p=\"A\";I64 Main(I64 a,I64 b){return p[0];}",&bytes,&errors);
  if(!module || errors) { Report("FAIL pointer placement source\n"); return; }
  header=module;
  image=I386Link(&module,&bytes,1,&size);
  if(image || size) { Report("FAIL unknown pointer load address\n"); return; }
  image=I386Link(&module,&bytes,1,&size,"Main",-1);
  if(image || size) { Report("FAIL explicit unknown pointer load address\n"); return; }
  image=I386Link(&module,&bytes,1,&size,"Main",0xFFFFFFF0);
  if(image || size) { Report("FAIL overflowing pointer load address\n"); return; }
  address=0x100000000-8-header->code_size;
  image=I386Link(&module,&bytes,1,&size,"Main",address);
  if(!image || size!=8+header->code_size) { Report("FAIL boundary pointer load address\n"); return; }
  record=module+header->records_offset;
  for(i=0;i<header->record_count;i++,record++)
    if(record->kind==I386_MODULE_POINTER) {
      pointers++;
      if((image+8+record->offset)(U32 *)[0]!=address+8+record->name_offset ||
          (module+32+record->offset)(U32 *)[0]) { Report("FAIL pointer relocation value\n"); return; }
    }
  if(pointers!=1) { Report("FAIL pointer record count\n"); return; }
  Free(image); Free(module); Report("PASS pointer placement\n");
}
U0 CompileTests()
{
  U8 *data=MAlloc(65536),*cursor=data,*line;
  Report("START i386 data\n");
  CheckHostGlobalFill;
  CheckPointerPlacement;
  EmitData("I64 count; I64 Main(I64 a,I64 b) { return count; }",0,&cursor);
  EmitData("I64 count=0x100000000; I64 Main(I64 a,I64 b) { count+=42; return count; }",0x10000002A,&cursor);
  EmitData("U8 *ptr=0; U32 tag=0x12345678; I64 Main(I64 a,I64 b) { ptr=&tag; if (sizeof(ptr)!=4) return -1; return *ptr+tag; }",0x123456F0,&cursor);
  EmitData("extern I64 Next(); I64 Main(I64 a,I64 b) { return Next()+Next(); } I64 Next() { static I64 count=7; return ++count; }",17,&cursor);
  EmitData("I64 values[3]={1,0x100000000,-3}; I64 Main(I64 a,I64 b) { values[0]++; return values[0]+values[1]+values[2]; }",0xFFFFFFFF,&cursor);
  EmitData("I64 values[]={1,2,3}; I64 Main(I64 a,I64 b) { return sizeof(values)+values[0]+values[1]+values[2]; }",30,&cursor);
  EmitData("class P { U8 *ptr; U8 tag; I64 value; }; P p={0,7,0x100000000}; I64 Main(I64 a,I64 b) { return sizeof(P)+p.tag+p.value; }",0x100000014,&cursor);
  EmitData("U8 text[]=\"ABC\"; I64 Main(I64 a,I64 b) { return sizeof(text)+text[0]+text[2]; }",136,&cursor);
  EmitData("U8 *ptr=0x12345678; U32 tag=42; I64 Main(I64 a,I64 b) { return ptr+0; }",0x12345678,&cursor);
  EmitData("I64 (*fp)(I64 x,I64 y); extern I64 Add(I64 x,I64 y); I64 Main(I64 a,I64 b) { fp=&Add; return (*fp)(0xFFFFFFFF,1); } I64 Add(I64 x,I64 y) { return x+y; }",0x100000000,&cursor);
  EmitData("import I64 count; import I64 Add(I64 x); I64 Main(I64 a,I64 b) { count=0x100000000; Add(2); return count+count; }",0x200000004,&cursor,
    "I64 count=7; I64 Add(I64 x) { count+=x; return count; }");
  EmitData("import I64 count; import I64 Add(I64 x); I64 Main(I64 a,I64 b) { count=0x100000000; Add(2); return count+count; }",0x200000004,&cursor,
    "I64 count=7; I64 Add(I64 x) { count+=x; return count; }",TRUE);
  EmitData("import I64 Add(I64 x,I64 y); I64 Main(I64 a,I64 b) { I64 (*fp)(I64 x,I64 y); fp=&Add; return (*fp)(0xFFFFFFFF,1); }",0x100000000,&cursor,
    "I64 Add(I64 x,I64 y) { return x+y; }");
  EmitData("I64 Main(I64 a,I64 b) { static U8 *p[2]={0,0}; if (p[0] || p[1]) return -1; p[1]=&b; *p[1]=42; return sizeof(p)+b; }",50,&cursor);
  EmitData("U8 values[2]={1,255}; I64 Main(I64 a,I64 b) { values[1]=254; values[1]+=3; values[1]<<=2; return values[0]+values[1]; }",5,&cursor);
  EmitData("I64 values[2]={7,-23}; I64 Main(I64 a,I64 b) { values[1]/=4; values[0]%=3; return values[0]+values[1]; }",-4,&cursor);
  EmitData("I64 grid[][2]={{1,2},{3,4}}; I64 Main(I64 a,I64 b) { return sizeof(grid)+grid[0][0]+grid[0][1]+grid[1][0]+grid[1][1]; }",42,&cursor);
  EmitData("class Pair { I64 left; I64 right; }; Pair rows[]={{1,2},{3,4}}; I64 Main(I64 a,I64 b) { return sizeof(rows)+rows[0].left+rows[1].right; }",37,&cursor);
  EmitData("I64 Main(I64 a,I64 b) { static I64 grid[][2]={{1,2},{3,4}}; return sizeof(grid)+grid[0][0]+grid[0][1]+grid[1][0]+grid[1][1]; }",42,&cursor);
  RejectLink("I64 Main;");
  RejectLink("import I64 Add(); I64 Main(I64 a,I64 b) { return Add(); }","I64 Add=42;");
  RejectLink("I64 State; I64 Main(I64 a,I64 b) { return State; }","I64 State() { return 42; }");
  EmitData("U8 *text=\"ABC\"; I64 Main(I64 a,I64 b) { text[1]=90; return sizeof(text)+text[0]+text[1]+text[2]; }",226,&cursor);
  EmitData("I64 Main(I64 a,I64 b){static U8 *text=\"AZ\";return ++text[0];}",66,&cursor);
  EmitData("class S { U8 *a; U32 tag; I8 *b; }; S s={\"ABC\",0x12345678,\"xy\"}; I64 Main(I64 a,I64 b){if(s.tag!=0x12345678 || sizeof(S)!=12)return -1;return s.a[2]+s.b[1];}",188,&cursor);
  EmitData("U8 *names[]={\"ab\",\"cd\"}; I64 Main(I64 a,I64 b){return sizeof(names)+names[0][1]+names[1][0];}",205,&cursor);
  EmitData("U8 *text=\"A\\0B\" \"C\"; I64 Main(I64 a,I64 b){if(text[1] || text[4])return -1;return text[2]+text[3];}",133,&cursor);
  EmitData("U8 *text=\"\"; I64 Main(I64 a,I64 b){return text[0]+42;}",42,&cursor);
  EmitData("import U8 *text; I64 Main(I64 a,I64 b){return text[1];}",121,&cursor,"U8 *text=\"xy\";");
  EmitData("import U8 *text; I64 Main(I64 a,I64 b){return text[1];}",121,&cursor,"U8 *text=\"xy\";",TRUE);
  RejectSource("extern I64 Read(); I64 count=Read(); I64 Main(I64 a,I64 b) { return count; }");
  Report("PASS data rejection cases\n");
  *cursor(U32 *)=0; cursor+=4;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",data,cursor-data); Report(line);
  Report("DONE i386 data\n");
}
CompileTests;
