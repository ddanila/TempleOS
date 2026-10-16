//Capture original terminal creation, welcome insertion and retained settings.
U0 Report(U8 *text) { while (*text) OutU8(0xE9,*text++); }
U0 ExportDoc(U8 *name)
{
  I64 size;
  U8 *data=DocSave(DocPut,&size),*line;
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);
  Report(line); Free(line);
  //Keep exported buffers alive until the host captures guest memory.
}
U0 TerminalStartReference()
{
  DocTermNew;
  if (DocPut!=DocDisplay || DocPut->max_entries!=4096 ||
      !Fs->border_doc || !Fs->cur_menu || IsRaw) {
    Report("FAIL original terminal initialization\n"); return;
  }
  ExportDoc("terminal-empty.DD");
  if (!Type("::/Doc/Start.DD")) {
    Report("FAIL original welcome Type\n"); return;
  }
  ExportDoc("terminal-welcome.DD");
  DocClear;
  ExportDoc("terminal-cleared.DD");
  Report("DONE original terminal startup documents\n");
}
TerminalStartReference;
