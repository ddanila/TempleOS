// Runs only in the isolated rebuild-test ISO, never the normal desktop image.
U0 Report(U8 *s)
{
  while (*s) OutU8(0xE9,*s++);
}
U0 Export(U8 *name,U8 *path)
{
  I64 size;
  U8 *data=FileRead(path,&size),*line;
  if (!data) { Report("FAIL export\n"); return; }
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);
  Report(line);
  Free(line);
  // Keep exported buffers live until the host saves physical memory.
}
U0 Rebuild()
{
  I64 errors;
  Report("START rebuild\n");
  CopyTree("T:/","B:/");
  Cd("B:/");
  Report("STAGE compiler\n");
  errors=Cmp("B:/Compiler/Compiler","Compiler",,'B');
  if (errors) { Report("FAIL compiler\n"); return; }
  Export("Compiler.BIN","B:/Compiler/Compiler.BIN.Z");
  Report("STAGE kernel\n");
  In("TB\nScale2Mem(2048,0x40000)\nT \n\n\n\n");
  errors=Cmp("B:/Kernel/Kernel","Kernel",,'B');
  if (errors) { Report("FAIL kernel\n"); return; }
  Export("Kernel.BIN","B:/Kernel/Kernel.BIN.Z");
  Report("DONE rebuild\n");
}
Rebuild;
