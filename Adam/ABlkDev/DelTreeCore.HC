I64 DelTreeDirs(CDirEntry *tmpde1)
{
  I64 res=0;
  CDirEntry *tmpde2;
  while (tmpde1) {
    tmpde2=tmpde1->next;
    if (tmpde1->attr & RS_ATTR_DIR) {
      if (tmpde1->sub)
	res+=DelTreeDirs(tmpde1->sub);
      res+=Del(tmpde1->full_name,TRUE,TRUE);
    }
    DirEntryDel(tmpde1);
    tmpde1=tmpde2;
  }
  return res;
}
I64 DelTreeFiles(CDirEntry *tmpde1)
{
  I64 res=0;
  CDirEntry *tmpde2;
  while (tmpde1) {
    tmpde2=tmpde1->next;
    if (tmpde1->attr & RS_ATTR_DIR) {
      if (tmpde1->sub)
	res+=DelTreeFiles(tmpde1->sub);
    } else
      res+=Del(tmpde1->full_name,FALSE,TRUE);
    DirEntryDel(tmpde1);
    tmpde1=tmpde2;
  }
  return res;
}
public I64 DelTree(U8 *files_find_mask,U8 *fu_flags=NULL)
{//Delete directory tree.
  I64 res=0,fuf_flags=0;
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),"+r");
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);
  if (IsDir(files_find_mask)) {
    res=DelTreeDirs(FilesFind(files_find_mask,fuf_flags));
    res+=Del(files_find_mask,TRUE,TRUE);
    res+=Del(files_find_mask,FALSE,TRUE);
  } else
    res=DelTreeFiles(FilesFind(files_find_mask,fuf_flags));
  return res;
}

