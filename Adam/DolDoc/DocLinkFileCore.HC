public U8 *DocLinkFile(U8 *link_st,CTask *mem_task=NULL)
{//Return the file for an $LK,"Editor Link Types",A="MN:LK_FILE"$.
  U8 *filename=NULL,*st,*res=NULL;
  if (link_st) {
    switch (EdLinkCvt(link_st,&filename)) {
      case LK_FILE:
      case LK_FILE_ANCHOR:
      case LK_FILE_FIND:
      case LK_FILE_LINE:
      case LK_PLAIN:
      case LK_PLAIN_FIND:
      case LK_PLAIN_LINE:
	st=FileNameAbs(filename,FUF_Z_OR_NOT_Z|FUF_SCAN_PARENTS);
	res=StrNew(st);
	Free(st);
	break;
      case LK_BIBLE_FIND:
	res=StrNew(BIBLE_FILENAME,mem_task);
	break;
    }
    Free(filename);
  }
  return res;
}
