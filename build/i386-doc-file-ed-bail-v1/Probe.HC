U0 DocFileSearchReport(U8 *s)
{
  while (*s) OutU8(0xE9,*s++);
}
U0 DocFileSearchProbe()
{
  I64 line=1,border=Fs->border_src;
  Bool silent=IsSilent;
  if (!DocFileEd(LK_FILE_FIND,"::/Probe/Search.DD","Unique search marker",&line,EDF_UNCOLLAPSE|EDF_BAIL) || line!=2)
    throw('FindHit',TRUE);
  line=1;
  if (DocFileEd(LK_FILE_FIND,"::/Probe/Search.DD","Not in this file",&line,EDF_UNCOLLAPSE|EDF_BAIL))
    throw('FindMiss',TRUE);
  if (Fs->border_src!=border || IsSilent!=silent)
    throw('FindStat',TRUE);
  DocFileSearchReport("DONE DocFileEd bail search\n");
}
DocFileSearchProbe;
