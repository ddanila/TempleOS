U0 Report(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 ArchiveWords()
{
  U8 *source,*check,*line;I64 size;CArcCompress *arc;
  source=FileRead("T:/Adam/AutoComplete/ACWords.DATA",&size);
  if(!source) {Report("FAIL autocomplete word source\n");return;}
  arc=CompressBuf(source,size);check=ExpandBuf(arc);
  if(arc->expanded_size!=size || !check || MemCmp(source,check,size)) {
    Report("FAIL autocomplete word archive roundtrip\n");return;
  }
  line=MStrPrint("EXPORT ACWords.DATA.Z %X %X\n",arc,arc->compressed_size);
  Report(line);Free(line);Free(check);Free(arc);Free(source);
  Report("DONE autocomplete word archive\n");
}
ArchiveWords;
