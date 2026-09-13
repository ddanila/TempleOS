U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 Export(U8 *name,U8 *data,I64 size)
{
  U8 *line=MStrPrint("EXPORT %s %X %X\n",name,data,size);
  Report(line); Free(line);
}
U0 CompileTests()
{
  CAOT *aot;
  CAOTImportExport *ie;
  I64 errors,size;
  U8 *module,*line;
  Report("START target module validator\n");
  aot=CmpI386Buf("#include \"/Kernel/Types.HH\"\n#define TRUE 1\n#define FALSE 0\n#define U32_MAX 0xFFFFFFFF\nextern Bool I386ModuleValid(U8 *data,I64 size); I64 Test(I64 a,I64 b) { return I386ModuleValid(a,b); }\n#include \"/Kernel/I386/ModuleCheck.HC\"",&errors);
  if (!aot || errors) { Report("FAIL validator compile\n"); return; }
  for (ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next)
    if (ie->type==IET_REL32_EXPORT) {
      line=MStrPrint("RANGE 0 %X\n",ie->rip); Report(line); Free(line);
    }
  Export("validator.bin",aot->buf,aot->aot_U8s);
  module=CmpI386Module("#include \"/Kernel/Types.HH\"\nimport I64 Add(I64 a,I64 b); I64 Main(I64 a,I64 b) { return Add(a,b); }",&size,&errors);
  if (!module || errors) { Report("FAIL module fixture\n"); return; }
  Export("sample.t32m",module,size);
  Report("DONE target module validator\n");
}
CompileTests;
