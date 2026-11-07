U0 LexPutToken(CCmpCtrl *cc)
{//Print cur token to StdOut. (Crude)
  '"';
  if (cc->token==TK_IDENT || cc->token==TK_STR)
    "%s",cc->cur_str;
  else if (cc->token==TK_I64)
    "INT:%X",cc->cur_i64;
  else if (cc->token==TK_CHAR_CONST)
    "U8:%X",cc->cur_i64;
  else if (cc->token==TK_F64)
    "FLOAT:%e",cc->cur_f64;
  else if (cc->token=='\n')
    "<NEW_LINE>";
  else if (Bt(char_bmp_displayable,cc->token))
    '' cc->token;
  else {
    "T:%X",cc->token;
  }
  "\" ";
}

U8 *LexPutLine(CCmpCtrl *cc,U8 *start)
{//Print cur pos to end of line to StdOut.
  I64 ch;
  U8 *ptr;
  if (!start) return NULL;
  if (cc->lex_include_stk->flags&LFSF_DOC)
    return DocPutLine(cc->lex_include_stk->doc,start);
  else {
    ptr=start;
    while (ch=*ptr++) {
      if (ch=='\n') {
	if (*ptr=='\r')
	  ptr++;
	break;
      } else if (ch=='\r') {
	if (*ptr=='\n')
	  ptr++;
	break;
      }
      '' ch;
    }
    if (!ch) ptr--;
    '\n';
    return ptr;
  }
  return NULL;
}

U0 LexPutPos(CCmpCtrl *cc)
{//Print token, line link and, then, $LK,"LexPutLine",A="MN:LexPutLine"$().
  LexPutToken(cc);
  FixSet(cc->lex_include_stk->full_name,cc->lex_include_stk->line_num);
  if (IsRaw)
    "%s,%d ",cc->lex_include_stk->full_name,cc->lex_include_stk->line_num;
  else {
    PutFileLink(cc->lex_include_stk->full_name,,cc->lex_include_stk->line_num);
    AdamErr("%s,%d\n",
	  cc->lex_include_stk->full_name,cc->lex_include_stk->line_num);
    '' CH_SPACE;
  }
  LexPutLine(cc,cc->lex_include_stk->line_start);
}

U0 LexWarn(CCmpCtrl *cc,U8 *str=NULL)
{//Print warn msg, then, $LK,"LexPutPos",A="MN:LexPutPos"$().
  if (str) PrintWarn(str);
  if (cc->htc.fun) {
    "in fun '%s'.\n",cc->htc.fun->str;
    if (IsRaw)
      "%s\n",cc->htc.fun->src_link;
    else {
      "$$LK,\"%s\"$$\n",cc->htc.fun->src_link;
      AdamErr("%s\n",cc->htc.fun->src_link);
    }
  } else
    LexPutPos(cc);
  cc->warning_cnt++;
}

U0 LexExcept(CCmpCtrl *cc,U8 *str=NULL)
{//Print err msg, $LK,"LexPutPos",A="MN:LexPutPos"$() and throw exception.
  if (!Bt(&sys_run_level,RLf_ADAM_SERVER)) {
    Raw(ON);
    "Note: Still in boot phase.\n";
  }
  if (str) PrintErr(str);
  if (!IsRaw)
    AdamErr("Task:%08X %s\n",Fs,str);
  LexPutPos(cc);
  cc->error_cnt++;
  FlushMsgs;
  if (!Bt(&sys_run_level,RLf_ADAM_SERVER))
    Dbg("Type \"Fix;\"");
  throw('Compiler');
}

