#include "/Kernel/I386/Module.HH"
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
U0 BuildKernel()
{
  U8 *source,*modules[6],*image,*name,*line;
  I64 sizes[6],size,errors,i;
  Report("START kernel cross-build\n");
  for(i=0;i<6;i++) {
    switch(i) {
      case 0: name="Kernel"; break;
      case 1: name="SysTry"; break;
      case 2: name="TaskContext"; break;
      case 3: name="ExceptContext"; break;
      case 4: name="IrqEntry"; break;
      case 5: name="ExceptionEntry"; break;
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
  image=I386Link(modules,sizes,6,&size);
  if(!image) { Report("FAIL kernel link\n"); return; }
  line=MStrPrint("EXPORT Kernel32.BIN %X %X\n",image,size); Report(line);
  Report("DONE kernel cross-build\n");
}
BuildKernel;
