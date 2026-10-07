#include "/Adam/DolDoc/EdLinkTypes.HH"
#define DFT_ADDR_LINK_BIN_SIZE	64
#ifndef ED_LINK_TMP_FILENAME
#define ED_LINK_TMP_FILENAME blkdev.tmp_filename
#endif

public I64 EdLinkCvt(U8 *link_st,U8 **_filename=NULL,U8 **_needle_str=NULL,
	I64 *_num=NULL,I64 edf_dof_flags=0)
{//$LK,"Editor Link",A="MN:LK_FILE"$--> filename, needle_str and line number.
  U8 *st,*ptr,*src,*filename=NULL,*needle_str=NULL,*filename2;
  I64 res,i,num=1;
  CHashSrcSym *tmph;
  if (!link_st||!*link_st) {
    if (edf_dof_flags&EDF_BAIL)
      return -1;
    link_st=ED_LINK_TMP_FILENAME;
  }
  st=StrNew(link_st);
  res=LK_FILE;
  if (StrLen(st)>3 && st[2]==':') {
    st[2]=0;
    filename2=st+3;
    switch (res=DefineMatch(st,"ST_LINK_TYPES",LMF_IGNORE_CASE)) {
      case LK_MAN_PAGE:
	if (tmph=HashFind(filename2,Fs->hash_table,HTG_SRC_SYM))
	  res=EdLinkCvt(tmph->src_link,&filename,
		&needle_str,&num,edf_dof_flags);
	else
	  res=-1;
	goto lc_done;
      case LK_ADDR:
	if (ptr=StrLastOcc(filename2,",")) {
	  *ptr=0;
	  i=Str2I64(ptr+1);
	} else
	  i=DFT_ADDR_LINK_BIN_SIZE;
	if (ptr=SrcEdLink(ExePrint("%s;",filename2),i)) {
	  res=EdLinkCvt(ptr,&filename,&needle_str,&num,edf_dof_flags);
	  Free(ptr);
	} else
	  res=-1;
	goto lc_done;
      case LK_DEF:
	if (ptr=StrLastOcc(filename2,",")) {
	  *ptr=0;
	  i=Str2I64(ptr+1);
	} else
	  i=-1;
	filename=StrNew(filename2);
	num=i;
	goto lc_done;
      case LK_HELP_INDEX:
	filename=StrNew(filename2);
	goto lc_done;
      case LK_BIBLE_FIND:
	if (ptr=StrLastOcc(filename2,",")) {
	  *ptr=0;
	  src=ptr+1;
	  while (*src) { //We do not allow ending verse
	    if (*src=='-')
	      *src=0;
	    src++;
	  }
	  needle_str=StrNew(ptr+1);
	}
	i=DefineMatch(filename2,"ST_BIBLE_BOOKS",LMF_IGNORE_CASE);
	if (i<0)
	  res=-1;
	else {
	  num=Str2I64(DefineSub(i,"ST_BIBLE_BOOK_LINES"));
	  filename2=BIBLE_FILENAME;
	}
	break;
      case LK_FILE_LINE:
      case LK_PLAIN_LINE:
      case LK_DOC_LINE:
	if (ptr=StrLastOcc(filename2,",")) {
	  *ptr=0;
	  num=Str2I64(ptr+1);
	}
	break;
      case LK_FILE_ANCHOR:
      case LK_DOC_ANCHOR:
	if (ptr=StrLastOcc(filename2,",")) {
	  *ptr=0;
	  needle_str=StrNew(ptr+1);
	}
	break;
      case LK_FILE_FIND:
      case LK_PLAIN_FIND:
      case LK_DOC_FIND:
	if (ptr=StrLastOcc(filename2,",")) {
	  *ptr=0;
	  needle_str=StrNew(ptr+1);
	  if (ptr=StrLastOcc(needle_str,":")) {
	    *ptr=0;
	    num=Str2I64(ptr+1);
	  }
	}
	break;
    }
  } else
    filename2=st;
  if (res>=0) {
    if (LK_DOC<=res<=LK_DOC_LINE)
      filename=StrNew(filename2); //Holds document address as number.
    else
      filename=FileNameAbs(filename2,FUF_Z_OR_NOT_Z);
  }
lc_done:
  Free(st);
  if (_filename)
    *_filename=filename;
  else
    Free(filename);
  if (_needle_str)
    *_needle_str=needle_str;
  else
    Free(needle_str);
  if (_num)
    *_num=num;
  return res;
}
