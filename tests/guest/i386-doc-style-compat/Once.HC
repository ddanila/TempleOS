U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }

U0 NativeStyleCompatibilityRead()
{
  CDoc *doc=DocRead("T:/NativeColor.DD");
  U8 *saved,*line;
  I64 size;
  if(!doc) { Report("FAIL original styled document read\n"); return; }
  saved=DocSave(doc,&size);
  if(!saved || size<=0) {
    Report("FAIL original styled document save\n");
    return;
  }
  line=MStrPrint("EXPORT OriginalStyleRoundTrip.DD %X %X\n",saved,size);
  Report(line);
  Free(line);
  DocPutKey(doc,'!');
  saved=DocSave(doc,&size);
  DocDel(doc);
  if(!saved || size<=0) {
    Report("FAIL original styled document edit\n");
    return;
  }
  line=MStrPrint("EXPORT OriginalAuthoredStyle.DD %X %X\n",saved,size);
  Report(line);
  Free(line);
  // QMP exports these buffers after reading the debug log; keep both live.
  Report("DONE original styled document compatibility\n");
}

NativeStyleCompatibilityRead;
