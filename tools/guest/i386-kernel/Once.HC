#include "/Kernel/I386/Module.HH"
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
#include "/Kernel/I386/StrCopyCheck.HC"
#include "/Kernel/I386/QueueCheck.HC"
#include "/Kernel/I386/HashTableCheck.HC"
#include "/Kernel/I386/DefineListCheck.HC"
#include "/Kernel/I386/DefineLookupCheck.HC"
#include "/Kernel/I386/DocInitCheck.HC"
#include "/Kernel/I386/DocEntryAllocCheck.HC"
#include "/Kernel/I386/DocFormNavCheck.HC"
#include "/Kernel/I386/DocEntryLifeCheck.HC"
#include "/Kernel/I386/BitEquCheck.HC"
#include "/Kernel/I386/DocRecordCheck.HC"
#include "/Kernel/I386/DocAccessCheck.HC"
#include "T:/DocDefaultsOracle.HC"
#include "T:/TextBaseOracle.HC"
#include "T:/TextRenderOracle.HC"
extern I64 Bcd2Bin(U64 value);
#include "/Kernel/I386/DateCheck.HC"
#include "/Kernel/I386/GraphicsContextCheck.HC"
#include "T:/DateOracle.HC"
#include "/Kernel/I386/HelpFileCheck.HH"
Bool OriginalHelpFileCheck()
{
  CCmpCtrl *cc=CmpCtrlNew(I386_HELP_FILE_CHECK_SOURCE,CCF_DONT_FREE_BUF,"C:/Probe/PublicHeaders.HC");
  CHashSrcSym *help;
  U8 *name=FileNameAbs("::/Doc/ProbeHelp.DD.Z");
  Bool result;
  if(Lex(cc)!=TK_EOF) { Free(name); CmpCtrlDel(cc); return FALSE; }
  help=HashFind(name,cc->htc.glbl_hash_table,HTT_HELP_FILE);
  if(help) { Report("ORIGINAL HELP SOURCE "); Report(help->src_link); Report(" "); Report(help->idx); Report("\n"); }
  result=help && help->idx && !StrCmp(help->idx,"Second") && help->src_link &&
    !StrCmp(help->src_link,"FL:C:/Probe/PublicHeaders.HC,5") && (help->type&HTF_PUBLIC);
  while(help=HashFind(name,cc->htc.glbl_hash_table,HTT_HELP_FILE))
    HashRemDel(help,cc->htc.glbl_hash_table);
  Free(name); CmpCtrlDel(cc); return result;
}
U0 BuildKernel()
{
  U8 *source,*modules[12],*image,*name,*line;
  I64 sizes[12],size,errors,i;
  Report("START kernel cross-build\n");
  if(!StrCopyCheck(&StrCpy)) { Report("FAIL original StrCpy\n"); return; }
  Report("PASS original StrCpy\n");
  if(BitEquCheck(&BEqu,&LBEqu)!=168) { Report("FAIL original bit assignment\n"); return; }
  Report("PASS original bit assignment\n");
  if(QueueCheck!=9) { Report("FAIL original queues\n"); return; }
  Report("PASS original queues\n");
  if(HashTableCheck(&HashTableNew,&HashTableDel,&HashLstAdd,&HashFind,&MHeapCtrl)!=10) { Report("FAIL original public tables\n"); return; }
  Report("PASS original public tables\n");
  if(DefineListCheck(&DefineLstLoad,&HashDefineLstAdd,&HashTableNew,&HashTableDel,&HashDel,&HashFind)!=6) { Report("FAIL original define list\n"); return; }
  Report("PASS original define list\n");
  if(DefineLookupCheck!=16) { Report("FAIL original definition lookup\n"); return; }
  for(i=0;i<4;i++) if(DefineMissingCheck(i)!=1) { Report("FAIL original missing definition\n"); return; }
  Report("PASS original definition lookup\n");
  if(DocInitCheck!=137) { Report("FAIL original document initialization\n"); return; }
  Report("PASS original document initialization\n");
  if(DocEntryAllocCheck!=8 || DocFormNavCheck!=8) { Report("FAIL original document entries\n"); return; }
  Report("PASS original document entries\n");
  if(DocEntryLifeCheck!=8) { Report("FAIL original document entry lifetime\n"); return; }
  Report("PASS original document entry lifetime\n");
  if(OriginalTextBaseCheck!=256) { Report("FAIL original text base\n"); return; }
  Report("PASS original text base\n");
  if(OriginalTextRenderCheck!=12) { Report("FAIL original text rendering\n"); return; }
  Report("PASS original text rendering\n");
  i=GraphicsContextCheck;
  if(i!=20) { line=MStrPrint("FAIL graphics context %d\n",i); Report(line); Free(line); return; }
  Report("PASS original graphics context\n");
  i=DateCheck; errors=OriginalDateCheck;
  line=MStrPrint("DATE RESULTS %d %d\n",i,errors); Report(line); Free(line);
  if(i!=1333 || errors!=146) { Report("FAIL date conversion\n"); return; }
  Report("PASS date conversion\n");
  if(DocRecordCheck!=4) { Report("FAIL original document records\n"); return; }
  Report("PASS original document records\n");
  if(DocAccessCheck(&DocPut,&DocDisplay,&DocBorder)!=8) { Report("FAIL original document selection\n"); return; }
  Report("PASS original document selection\n");
  if(!OriginalDocDefaultsCheck) { Report("FAIL original document defaults\n"); return; }
  Report("PASS original document defaults\n");
  if(!OriginalHelpFileCheck) { Report("FAIL original help metadata\n"); return; }
  Report("PASS original help metadata\n");
  for(i=0;i<12;i++) {
    switch(i) {
      case 0: name="Kernel"; break;
      case 1: name="SysTry"; break;
      case 2: name="TaskContext"; break;
      case 3: name="ExceptContext"; break;
      case 4: name="IrqEntry"; break;
      case 5: name="ExceptionEntry"; break;
      case 6: name="Startup"; break;
      case 7: name="CompilerRuntime"; break;
      case 8: name="CompilerProbe"; break;
      case 9: name="FileRuntime"; break;
      case 10: name="ConsoleRuntime"; break;
      case 11: name="MemoryRuntime"; break;
    }
    line=MStrPrint("/Kernel/I386/%s.HC",name);
    source=FileRead(line); Free(line);
    modules[i]=CmpI386Module(source,&sizes[i],&errors); Free(source);
    if(!modules[i] || errors) {
      source=DocSave(DocPut,&size);
      line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
      Report("FAIL kernel cross-build\n"); return;
    }
    line=MStrPrint("EXPORT %s.t32m %X %X\n",name,modules[i],sizes[i]); Report(line);
  }
  image=I386Link(modules,sizes,6,&size,"Main",0x11000);
  if(!image) { Report("FAIL kernel link\n"); return; }
  line=MStrPrint("EXPORT Kernel32.BIN %X %X\n",image,size); Report(line);
  source=FileRead("T:/IncludeInner.HC",&size);
  image=CompressBuf(source,size);
  if(image(CArcCompress *)->compression_type!=CT_7_BIT) { Report("FAIL include archive mode\n"); return; }
  line=MStrPrint("EXPORT IncludeInner.HC.Z %X %X\n",image,image(CArcCompress *)->compressed_size); Report(line);
  Report("DONE kernel cross-build\n");
}
BuildKernel;
