#include "/Compiler/ControlInit.HC"

#include "/Compiler/LexFiles.HC"
U0 LexFileSystemFree(U8 *context,U8 *allocation)
{
  Free(allocation);
}
U0 LexFileSystemDocDel(U8 *context,CDoc *document)
{
  DocDel(document);
}
CLexFile *LexFilePush(CCmpCtrl *cc)
{
  return LexFileAttach(cc,CAlloc(sizeof(CLexFile)));
}
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
  while (LexFilePop(cc));
  LinkedLstDel(cc->lex_prs_stk);
  LinkedLstDel(cc->htc.next);
  Free(cc->ps);
  Free(cc->cur_str);
  Free(cc->cur_help_idx);
  Free(cc->dollar_buf);
  Free(cc);
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

U32 lex_zeros=0;

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

U0 LexSkipEol(CCmpCtrl *cc)
{//$LK,"LexGetChar",A="MN:LexGetChar"$ to NULL until end-of-line.
  I64 ch;
  do ch=$WW,0$LexGetChar(cc);
  while (Bt(char_bmp_non_eol,ch));
}

U8 *LexFirstRem(CCmpCtrl *cc,U8 *marker,I64 _len=NULL)
{//$LK,"LexGetChar",A="MN:LexGetChar"$() chars making str until marker.
  U8 *res,*ptr;
  CQueVectU8 *tmpv=QueVectU8New;
  I64 i,len=0;
  while (TRUE) {
    i=LexGetChar(cc);
    if (!i||StrOcc(marker,i))
      break;
    QueVectU8Put(tmpv,len++,i);
  }
  if (i)
    Bts(&cc->flags,CCf_USE_LAST_U16);
  res=ptr=MAlloc(len+1);
  for (i=0;i<len;i++)
    *ptr++=QueVectU8Get(tmpv,i);
  *ptr=0;
  QueVectU8Del(tmpv);
  if (_len) *_len=len;
  return res;
}

U0 LexIncludeStr(CCmpCtrl *cc,U8 *abs_filename,U8 *src,Bool actual_file)
{
  LexBackupLastChar(cc);
  CLexFile *tmpf=LexFilePush(cc);
  if (actual_file)
    tmpf->full_name=StrNew(abs_filename);
  else
    tmpf->full_name=StrNew(blkdev.tmp_filename);
  tmpf->line_num=1;
  tmpf->buf=tmpf->buf_ptr=tmpf->line_start=cc->cur_buf_ptr=src;
}

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

#include "/Compiler/LexString.HC"
I64 LexSystemChar(U8 *context,CCmpCtrl *cc)
{
  return LexGetChar(cc);
}
I64 LexInStr(CCmpCtrl *cc,U8 *buf,I64 size,Bool *done)
{
  CLexCharSource source;
  source.context=0; source.read=&LexSystemChar;
  return LexStringChunk(cc,buf,size,done,&source);
}

#include "/Compiler/LexNumber.HC"
#include "/Compiler/LexChar.HC"
#include "/Compiler/LexPunct.HC"
#include "/Compiler/LexIdent.HC"

I64 Lex(CCmpCtrl *cc)
{//Fetch next token.
  I64 i,j,k,l,ch;
  CHash *tmph;
  Bool str_done,in_str,punct_finish;
  CLexPunctTables punct_tables;
  CLexCharSource token_source;
  U8 *fbuf,*buf2,*buf3,buf[STR_LEN];
  token_source.context=0; token_source.read=&LexSystemChar;
  punct_tables.first=cmp.dual_U16_tokens1; punct_tables.second=cmp.dual_U16_tokens2;
  punct_tables.third=cmp.dual_U16_tokens3;
  cc->last_line_num=cc->lex_include_stk->line_num;
  while (TRUE) {
lex_cont:
    switch [ch=LexGetChar(cc)] {
      case 0:
	return cc->token=TK_EOF;
      case TK_SUPERSCRIPT:
	ch='>';
	goto lex_ident;
      case TK_SUBSCRIPT:
	ch='<';
	goto lex_ident;
      case TK_NORMALSCRIPT:
	ch='=';
	goto lex_ident;
      case '@':
	if (cc->flags&CCF_KEEP_AT_SIGN) {
	  cc->token=ch;
	  goto lex_end;
	}
      case 'A'...'Z':
      case 'a'...'z':
      case '_':
      case 128...255:
lex_ident:
        i=LexIdentRead(cc,ch,buf,STR_LEN,&token_source);
        if(i==-2) LexExcept(cc,"Ident limited to STR_LEN chars at ");
        tmph=LexIdentFind(cc,buf);
	if (tmph)
	  j=tmph->type;
	else
	  j=0;
	if (j & HTT_DEFINE_STR && !(cc->flags & CCF_NO_DEFINES)) {
	  LexIncludeStr(cc,
		tmph->str,StrNew(tmph(CHashDefineStr *)->data),FALSE);
	  cc->lex_include_stk->flags|=LFSF_DEFINE;
	} else {
	  cc->hash_entry=tmph;
	  Free(cc->cur_str);
	  cc->cur_str=StrNew(buf);
	  cc->cur_str_len=i;
	  cc->token=TK_IDENT;
	  goto lex_end;
	}
	break;
      case '0'...'9':
      case '.':
        LexNumberBody(cc,ch,&token_source);
        goto lex_end;
      case '"':
	cc->flags|=CCF_IN_QUOTES;
	buf2=NULL;
	i=0;
	do {
	  j=LexInStr(cc,buf,STR_LEN,&str_done);
	  buf3=MAlloc(i+j);
	  if (buf2) {
	    MemCpy(buf3,buf2,i);
	    Free(buf2);
	    buf2=buf3;
	    MemCpy(buf2+i,buf,j);
	  } else {
	    buf2=buf3;
	    MemCpy(buf2,buf,j);
	  }
	  i+=j;
	} while (!str_done);
	Free(cc->cur_str);
	cc->cur_str=MAlloc(i);
	MemCpy(cc->cur_str,buf2,i);
	Free(buf2);
	cc->cur_str_len=i;
	cc->flags&=~CCF_IN_QUOTES;
	cc->token=TK_STR;
	goto lex_end;
      case '\'':
	if (cc->flags&CCF_NO_CHAR_CONST)
	  break;
	if(LexCharBody(cc,&token_source)==-2)
	  LexExcept(cc,"Char const limited to 8 chars at ");
	goto lex_end;
      case '#':
	if (cc->flags&CCF_KEEP_SIGN_NUM) {
	  cc->token=ch;
	  goto lex_end;
	}
	if (Lex(cc)!=TK_IDENT)	//skip '#'
	  goto lex_end;
	if (!(tmph=cc->hash_entry))
	  goto lex_end;
	if (!(tmph->type & HTT_KEYWORD))
	  goto lex_end;
	switch (i=tmph(CHashGeneric *)->user_data0) {
	  case KW_INCLUDE:
	    if (Lex(cc)!=TK_STR)
	      goto lex_end;
	    fbuf=ExtDft(cc->cur_str,"HC.Z");
	    buf2=FileNameAbs(fbuf);
	    Free(fbuf);
	    if (Bt(&sys_run_level,RLf_DOC))
	      LexAttachDoc(cc,,,buf2);
	    else
	      LexIncludeStr(cc,buf2,FileRead(buf2),TRUE);
	    Free(buf2);
	    break;
	  case KW_DEFINE:
	    cc->flags|=CCF_NO_DEFINES;
	    if (Lex(cc)==TK_IDENT) {
	      tmph=CAlloc(sizeof(CHashDefineStr));
	      tmph->str=cc->cur_str;
	      cc->cur_str=0;
	      tmph->type=HTT_DEFINE_STR;
	      HashSrcFileSet(cc,tmph);

	      do ch=LexGetChar(cc); //skip space between define name and start
	      while (Bt(char_bmp_non_eol_white_space,ch));

	      i=j=0;
	      buf2=NULL;
	      if (ch) {
		in_str=FALSE;
		do {
		  if (ch=='\\') {
		    if (ch=LexGetChar(cc)) {
		      if (ch!='\r' && ch!='\n') {
			buf[j++]='\\';
			buf[j++]=ch;
		      } else if (ch=='\r' && LexGetChar(cc)!='\n')
			cc->flags|=CCF_USE_LAST_U16;
		    } else {
		      buf[j++]='\\';
		      break;
		    }
		  } else if (ch!='\n') {
		    if (ch=='\"')
		      in_str=!in_str;
		    buf[j++]=ch;
		  } else
		    break;
		  while (ch=LexGetChar(cc)) {
		    if (ch=='/') {
		      ch=LexGetChar(cc);
		      if (ch=='/' && !in_str) {
			do ch=LexGetChar(cc);
			while (Bt(char_bmp_non_eol,ch));
			break;
		      } else {
			buf[j++]='/';
			cc->flags|=CCF_USE_LAST_U16;
		      }
		    } else if (ch=='\\') {
		      if (ch=LexGetChar(cc)) {
			if (ch=='\"') {
			  buf[j++]='\\';
			  buf[j++]=ch;
			} else {
			  cc->flags|=CCF_USE_LAST_U16;
			  ch='\\';
			  break;
			}
		      }
		    } else if (Bt(char_bmp_non_eol,ch)) {
		      if (ch=='\"')
			in_str=!in_str;
		      buf[j++]=ch;
		    } else
		      break;
		    if (j>=STR_LEN-4) {//Spot for ['\'][ch],[ch],[0]
		      buf[j++]=0;
		      buf3=MAlloc(i+j);
		      if (buf2) {
			MemCpy(buf3,buf2,i);
			Free(buf2);
			buf2=buf3;
			MemCpy(buf2+i,buf,j);
		      } else {
			buf2=buf3;
			MemCpy(buf2,buf,j);
		      }
		      i+=j-1;
		      j=0;
		    }
		  }
		} while (ch=='\\');
	      }
	      buf[j++]=0;
	      buf3=MAlloc(i+j);
	      if (buf2) {
		MemCpy(buf3,buf2,i);
		Free(buf2);
		buf2=buf3;
		MemCpy(buf2+i,buf,j);
	      } else {
		buf2=buf3;
		MemCpy(buf2,buf,j);
	      }
	      tmph(CHashDefineStr *)->data=buf2;
	      tmph(CHashDefineStr *)->cnt=-1;
	      HashAdd(tmph,cc->htc.define_hash_table);
	    }
	    cc->flags&=~CCF_NO_DEFINES;
	    break;
	  case KW_ELSE:
	    if (cc->flags & CCF_IN_IF) {
	      cc->token=TK_ELSE;
	      goto lex_end;
	    }
lex_else:
	    j=1;
	    do {
	      if (ch=LexGetChar(cc)) {
		if (ch=='#') {
		  if (!Lex(cc))
		    goto lex_end;
		  i=PrsKeyWord(cc);
		  if (i==KW_IF || i==KW_IFDEF || i==KW_IFNDEF ||
			i==KW_IFAOT || i==KW_IFJIT)
		    j++;
		  else if (i==KW_ENDIF)
		    j--;
		}
	      } else {
		cc->token=TK_EOF;
		goto lex_end;
	      }
	    } while (j);
	    break;

	  case KW_IF:
	    if (cc->flags & CCF_IN_IF) {
	      cc->token=TK_IF;
	      goto lex_end;
	    }
lex_if:
	    cc->flags|=CCF_IN_IF;
	    if (!Lex(cc)) {
	      cc->flags&=~CCF_IN_IF;
	      goto lex_end;
	    }
	    if (LexExpression(cc)) {
	      cc->flags&=~CCF_IN_IF;
	      switch (cc->token) {
		case TK_IF:	goto lex_if;
		case TK_IFDEF:	goto lex_ifdef;
		case TK_IFNDEF:	goto lex_ifndef;
		case TK_IFAOT:	goto lex_ifaot;
		case TK_IFJIT:	goto lex_ifjit;
		case TK_ELSE:	goto lex_else;
		case TK_ENDIF:	goto lex_cont;
		default:	goto lex_end;
	      }
	    } else {
	      cc->flags&=~CCF_IN_IF;
	      if (cc->token!=TK_ENDIF && cc->token!=TK_ELSE) {
		if (cc->token==TK_IF || cc->token==TK_IFDEF ||
		      cc->token==TK_IFNDEF || cc->token==TK_IFAOT ||
		      cc->token==TK_IFJIT)
		  j=2;
		else
		  j=1;
		do {
		  if (ch=LexGetChar(cc)) {
		    if (ch=='#') {
		      if (!Lex(cc))
			goto lex_end;
		      i=PrsKeyWord(cc);
		      if (i==KW_IF || i==KW_IFDEF || i==KW_IFNDEF ||
			    i==KW_IFAOT || i==KW_IFJIT)
			j++;
		      else if (i==KW_ENDIF)
			j--;
		      else if (i==KW_ELSE && j==1)
			break;
		    }
		  } else {
		    cc->token=TK_EOF;
		    goto lex_end;
		  }
		} while (j);
	      }
	    }
	    break;
	  case KW_IFDEF:
	    if (cc->flags & CCF_IN_IF) {
	      cc->token=TK_IFDEF;
	      goto lex_end;
	    }
lex_ifdef:
	    cc->flags|=CCF_NO_DEFINES;
	    if (!Lex(cc)) {
	      cc->flags&=~CCF_NO_DEFINES;
	      goto lex_end;
	    }
	    cc->flags&=~CCF_NO_DEFINES;
	    if (cc->token!=TK_IDENT)
	      goto lex_end;
	    if (cc->hash_entry)
	      goto lex_cont;
	    j=1;
	    do {
	      if (ch=LexGetChar(cc)) {
		if (ch=='#') {
		  if (!Lex(cc))
		    goto lex_end;
		  i=PrsKeyWord(cc);
		  if (i==KW_IF || i==KW_IFDEF || i==KW_IFNDEF ||
			i==KW_IFAOT || i==KW_IFJIT)
		    j++;
		  else if (i==KW_ENDIF)
		    j--;
		  else if (i==KW_ELSE && j==1)
		    break;
		}
	      } else {
		cc->token=TK_EOF;
		goto lex_end;
	      }
	    } while (j);
	    break;
	  case KW_IFNDEF:
	    if (cc->flags & CCF_IN_IF) {
	      cc->token=TK_IFNDEF;
	      goto lex_end;
	    }
lex_ifndef:
	    cc->flags|=CCF_NO_DEFINES;
	    if (!Lex(cc)) {
	      cc->flags&=~CCF_NO_DEFINES;
	      goto lex_end;
	    }
	    cc->flags&=~CCF_NO_DEFINES;
	    if (cc->token!=TK_IDENT)
	      goto lex_end;
	    if (!cc->hash_entry)
	      goto lex_cont;
	    j=1;
	    do {
	      if (ch=LexGetChar(cc)) {
		if (ch=='#') {
		  if (!Lex(cc))
		    goto lex_end;
		  i=PrsKeyWord(cc);
		  if (i==KW_IF || i==KW_IFDEF || i==KW_IFNDEF ||
			i==KW_IFAOT || i==KW_IFJIT)
		    j++;
		  else if (i==KW_ENDIF)
		    j--;
		  else if (i==KW_ELSE && j==1)
		    break;
		}
	      } else {
		cc->token=TK_EOF;
		goto lex_end;
	      }
	    } while (j);
	    break;
	  case KW_IFAOT:
	    if (cc->flags & CCF_IN_IF) {
	      cc->token=TK_IFAOT;
	      goto lex_end;
	    }
lex_ifaot:
	    if (cc->flags & CCF_AOT_COMPILE)
	      goto lex_cont;
	    j=1;
	    do {
	      if (ch=LexGetChar(cc)) {
		if (ch=='#') {
		  if (!Lex(cc))
		    goto lex_end;
		  i=PrsKeyWord(cc);
		  if (i==KW_IF || i==KW_IFDEF || i==KW_IFNDEF ||
			i==KW_IFAOT || i==KW_IFJIT)
		    j++;
		  else if (i==KW_ENDIF)
		    j--;
		  else if (i==KW_ELSE && j==1)
		    break;
		}
	      } else {
		cc->token=TK_EOF;
		goto lex_end;
	      }
	    } while (j);
	    break;
	  case KW_IFJIT:
	    if (cc->flags & CCF_IN_IF) {
	      cc->token=TK_IFAOT;
	      goto lex_end;
	    }
lex_ifjit:
	    if (!(cc->flags & CCF_AOT_COMPILE))
	      goto lex_cont;
	    j=1;
	    do {
	      if (ch=LexGetChar(cc)) {
		if (ch=='#') {
		  if (!Lex(cc))
		    goto lex_end;
		  i=PrsKeyWord(cc);
		  if (i==KW_IF || i==KW_IFDEF || i==KW_IFNDEF ||
			i==KW_IFAOT || i==KW_IFJIT)
		    j++;
		  else if (i==KW_ENDIF)
		    j--;
		  else if (i==KW_ELSE && j==1)
		    break;
		}
	      } else {
		cc->token=TK_EOF;
		goto lex_end;
	      }
	    } while (j);
	    break;
	  case KW_ENDIF:
	    if (cc->flags & CCF_IN_IF) {
	      cc->token=TK_ENDIF;
	      goto lex_end;
	    }
	    break;
	  case KW_ASSERT:
	    if (!Lex(cc))
	      goto lex_end;
	    if (!LexExpression(cc))
	      LexWarn(cc,"Assert Failed ");
	    goto lex_end;
	  case KW_EXE:
	    if (!Lex(cc))
	      goto lex_end;
	    PrsStreamBlk(cc);
	    goto lex_end;
	  case KW_HELP_INDEX:
	    if (Lex(cc)!=TK_STR)
	      goto lex_end;
	    Free(cc->cur_help_idx);
	    cc->cur_help_idx=LexExtStr(cc,,FALSE);
	    break;
	  case KW_HELP_FILE:
	    if (Lex(cc)!=TK_STR)
	      goto lex_end;
	    tmph=CAlloc(sizeof(CHashSrcSym));
	    fbuf=ExtDft(cc->cur_str,"DD.Z");
	    tmph->str=FileNameAbs(fbuf);
	    Free(fbuf);
	    tmph->type=HTT_HELP_FILE|HTF_PUBLIC;
	    HashSrcFileSet(cc,tmph);
	    HashAdd(tmph,cc->htc.glbl_hash_table);
	    break;
	}
	break;
      case '\n':
	if (!(cc->flags&CCF_KEEP_NEW_LINES))
	  break; //else fall through
      case TK_INS_BIN:
      case TK_INS_BIN_SIZE:
	cc->token=ch;
	goto lex_end;
      case '!':
      case '$$'...'&':
      case '('...'-':
      case '/':
      case ':'...'?':
      case '[':
      case ']'...'^':
      case '{'...'~':
      case '`':
        i=LexPunctBody(cc,ch,&token_source,&punct_tables,&punct_finish);
        if(i==-2) goto lex_cont;
        if(!punct_finish) return cc->token;
        goto lex_end;
      case TK_TKS_NUM:
	break;
    }
  }
lex_end:
  LexGetChar(cc); //Do this so WAS_NEW_LINE is right
  cc->flags|=CCF_USE_LAST_U16;
  return cc->token;
}
