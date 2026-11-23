#include "/Kernel/I386/Module.HH"
U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
U0 CrossOptimizer()
{
  I64 size=0,errors=0;
  U8 *source=FileRead("/Kernel/I386/CompilerRuntime.HC"),*module=NULL,*line;
  Report("START implicit F64 helper cross\n");
  try {module=CmpI386Module(source,&size,&errors);}
  catch {Fs->catch_except=TRUE;Report("CAUGHT optimizer cross exception\n");}
  Free(source);
  if(!module || errors){U8 *diagnostic=DocSave(DocPut,&size);line=MStrPrint("EXPORT compiler-log.DD %X %X\n",diagnostic,size);Report(line);Report("FAIL implicit F64 helper compilation\n");return;}
  line=MStrPrint("EXPORT CompilerRuntime.t32m %X %X\n",module,size);
  Report(line);Free(line);
  Report("DONE implicit F64 helper cross\n");
}
CrossOptimizer;
