#include "/Kernel/I386/Module.HH"
U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
U0 CrossOptimizer()
{
  I64 size=0,errors=0;
  U8 *source=FileRead("/Kernel/I386/OptRuntime.HC"),*module=NULL,*line;
  Report("START full optimizer module cross\n");
  try {module=CmpI386Module(source,&size,&errors);}
  catch {Fs->catch_except=TRUE;Report("CAUGHT optimizer cross exception\n");}
  Free(source);
  if(!module || errors){U8 *diagnostic=DocSave(DocPut,&size);line=MStrPrint("EXPORT compiler-log.DD %X %X\n",diagnostic,size);Report(line);Report("FAIL full optimizer module compilation\n");return;}
  line=MStrPrint("EXPORT OptRuntime.t32m %X %X\n",module,size);
  Report(line);Free(line);
  Report("DONE full optimizer module cross\n");
}
CrossOptimizer;
