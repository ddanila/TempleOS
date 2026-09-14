#include "/Compiler/ControlInit.HH"
#include "T:/Bitmaps.HC"
U8 *StateAlloc(I64 size) { return CAlloc(size); }
U0 StateFree(U8 *allocation) { Free(allocation); }
Bool StatePush(CCmpCtrl *cc) { LexPush(cc); return TRUE; }
Bool StatePop(CCmpCtrl *cc,Bool restore) { if(restore) LexPopRestore(cc); else LexPopNoRestore(cc); return TRUE; }
#include "T:/State.HC"
#include "/Compiler/LexFiles.HH"
#include "T:/Files.HC"
#include "/Compiler/LexInput.HH"
CLexFile *InputPush(CCmpCtrl *cc) { return LexFileAttach(cc,StateAlloc(sizeof(CLexFile))); }
Bool InputPop(CCmpCtrl *cc)
{
  CLexFileRelease owner;
  owner.context=&file_alloc_frees; owner.allocation=&FileTestFree; owner.document=&FileTestDoc;
  LexFileReleaseTop(cc,&owner); return TRUE;
}
I64 InputRead(CCmpCtrl *cc,I64 *lines)
{
  I64 before=cmp.compiled_lines,ch=LexGetChar(cc);
  *lines=*lines+cmp.compiled_lines-before; return ch;
}
#include "T:/Input.HC"
I64 DocumentInputTest()
{
  CCmpCtrl *cc=CmpCtrlNew;
  CDoc *document=DocNew;
  U8 *expected="a\tb\nc";
  I64 i,result=0;
  DocPrint(document,"a\tb\nc");
  LexAttachDoc(cc,,document);
  if(!(cc->lex_include_stk->flags&LFSF_DOC)) result=1;
  for(i=0;i<5;i++) if(LexGetChar(cc)!=expected[i]) result=2;
  CmpCtrlDel(cc); return result;
}

#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native lex state\n");
  if(CharBitmapsTest) { Report("FAIL x64 character bitmaps\n"); return; }
  if(LexRawInputTest) { Report("FAIL x64 raw input\n"); return; }
  if(DocumentInputTest) { Report("FAIL x64 document input\n"); return; }
  if(LexFilesTest) { Report("FAIL x64 lexical files\n"); return; }
  if(LexStateTest) { Report("FAIL x64 lexer snapshots\n"); return; }
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL lex state compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL lex state link\n"); return; }
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
  Report("DONE native lex state\n");
}
CompileTests;
