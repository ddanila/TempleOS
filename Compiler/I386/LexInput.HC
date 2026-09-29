#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Compiler/LexInput.HC"
I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines)
{
  CLexFile *file;
  CDoc *doc;
  CDocEntry *entry;
  CDocBin *bin;
  U8 *binary,*format;
  I64 i;
  U8 *end;
  if(!cc || !compiled_lines || !cc->lex_include_stk || cc->flags&CCF_PMT || cc->opts&OPTF_ECHO) return -1;
  if(Btr(&cc->flags,CCf_USE_LAST_U16)) {
    return cc->last_U16;
  }
  while(TRUE) {
lex_step:
    if(LexBufferStep(cc,compiled_lines,&end)) {
      LexNormalizeChar(cc); return cc->last_U16;
    }
    file=cc->lex_include_stk;
    if(file->flags&LFSF_DOC) {
      doc=file->doc;
      if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL || !file->cur_entry) return -1;
      entry=file->cur_entry->next;
      while(entry!=doc) {
        file->cur_entry=entry;
        file->buf_ptr=cc->cur_buf_ptr=&i386_doc_zero;
        if(entry->type_u8==DOCT_TEXT && entry->tag && *entry->tag) {
          file->buf_ptr=cc->cur_buf_ptr=entry->tag;
          break;
        }
        if(cc->flags&CCF_IN_QUOTES &&
            (entry->type_u8==DOCT_FOREGROUND || entry->type_u8==DOCT_BACKGROUND ||
             entry->type_u8==DOCT_BLINK || entry->type_u8==DOCT_INVERT ||
             entry->type_u8==DOCT_UNDERLINE)) {
          if(cc->dollar_buf && !I386HeapFree(heap,cc->dollar_buf)) return -1;
          cc->dollar_buf=0;
          if(entry->attr!=DOC_DFT) {
            if(entry->attr<0) return -1;
            if(entry->type_u8==DOCT_FOREGROUND ||
                entry->type_u8==DOCT_BACKGROUND) {
              if(entry->attr>15) return -1;
            } else if(entry->attr>1) return -1;
          }
          format=I386HeapAlloc(heap,8,FALSE);
          if(!format) return -1;
          i=0; format[i++]='$$';
          if(entry->type_u8==DOCT_FOREGROUND) {
            format[i++]='F'; format[i++]='G';
          } else if(entry->type_u8==DOCT_BACKGROUND) {
            format[i++]='B'; format[i++]='G';
          } else if(entry->type_u8==DOCT_BLINK) {
            format[i++]='B'; format[i++]='K';
          } else if(entry->type_u8==DOCT_INVERT) {
            format[i++]='I'; format[i++]='V';
          } else {
            format[i++]='U'; format[i++]='L';
          }
          if(entry->attr!=DOC_DFT) {
            format[i++]=',';
            if(entry->attr>=10) format[i++]='1';
            format[i++]='0'+entry->attr%10;
          }
          format[i++]='$$'; format[i]=0;
          cc->dollar_buf=format;
          cc->dollar_cnt=2;
          file->buf_ptr=cc->cur_buf_ptr=format;
          goto lex_step;
        }
        if(entry->type_u8==DOCT_NEW_LINE) {
          file->line_start=entry->next;
          file->line_num=entry->y+2;
          (*compiled_lines)++;
          cc->last_U16='\n'; return cc->last_U16;
        }
        if(entry->type_u8==DOCT_TAB) {
          file->line_num=entry->y+1;
          cc->last_U16='\t'; return cc->last_U16;
        }
        if(entry->type_u8==DOCT_INS_BIN_SIZE) {
          file->line_num=entry->y+1;
          bin=entry->bin_data;
          if(bin) cc->cur_i64=bin->size;
          else cc->cur_i64=0;
          cc->last_U16=TK_INS_BIN_SIZE; return cc->last_U16;
        }
        if(entry->type_u8==DOCT_INS_BIN) {
          file->line_num=entry->y+1;
          if(cc->cur_str && !I386HeapFree(heap,cc->cur_str)) return -1;
          cc->cur_str=0; cc->cur_str_len=0;
          bin=entry->bin_data;
          if(bin && bin->size) {
            binary=I386HeapAlloc(heap,bin->size,FALSE);
            if(!binary) return -1;
            for(i=0;i<bin->size;i++) {
              if(bin->data) binary[i]=bin->data[i];
              else binary[i]=0;
            }
            cc->cur_str=binary; cc->cur_str_len=bin->size;
          }
          cc->last_U16=TK_INS_BIN; return cc->last_U16;
        }
        if(entry->type_u8==DOCT_SHIFTED_Y) {
          file->line_num=entry->y+1;
          if(entry->attr<0) cc->last_U16=TK_SUPERSCRIPT;
          else if(entry->attr>0) cc->last_U16=TK_SUBSCRIPT;
          else cc->last_U16=TK_NORMALSCRIPT;
          return cc->last_U16;
        }
        entry=entry->next;
      }
      if(entry!=doc) goto lex_step;
      cc->last_U16=TK_EOF; return TK_EOF;
    }
    if(file->next) {
      if(!I386LexFilePop(heap,cc)) {
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
