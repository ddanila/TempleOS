#include "/Kernel/I386/Module.HH"
U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
U0 Cross(U8*name)
{
 I64 size=0,errors=0;U8 *path=MStrPrint("/Kernel/I386/%s.HC",name);
 U8 *source=FileRead(path),*module=NULL,*line;
 module=CmpI386Module(source,&size,&errors);
 if(!module || errors){U8 *diagnostic=DocSave(DocPut,&size);line=MStrPrint("EXPORT compiler-log.DD %X %X\n",diagnostic,size);Report(line);Report("FAIL cross\n");return;}
 line=MStrPrint("EXPORT %s.t32m %X %X\n",name,module,size);Report(line);Free(line);Free(source);Free(path);
}
Cross("FileRuntime");Cross("ConsoleRuntime");Report("DONE raw-header cross\n");
