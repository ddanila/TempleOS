#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Compiler/LexInput.HC"
I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines)
{
  CLexFile *file;
  U8 *end;
  if(!cc || !compiled_lines || !cc->lex_include_stk || cc->flags&CCF_PMT || cc->opts&OPTF_ECHO) return -1;
  if(cc->lex_include_stk->flags&LFSF_DOC) return -1;
  if(Btr(&cc->flags,CCf_USE_LAST_U16)) {
    return cc->last_U16;
  }
  while(TRUE) {
    if(LexBufferStep(cc,compiled_lines,&end)) {
      LexNormalizeChar(cc); return cc->last_U16;
    }
    file=cc->lex_include_stk;
    if(file->next) {
      if(file->next->flags&LFSF_DOC || !I386LexFilePop(heap,cc)) {
        if(end) cc->cur_buf_ptr=end-1;
        return -1;
      }
      file=cc->lex_include_stk; cc->cur_buf_ptr=file->buf_ptr;
      cc->flags&=~CCF_USE_LAST_U16;
      if(cc->last_U16=file->last_U16) {
        LexNormalizeChar(cc); return cc->last_U16;
      }
    } else {
      if(end) cc->cur_buf_ptr=end-1;
      cc->last_U16=TK_EOF; return TK_EOF;
    }
  }
}

I64 I386LexSourceRead(U8 *context,CCmpCtrl *cc)
{
  CI386LexCharSource *source=context;
  return I386LexRawChar(source->heap,cc,source->compiled_lines);
}
