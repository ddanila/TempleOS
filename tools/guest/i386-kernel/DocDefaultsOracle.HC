//Original parser-based defaults, preserved independently of the fixed-table initializer.
Bool OriginalDocDefaultsCheck()
{
  CDolDocGlbls expected,actual;
  CCmpCtrl *cc;
  CHashGeneric *tmph;
  I64 i;
  U8 *left,*right;
  MemSet(&expected,0,sizeof(expected));
  MemCpy(&actual,&doldoc,sizeof(actual));
  expected.clean_scan_codes[0]=1;
  actual.clean_scan_codes[0]|=1;
  DocDefaultsInit(&actual);
  if(actual.hash!=doldoc.hash) return FALSE;
  MemSet(expected.dft_de_flags,	0,sizeof(expected.dft_de_flags));
  MemSet(expected.dft_type_flags,	0,sizeof(expected.dft_type_flags));
  cc=CmpCtrlNew("TX+T;DA+P+TRM+T+DL+DRT;CM+LE+RE;AN+T;LK+L+UL+T;MA+X+UL+T;"
	"MU+X+UL+T;BT+X+B+T;CB+CA+P+T+DRT;LS+LS+P+T+DRT;HX+P+Z;TR+TR+C+CA+UL+T;"
	"SP+T;IB+T;IS+T;SO+T;HC+T;",CCF_DONT_FREE_BUF);
  cc->htc.hash_table_lst=NULL;
  Lex(cc);
  while (cc->token==TK_IDENT) {
    if (tmph=HashFind(cc->cur_str,doldoc.hash,DHT_DOC_CMD)) {
      i=tmph->user_data0;
      Lex(cc);
      PrsDocFlags(cc,&expected.dft_de_flags[i],&expected.dft_type_flags[i]);
    }
    if (cc->token==';')
      Lex(cc);
  }
  CmpCtrlDel(cc);

  for (i=0;i<DOCT_TYPES_NUM;i++)
    expected.dft_de_flags[i]&=~DOCG_BL_IV_UL;

  expected.type_flags_form[0]=0;
  for (i=0;i<DOCT_TYPES_NUM;i++)
    if (Bt(&expected.dft_de_flags[i],DOCEf_TAG) && i!=DOCT_TEXT || i==DOCT_HEX_ED)
      Bts(expected.type_flags_form,i);

      //Don't forget $LK,"cmp_type_flags_src_code",A="MN:cmp_type_flags_src_code"$.
  expected.type_flags_nontag_invis[0]=
	1<<DOCT_PMT|
	1<<DOCT_PAGE_LEN|
	1<<DOCT_LEFT_MARGIN|
	1<<DOCT_RIGHT_MARGIN|
	1<<DOCT_HEADER|
	1<<DOCT_FOOTER|
	1<<DOCT_INDENT|
	1<<DOCT_FOREGROUND|
	1<<DOCT_BACKGROUND|
	1<<DOCT_DFT_FOREGROUND|
	1<<DOCT_DFT_BACKGROUND|
	1<<DOCT_WORD_WRAP|
	1<<DOCT_HIGHLIGHT|
	1<<DOCT_BLINK|
	1<<DOCT_INVERT|
	1<<DOCT_UNDERLINE|
	1<<DOCT_SHIFTED_X|
	1<<DOCT_SHIFTED_Y|
	1<<DOCT_SPRITE;

  expected.type_flags_data[0]=1<<DOCT_DATA|1<<DOCT_HEX_ED|1<<DOCT_CHECK_BOX;

  expected.type_flags_chk_dup[0]=
	1<<DOCT_LEFT_MARGIN|
	1<<DOCT_RIGHT_MARGIN|
	1<<DOCT_HEADER|
	1<<DOCT_FOOTER|
	1<<DOCT_FOREGROUND|
	1<<DOCT_BACKGROUND|
	1<<DOCT_DFT_FOREGROUND|
	1<<DOCT_DFT_BACKGROUND|
	1<<DOCT_WORD_WRAP|
	1<<DOCT_HIGHLIGHT|
	1<<DOCT_BLINK|
	1<<DOCT_INVERT|
	1<<DOCT_UNDERLINE|
	1<<DOCT_SHIFTED_X|
	1<<DOCT_SHIFTED_Y;

  Bts(expected.clean_scan_codes,SC_CURSOR_RIGHT);
  Bts(expected.clean_scan_codes,SC_CURSOR_LEFT);
  Bts(expected.clean_scan_codes,SC_CURSOR_UP);
  Bts(expected.clean_scan_codes,SC_CURSOR_DOWN);
  Bts(expected.clean_scan_codes,SC_PAGE_UP);
  Bts(expected.clean_scan_codes,SC_PAGE_DOWN);
  Bts(expected.clean_scan_codes,SC_ALT);
  Bts(expected.clean_scan_codes,SC_CTRL);
  Bts(expected.clean_scan_codes,SC_SHIFT);
  Bts(expected.clean_scan_codes,SC_CAPS);
  Bts(expected.clean_scan_codes,SC_NUM);
  Bts(expected.clean_scan_codes,SC_SCROLL);
  Bts(expected.clean_scan_codes,SC_HOME);
  Bts(expected.clean_scan_codes,SC_END);
  Bts(expected.clean_scan_codes,SC_GUI);
  Bts(expected.clean_scan_codes,SC_BACKSPACE); //Handled specially
  left=&expected.dft_de_flags; right=&actual.dft_de_flags;
  for(i=0;i<sizeof(CDolDocGlbls)-offset(CDolDocGlbls.dft_de_flags);i++)
    if(left[i]!=right[i]) return FALSE;
  return TRUE;
}
