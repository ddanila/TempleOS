#include "/Compiler/ControlInit.HH"
#include "/Compiler/LexString.HH"
#include "/Compiler/LexChar.HH"
I64 StringSystemRead(U8 *context,CCmpCtrl *cc)
{
  I64 *lines=context,before=cmp.compiled_lines,ch=LexGetChar(cc);
  *lines=*lines+cmp.compiled_lines-before; return ch;
}
I64 StringChunk(CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *lines)
{
  CLexCharSource source;
  source.context=lines; source.read=&StringSystemRead;
  return LexStringChunk(cc,buf,size,done,&source);
}
#include "T:/Strings.HC"
I64 CharToken(CCmpCtrl *cc,I64 *lines) { return Lex(cc); }
#include "T:/CharTests.HC"
#include "T:/Failures.HC"
#include "T:/CharFailures.HC"
#include "T:/Host.HC"
#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native lex string\n");
  if(CharFailureTest) { Report("FAIL x64 character reader failures\n"); return; }
  if(CharTest) { Report("FAIL x64 character constants\n"); return; }
  if(StringTest) { Report("FAIL x64 quoted strings\n"); return; }
  if(StringFailureTest) { Report("FAIL x64 string reader failures\n"); return; }
  if(HostStringTest) { Report("FAIL x64 string tokens\n"); return; }
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL lex string compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL lex string link\n"); return; }
  h=module; r=module+h->records_offset;
  Report("LINKED 0\n");
  for (i=0;i<h->record_count;i++,r++) {
    line=NULL;
    if (r->kind==I386_MODULE_EXPORT)
      line=MStrPrint("RANGE 0 %X\n",8+r->offset);
    else if (r->kind==I386_MODULE_DATA_RANGE)
      line=MStrPrint("DATA 0 %X %X\n",8+r->offset,r->name_offset);
    if (line) { Report(line); Free(line); }
  }
  source=MAlloc(loaded+32);
  source(U32 *)[0]=loaded;
  (source+4)(I64 *)[0]=0;
  (source+12)(I64 *)[0]=0;
  (source+20)(I64 *)[0]=0;
  MemCpy(source+28,image,loaded);
  (source+28+loaded)(U32 *)[0]=0;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",source,loaded+32); Report(line);
  Report("DONE native lex string\n");
}
CompileTests;
