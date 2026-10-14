//Run against the original kernel/compiler and repaired original assets.
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
U0 CaptureStr(U8 *name,U8 *input,U8 *dft=NULL,I64 flags=0)
{
  U8 *st,*line;
  DocClear;
  In("%s",input);
  st=GetStr(NULL,dft,flags);
  line=MStrPrint("EXPORT %s %X %X\n",name,st,StrLen(st)+1);
  Report(line); Free(line);
  //Keep exported memory alive until the host has captured it.
}
CaptureStr("single.bin","alpha\n");
CaptureStr("empty.bin","\n");
CaptureStr("default.bin","\n","fallback");
CaptureStr("multiline.bin","alpha\nbeta\n\x1B",NULL,GSF_WITH_NEW_LINE);
CaptureStr("cancel.bin","discard\x1C");
CaptureStr("cancel-default.bin","discard\x1C","fallback");
Report("DONE original GetStr basic input\n");
