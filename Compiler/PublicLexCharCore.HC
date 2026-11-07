Bool LexDollar(CCmpCtrl *cc,CDoc *doc,CDocEntry *doc_e)
{
  U8 *st;
  if (cc->flags&CCF_IN_QUOTES) {
    Free(cc->dollar_buf);
    st=Doc2PlainText(doc,doc_e);
    cc->dollar_buf=MStrPrint("$$%$$Q$$",st);
    cc->dollar_cnt=2;
    Free(st);
    return TRUE;
  } else
    return FALSE;
}

#include "/Compiler/LexInput.HC"

I64 LexGetChar(CCmpCtrl *cc)
{//Get one char from stream. Allow put-back one.
  U8 *ptr,*src;
  CLexFile *tmpf;
  CDoc *doc;
  CDocEntry *doc_e;
  if (!Btr(&cc->flags,CCf_USE_LAST_U16)) {
lgc_start1:
    if(LexBufferStep(cc,&cmp.compiled_lines,&src)) goto lgc_done;
lgc_here:
	tmpf=cc->lex_include_stk;
	if (tmpf->flags & LFSF_DOC) {
	  doc=tmpf->doc;
	  doc_e=tmpf->cur_entry;
	  doc_e=doc_e->next;
lgc_start2:
	  if (doc_e!=doc) {
	    tmpf->cur_entry=doc_e;
	    switch [doc_e->type_u8] {
	      case DOCT_TEXT:
		if (doc_e->de_flags & ~(DOCEF_TAG|DOCEF_DEFINE|DOCEF_TAG_CB|
		      DOCG_BL_IV_UL|DOCEF_WORD_WRAP|DOCEF_HIGHLIGHT|
		      DOCEF_SKIP|DOCEF_FILTER_SKIP) &&
		      LexDollar(cc,doc,doc_e) && *(src=cc->dollar_buf)) {
		  tmpf->line_num=doc_e->y+1;
		  tmpf->buf_ptr=cc->cur_buf_ptr=src;
		} else if (*(src=doc_e->tag))
		  tmpf->buf_ptr=cc->cur_buf_ptr=src;
		else {
		  doc_e=doc_e->next;
		  goto lgc_start2;
		}
		break;
	      case DOCT_NEW_LINE:
		tmpf->buf_ptr=cc->cur_buf_ptr=&lex_zeros;
		tmpf->line_start=doc_e->next;
		tmpf->line_num=doc_e->y+2;//+1 because NEW_LINE is on prev line
//+1 because doc y starts at zero
		cmp.compiled_lines++;
		cc->last_U16='\n';
		goto lgc_done;
	      case DOCT_TAB:
		tmpf->buf_ptr=cc->cur_buf_ptr=&lex_zeros;
		tmpf->line_num=doc_e->y+1;
		cc->last_U16='\t';
		goto lgc_done;
	      case DOCT_INS_BIN:
		tmpf->buf_ptr=cc->cur_buf_ptr=&lex_zeros;
		tmpf->line_num=doc_e->y+1;
		Free(cc->cur_str);
		cc->cur_str=NULL;
		cc->cur_str_len=0;
		if (doc_e->bin_data) {
		  ptr=MAlloc(doc_e->bin_data->size);
		  if (doc_e->bin_data->data)
		    MemCpy(ptr,doc_e->bin_data->data,doc_e->bin_data->size);
		  cc->cur_str=ptr;
		  cc->cur_str_len=doc_e->bin_data->size;
		}
		cc->last_U16=TK_INS_BIN;
		goto lgc_done;
	      case DOCT_INS_BIN_SIZE:
		tmpf->buf_ptr=cc->cur_buf_ptr=&lex_zeros;
		if (doc_e->bin_data)
		  cc->cur_i64=doc_e->bin_data->size;
		else
		  cc->cur_i64=0;
		tmpf->line_num=doc_e->y+1;
		cc->last_U16=TK_INS_BIN_SIZE;
		goto lgc_done;
	      case DOCT_SHIFTED_Y:
		if (LexDollar(cc,doc,doc_e) && *(src=cc->dollar_buf)) {
		  tmpf->line_num=doc_e->y+1;
		  tmpf->buf_ptr=cc->cur_buf_ptr=src;
		} else {
		  tmpf->buf_ptr=cc->cur_buf_ptr=&lex_zeros;
		  tmpf->line_num=doc_e->y+1;
		  if (doc_e->attr<0)
		    cc->last_U16=TK_SUPERSCRIPT;
		  else if (doc_e->attr>0)
		    cc->last_U16=TK_SUBSCRIPT;
		  else
		    cc->last_U16=TK_NORMALSCRIPT;
		  goto lgc_done;
		}
		break;
	      case DOCT_MARKER:
	      case DOCT_CURSOR:
		doc_e=doc_e->next;
		goto lgc_start2;
	      case 0xFF: //nobound switch
	      default:
		if (LexDollar(cc,doc,doc_e) && *(src=cc->dollar_buf)) {
		  tmpf->line_num=doc_e->y+1;
		  tmpf->buf_ptr=cc->cur_buf_ptr=src;
		} else {
		  doc_e=doc_e->next;
		  goto lgc_start2;
		}
	    }
	  }
	  if (doc_e!=doc)
	    goto lgc_start1;
	  tmpf->cur_entry=doc->head.last; //When take next, will still be end.
	}
	tmpf=cc->lex_include_stk;
	if (tmpf->next) {
	  tmpf=LexFilePop(cc);
	  cc->cur_buf_ptr=tmpf->buf_ptr;
	  cc->flags&=~CCF_USE_LAST_U16;
	  if (!(cc->last_U16=tmpf->last_U16))
	    goto lgc_start1;
	} else {
	  if (cc->flags & CCF_PMT) {
	    Free(tmpf->buf);
	    ptr=CmdLinePmt;
	    if (StrCmp(ptr,"\n") && !cc->pmt_line++ && !StrCmp(ptr,"?\n") &&
		cc->flags & CCF_QUESTION_HELP) {
	      Free(ptr);
	      ptr=StrNew("Help;;\n");
	    }
	    tmpf->buf=tmpf->buf_ptr=tmpf->line_start=cc->cur_buf_ptr=ptr;
	    goto lgc_start1;
	  } else {
	    if (src)
	      cc->cur_buf_ptr=src-1;
	    cc->last_U16=TK_EOF;
	  }
	}
lgc_done:
    LexNormalizeChar(cc);
    if (cc->opts & OPTF_ECHO &&
	  cc->last_U16<256 && Bt(char_bmp_printable,cc->last_U16))
      '' cc->last_U16;
  }
  return cc->last_U16;
}

