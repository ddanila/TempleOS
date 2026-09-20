#include "/Kernel/I386/Module.HH"
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
#include "/Kernel/I386/StrCopyCheck.HC"
#include "/Kernel/I386/QueueCheck.HC"
U0 BuildKernel()
{
  U8 *source,*modules[12],*image,*name,*line;
  I64 sizes[12],size,errors,i;
  Report("START kernel cross-build\n");
  if(!StrCopyCheck(&StrCpy)) { Report("FAIL original StrCpy\n"); return; }
  Report("PASS original StrCpy\n");
  if(QueueCheck!=9) { Report("FAIL original queues\n"); return; }
  Report("PASS original queues\n");
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
