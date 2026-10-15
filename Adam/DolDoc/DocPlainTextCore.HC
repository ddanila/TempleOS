U8 *Doc2PlainText(CDoc *doc,CDocEntry *doc_e)
{//TODO: break strs
  I64 i,j,attr=doc_e->attr,
	t1,f1,de_flags,type;
  U8 *buf,*buf2;

  if (doc_e->type_u8==DOCT_FOREGROUND &&
	doc->flags&DOCF_COLOR_NAMES && 0<=attr<COLORS_NUM) {
    buf=StrNew(DefineSub(attr,"ST_COLORS"));
    attr=DOC_DFT;
  } else
    buf=StrNew(DefineSub(doc_e->type_u8,"ST_DOC_CMDS"));
  if (doc_e->type_u8!=DOCT_ERROR) {
    f1=doldoc.dft_de_flags[doc_e->type_u8];
    t1=doc_e->type_u8|doldoc.dft_type_flags[doc_e->type_u8];

    de_flags=doc_e->de_flags&~(DOCG_BL_IV_UL|DOCEF_SEL|
	  DOCEF_HIGHLIGHT|DOCEF_WORD_WRAP|DOCEF_SKIP|DOCEF_FILTER_SKIP);
    for (i=0;i<DOCEf_FLAGS_NUM;i++)
      if (Bt(&f1,i)!=Bt(&de_flags,i)) {
	if (Bt(&de_flags,i)) {
	  if (!(1<<i&DOCEG_HAS_ARG)) {
	    buf2=MStrPrint("%s+%Z",buf,i,"ST_DOC_FLAGS");
	    Free(buf); buf=buf2;
	  }
	} else {
	  buf2=MStrPrint("%s-%Z",buf,i,"ST_DOC_FLAGS");
	  Free(buf); buf=buf2;
	}
      }
    type=doc_e->type&~DOCET_SEL;
    for (i=DOCEt_BLINK;i<=DOCEt_UNDERLINE;i++)
      if (Bt(&t1,i)!=Bt(&type,i)) {
	if (Bt(&type,i))
	  buf2=MStrPrint("%s+%Z",buf,i,"ST_DOC_FLAGS");
	else
	  buf2=MStrPrint("%s-%Z",buf,i,"ST_DOC_FLAGS");
	Free(buf); buf=buf2;
      }
    buf2=MStrPrint("%s,",buf);
    Free(buf); buf=buf2;
    switch [doc_e->type_u8] {
      case DOCT_HEX_ED:
	buf2=MStrPrint("%s%d,",buf,doc_e->len);
	Free(buf); buf=buf2;
	buf2=MStrPrint("%s%d,",buf,doc_e->hex_ed_width);
	Free(buf); buf=buf2;
	break;
      case DOCT_FOREGROUND:
      case DOCT_BACKGROUND:
      case DOCT_DFT_FOREGROUND:
      case DOCT_DFT_BACKGROUND:
	if (doc->flags&DOCF_COLOR_NAMES && 0<=attr<COLORS_NUM) {
	  buf2=MStrPrint("%s%Z,",buf,doc_e->attr,"ST_COLORS");
	  Free(buf); buf=buf2;
	  break;
	}
      case DOCT_PAGE_LEN:
      case DOCT_LEFT_MARGIN:
      case DOCT_RIGHT_MARGIN:
      case DOCT_HEADER:
      case DOCT_FOOTER:
      case DOCT_INDENT:
      case DOCT_WORD_WRAP:
      case DOCT_HIGHLIGHT:
      case DOCT_BLINK:
      case DOCT_INVERT:
      case DOCT_UNDERLINE:
      case DOCT_SHIFTED_X:
      case DOCT_SHIFTED_Y:
	if (attr!=DOC_DFT) {
	  buf2=MStrPrint("%s%d,",buf,doc_e->attr);
	  Free(buf); buf=buf2;
	}
      case DOCT_TYPES_NUM-1: //nobound switch
	break;
    }
    de_flags=doc_e->de_flags & DOCEG_HAS_ARG;
    while (de_flags) {
      j=Bsf(de_flags);
      Btr(&de_flags,j);
      switch [j] {
	case DOCEf_TAG:
	  if (doc_e->type_u8==DOCT_DATA || doc_e->type_u8==DOCT_MACRO &&
		(doc_e->de_flags&DOCEF_LEFT_MACRO &&
		!StrCmp(doc_e->tag,doc_e->left_macro) ||
		doc_e->de_flags&DOCEF_RIGHT_MACRO &&
		!StrCmp(doc_e->tag,doc_e->right_macro)) ||
		doc_e->de_flags&DOCEF_LST && !StrCmp(doc_e->tag,"[]") &&
		doc_e->de_flags&DOCEF_DEFINE) {
	    buf2=buf;
	    buf=NULL;
	  } else {
	    if (doc_e->type_u8==DOCT_CHECK_BOX) {
	      if (StrLen(doc_e->tag)>=4)
		buf2=doc_e->tag+4;
	      else
		buf2="";
	    } else if (doc_e->de_flags & DOCEF_TREE) {
	      if (StrLen(doc_e->tag)>=3)
		buf2=doc_e->tag+3;
	      else
		buf2="";
	    } else
	      buf2=doc_e->tag;
	    if (Bt(&doldoc.dft_de_flags[doc_e->type_u8],DOCEf_TAG))
	      buf2=MStrPrint("%s\"%$$Q\",",buf,buf2);
	    else
	      buf2=MStrPrint("%sT=\"%$$Q\",",buf,buf2);
	  }
	  break;
	case DOCEf_LEN:
	  buf2=MStrPrint("%sLEN=%d,",buf,doc_e->len);
	  break;
	case DOCEf_AUX_STR:
	  buf2=MStrPrint("%sA=\"%$$Q\",",buf,doc_e->aux_str);
	  break;
	case DOCEf_DEFINE:
	  buf2=MStrPrint("%sD=\"%$$Q\",",buf,doc_e->define_str);
	  break;
	case DOCEf_HTML_LINK:
	  buf2=MStrPrint("%sHTML=\"%$$Q\",",buf,doc_e->html_link);
	  break;
	case DOCEf_LEFT_EXP:
	  buf2=MStrPrint("%sLE=%d,",buf,doc_e->left_exp);
	  break;
	case DOCEf_LEFT_MACRO:
	  buf2=MStrPrint("%sLM=\"%$$Q\",",buf,doc_e->left_macro);
	  break;
	case DOCEf_RIGHT_EXP:
	  buf2=MStrPrint("%sRE=%d,",buf,doc_e->right_exp);
	  break;
	case DOCEf_RIGHT_MACRO:
	  buf2=MStrPrint("%sRM=\"%$$Q\",",buf,doc_e->right_macro);
	  break;
	case DOCEf_HAS_BIN:
	  buf2=MStrPrint("%sBI=%d,",buf,doc_e->bin_num);
	  break;
	case DOCEf_BIN_PTR_LINK:
	  buf2=MStrPrint("%sBP=\"%$$Q\",",buf,doc_e->bin_ptr_link);
	  break;
	case DOCEf_RAW_TYPE:
	  if (doc_e->type_u8==DOCT_CHECK_BOX&&doc_e->raw_type!=RT_I8 ||
		doc_e->type_u8!=DOCT_CHECK_BOX&&doc_e->raw_type!=RT_I64)
	    buf2=MStrPrint("%sRT=%Z,",buf,doc_e->raw_type,"ST_RAW_TYPES");
	  break;
	case DOCEf_SHIFTED_X:
	  j=doc_e->type.u16[1]&0x1F;
	  if (j&0x10) j|=0xFFFFFFF0;
	  buf2=MStrPrint("%sSX=%d,",buf,j);
	  break;
	case DOCEf_SHIFTED_Y:
	  j=doc_e->type>>21 &0x1F;
	  if (j&0x10) j|=0xFFFFFFF0;
	  buf2=MStrPrint("%sSY=%d,",buf,j);
	  break;
	case DOCEf_SCROLLING_X:
	  buf2=MStrPrint("%sSCX=%d,",buf,doc_e->scroll_len);
	  break;
	case DOCEf_USER_DATA:
	  buf2=MStrPrint("%sU=0x%X,",buf,doc_e->user_data);
	  break;
	case DOCEf_FLAGS_NUM-1: //nobound switch
	  break;
      }
      Free(buf); buf=buf2;
    }
    buf[StrLen(buf)-1]=0;  //Kill last comma
  }
  buf2=StrNew(buf,doc->mem_task); //exact allocation
  Free(buf);
  return buf2;
}

