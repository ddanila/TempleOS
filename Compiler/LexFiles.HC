#include "/Compiler/LexFiles.HH"
U0 LexBackupLastChar(CCmpCtrl *cc)
{
  CLexFile *tmpf=cc->lex_include_stk;
  tmpf->buf_ptr=cc->cur_buf_ptr;
  if (cc->flags & CCF_USE_LAST_U16) {
    tmpf->last_U16=cc->last_U16;
    cc->flags&=~CCF_USE_LAST_U16;
  } else
    tmpf->last_U16=0;
}


CLexFile *LexFileAttach(CCmpCtrl *cc,CLexFile *file)
{
  if(file->next=cc->lex_include_stk) file->depth=file->next->depth+1;
  else file->depth=-1;
  return cc->lex_include_stk=file;
}
CLexFile *LexFileReleaseTop(CCmpCtrl *cc,CLexFileRelease *owner)
{
  CLexFile *file;
  if(file=cc->lex_include_stk) {
    if((cc->lex_include_stk=file->next) || !(cc->flags&CCF_DONT_FREE_BUF)) {
      if(file->flags&LFSF_DOC) {
        if(file->doc) (*owner->document)(owner->context,file->doc);
      } else (*owner->allocation)(owner->context,file->buf);
    }
    (*owner->allocation)(owner->context,file->full_name);
    (*owner->allocation)(owner->context,file);
  }
  return cc->lex_include_stk;
}
