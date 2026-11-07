#include "/Compiler/LexZeroCore.HC"

CDoc *LexDocRead(U8 *abs_filename,I64 flags)
{
  CDoc *doc=DocNew(abs_filename);
  U8 *src;
  I64 size=0;
  doc->flags|=flags;
  src=FileRead(abs_filename,&size);
  if (!src || !size) {
    Free(src);
    src=CAlloc(1);
    size=0;
  }
  DocLoad(doc,src,size);
  Free(src);
  return doc;
}

I64 cmp_type_flags_src_code[(DOCT_TYPES_NUM+63)/64]={
  1<<DOCT_TEXT|1<<DOCT_TAB|1<<DOCT_INS_BIN|1<<DOCT_INS_BIN_SIZE};

U0 LexAttachDoc(CCmpCtrl *cc,CLexFile *tmpf=NULL,
	CDoc *doc=NULL,U8 *abs_filename=NULL,CDocEntry *doc_e=NULL,I64 col=0)
{//Start lexing doc. Give either doc or abs_filename.
  if (!doc)
    doc=LexDocRead(abs_filename,DOCF_DBL_DOLLARS);
  if (!tmpf) {
    LexBackupLastChar(cc);
    tmpf=LexFilePush(cc);
  }
  if (!doc_e)
    doc_e=doc->head.next;
  tmpf->full_name=StrNew(doc->filename.name);
  tmpf->doc=doc;
  while (doc_e!=doc) {
    if (Bt(cmp_type_flags_src_code,doc_e->type_u8))
      break;
    doc_e=doc_e->next;
    col=doc_e->min_col;
  }
  if (doc_e!=doc) {
    col=ClampI64(col,doc_e->min_col,doc_e->max_col);
    tmpf->line_start=doc_e;
    tmpf->buf=NULL;
    tmpf->line_num=doc_e->y+1;
    if (doc_e->type_u8==DOCT_TEXT) {
      tmpf->cur_entry=doc_e;
      tmpf->buf_ptr=doc_e->tag;
    } else {
      tmpf->cur_entry=doc_e->last; //TODO: might be problem at begin of file
      tmpf->buf_ptr=&lex_zeros;
    }
    tmpf->flags=LFSF_DOC;
  } else {//TODO: DocDel(doc)?
    col=0;
    tmpf->buf=tmpf->buf_ptr=tmpf->line_start=CAlloc(1);
    tmpf->line_num=1;
    tmpf->flags=0;
  }
  cc->cur_buf_ptr=tmpf->buf_ptr+col;
  tmpf->last_U16=0;
}

