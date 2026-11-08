#include "/Compiler/ControlInit.HC"

#include "/Compiler/LexFiles.HC"
#include "/Compiler/ControlRelease.HC"
U0 LexFileSystemFree(U8 *context,U8 *allocation)
{
  Free(allocation);
}
U0 LexFileSystemDocDel(U8 *context,CDoc *document)
{
  DocDel(document);
}
#include "/Compiler/LexFilePushCore.HC"
CLexFile *LexFilePop(CCmpCtrl *cc)
{
  CLexFileRelease owner;
  owner.context=0; owner.allocation=&LexFileSystemFree; owner.document=&LexFileSystemDocDel;
  return LexFileReleaseTop(cc,&owner);
}

CCmpCtrl *CmpCtrlNew(U8 *buf=NULL,I64 flags=0,U8 *filename=NULL)
{//MAlloc and Init CCmpCtrl.
//Frees buf in $LK,"CmpCtrlDel",A="MN:CmpCtrlDel"$ unless $LK,"CCF_DONT_FREE_BUF",A="MN:CCF_DONT_FREE_BUF"$ flag is set.
  //FileName is for error reporting.  If files are #included,
  //new names are used.  See $LK,"Psalmody CmpCtrlNew",A="FF:::/Apps/Psalmody/PsalmodyFile.HC,CmpCtrlNew"$.
  CCmpCtrl *cc=CAlloc(sizeof(CCmpCtrl));
  CLexFile *tmpf;
  U32 *alpha_numeric;
  if (flags&CCF_KEEP_AT_SIGN)
    alpha_numeric=char_bmp_alpha_numeric_no_at;
  else
    alpha_numeric=char_bmp_alpha_numeric;
  CmpCtrlSeed(cc,flags,Fs->hash_table,alpha_numeric);
  tmpf=LexFilePush(cc);
  if (filename)
    tmpf->full_name=FileNameAbs(filename);
  else
    tmpf->full_name=StrNew(blkdev.tmp_filename);
  if (flags & CCF_PMT)
    buf=CAlloc(8);
  LexFileSeed(tmpf,buf);
  cc->cur_buf_ptr=buf;
  return cc;
}

U0 CmpCtrlDel(CCmpCtrl *cc)
{//Free CCmpCtrl.
  CLexFileRelease owner;
  owner.context=0; owner.allocation=&LexFileSystemFree; owner.document=&LexFileSystemDocDel;
  CmpCtrlRelease(cc,&owner);
}

I64 CmpCtrlSize(CCmpCtrl *cc)
{//Mem size of CCmpCtrl and its members.
  CLexFile *tmpf=cc->lex_include_stk;
  I64 res=0;
  while (tmpf) {
    if (tmpf->next || !(cc->flags & CCF_DONT_FREE_BUF)) {
      if (tmpf->flags & LFSF_DOC) {
	if (tmpf->doc)
	  res+=DocSize(tmpf->doc);
      } else
	res+=MSize2(tmpf->buf);
    }
    res+=MSize2(tmpf->full_name);
    res+=MSize2(tmpf);
    tmpf=tmpf->next;
  }
  res+=MSize2(cc->cur_str);
  res+=MSize2(cc);
  return res;
}

