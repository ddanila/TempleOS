I64 CopyTree2(CDirEntry *tmpde,I64 src_dir_len,I64 dst_dir_len,U8 *dst_dir)
{
  U8 *st;
  I64 res=1;
  while (tmpde) {
    st=MAlloc(StrLen(tmpde->full_name)+dst_dir_len+2);
    MemCpy(st,dst_dir,dst_dir_len);
    StrCpy(st+dst_dir_len,tmpde->full_name+src_dir_len);
    if (tmpde->attr & RS_ATTR_DIR) {
      DirMk(st,LinkedLstCnt(tmpde->sub));
      res+=CopyTree2(tmpde->sub,src_dir_len,dst_dir_len,dst_dir);
    } else
      if (CopySingle(tmpde->full_name,st))
	res++;
    Free(st);
    tmpde=tmpde->next;
  }
  return res;
}
public I64 CopyTree(U8 *src_files_find_mask,U8 *dst_files_find_mask,
	Bool no_mask=TRUE)
{//Copy directory tree.
//Returns the count of copied files (not dirs).
  CDirContext *dirc;
  CDirEntry *tmpde=NULL;
  I64 res=0,i1,i2;
  U8 *st1,*st2;

  st1=DirNameAbs(src_files_find_mask);
  st2=DirNameAbs(dst_files_find_mask);
  i1=StrLen(st1);
  if (!StrNCmp(st1,st2,i1) && (st2[i1]=='/' || !st2[i1]) ) {
    Free(st1);
    Free(st2);
    return 0;
  }
  Free(st1);
  Free(st2);
  if (dirc=DirContextNew(src_files_find_mask,TRUE,,no_mask)) {
    tmpde=FilesFind(dirc->mask,FUF_RECURSE);
    st1=DirCur;
    DirContextDel(dirc);
    i1=StrLen(st1);
    if (i1==3) i1--;
    if (dirc=DirContextNew(dst_files_find_mask,TRUE,TRUE)) {
      st2=DirCur;
      i2=StrLen(st2);
      if (i2==3) i2--;
      res=CopyTree2(tmpde,i1,i2,st2);
      DirContextDel(dirc);
      Free(st2);
    }
    DirTreeDel(tmpde);
    Free(st1);
  }
  return res;
}

