#include "/Compiler/ControlInit.HH"
CHashTable *ConditionalKeywords() { return cmp.asm_hash; }
I64 ConditionalNext(CCmpCtrl *cc,I64 *lines) { return Lex(cc); }
Bool ConditionalFree(CCmpCtrl *cc) { Free(cc->cur_str); cc->cur_str=0; return TRUE; }
#include "T:/Common.HC"
#include "T:/Cases.HC"
#include "T:/Failures.HC"
#include "T:/IncludeSources.HC"
Bool IncludeSourceMatch(U8 *name)
{
  U8 *source=FileRead(name); Bool same=source && !StrCmp(source,IncludeText(name));
  Free(source); return same;
}
U0 IncludePrepare() {}
Bool IncludeLoads(I64 count) { return TRUE; }
I64 IncludeNext(CCmpCtrl *cc,I64 *lines) { return Lex(cc); }
Bool IncludeSymbolFree(CHashSrcSym *entry) { HashDel(entry); return TRUE; }
#include "T:/Includes.HC"
#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native lex cond\n");
  i=ConditionalTest; if(!i) i=ConditionalEdgeTest; if(!i) i=ConditionalFailureTest;
  if(i) { line=MStrPrint("FAIL x64 conditional %d\n",i); Report(line); return; }
  if(!IncludeSourceMatch("T:/First.HC") || !IncludeSourceMatch("T:/Second.HC") ||
      !IncludeSourceMatch("T:/Empty.HC") || !IncludeSourceMatch("T:/Name.HC")) {
    Report("FAIL include source fixtures differ\n"); return;
  }
  i=IncludeTest;
  if(i) { line=MStrPrint("FAIL x64 includes %d\n",i); Report(line); return; }
  Report("PASS x64 include dispatch\n");
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL lex cond compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL lex cond link\n"); return; }
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
  Report("DONE native lex cond\n");
}
CompileTests;
