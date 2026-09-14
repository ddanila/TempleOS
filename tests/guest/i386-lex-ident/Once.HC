#include "/Compiler/ControlInit.HH"
#include "/Compiler/LexIdent.HH"
I64 IdentToken(CCmpCtrl *cc,U8 *output,I64 *lines)
{
  I64 i,token=Lex(cc);
  if(token==TK_IDENT) for(i=0;i<cc->cur_str_len;i++) output[i]=cc->cur_str[i];
  Free(cc->cur_str); cc->cur_str=0;
  return token;
}
#include "T:/Cases.HC"
#include "T:/Lookup.HC"
#include "T:/Failures.HC"
#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native lex ident\n");
  if(IdentLookupTest) { Report("FAIL x64 identifier lookup\n"); return; }
  if(IdentFailureTest) { Report("FAIL x64 identifier reader failure\n"); return; }
  if(IdentTest) { Report("FAIL x64 identifiers\n"); return; }
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL lex ident compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL lex ident link\n"); return; }
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
  Report("DONE native lex ident\n");
}
CompileTests;
