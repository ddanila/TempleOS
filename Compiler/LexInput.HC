#include "/Compiler/LexInput.HH"
//Live zero-terminated buffer (or null), active file, counters and output pointer.
//False reaches a buffer boundary; the caller owns file/document/prompt transitions.
Bool LexBufferStep(CCmpCtrl *cc,I64 *compiled_lines,U8 **end)
{
  U8 *source;
  CLexFile *file;
  while(TRUE) {
    source=cc->cur_buf_ptr;
    if(!source) { *end=0; return FALSE; }
    cc->cur_buf_ptr=source+1; *end=source+1;
    cc->last_U16=*source;
    if(!cc->last_U16) return FALSE;
    if(cc->last_U16!=CH_CURSOR) {
      if(cc->last_U16=='\n') {
        file=cc->lex_include_stk;
        if(!(file->flags&LFSF_DOC)) {
          file->line_num++;
          *compiled_lines=*compiled_lines+1;
          file->line_start=source+1;
        }
      }
      return TRUE;
    }
  }
}
U0 LexNormalizeChar(CCmpCtrl *cc)
{
  if(cc->last_U16==CH_SHIFT_SPACE) cc->last_U16=CH_SPACE;
}
