public Bool Copy(U8 *src_files_find_mask,U8 *dst_files_find_mask=".")
{//Copy files.
//If the name ends in ".Z", it will
  //be stored compressed.  If not ".Z"
  //it will be stored uncompressed.
  Bool res=TRUE;
  CDirContext *dirc;
  CDirEntry *tmpde,*tmpde1;
  U8 *st;
  if (!(tmpde1=FilesFind(src_files_find_mask,FUF_CLUS_ORDER)))
    return FALSE;
  if (IsDir(dst_files_find_mask)) {
    if (dirc=DirContextNew(dst_files_find_mask,TRUE)) {
      tmpde=tmpde1;
      while (tmpde) {
	if (!(tmpde->attr & RS_ATTR_DIR)) {
	  st=FileNameAbs(tmpde->name);
	  if (!CopySingle(tmpde->full_name,st))
	    res=FALSE;
	  Free(st);
	}
	tmpde=tmpde->next;
      }
      DirContextDel(dirc);
    }
    DirTreeDel(tmpde1);
    return res;
  } else {
    DirTreeDel(tmpde1);
    return CopySingle(src_files_find_mask,dst_files_find_mask);
  }
}

public Bool Move(U8 *f1,U8 *f2)
{//Move files from one location to another or rename.
  if (Copy(f1,f2)) {
    Del(f1);
    return TRUE;
  }
  return FALSE;
}
