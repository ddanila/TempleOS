#include "/Kernel/DocGlobals.HH"
#include "/Kernel/ScanCodes.HH"
U0 DocDefaultsInit(CDolDocGlbls *state)
{//Fixed document policy tables. Dictionary setup remains with DocInit.
  I64 i;
  #assert DOCT_TYPES_NUM<=64
  //Preserve caller-added clean scan codes, as the original DocInit does.
  for(i=0;i<DOCT_TYPES_NUM;i++) {
    state->dft_de_flags[i]=0; state->dft_type_flags[i]=0;
  }
  state->dft_de_flags[DOCT_TEXT]=DOCEF_TAG;
  state->dft_de_flags[DOCT_DATA]=DOCEF_DEREF_DATA|DOCEF_HAS_TERMINATOR|DOCEF_TAG|DOCEF_DFT_LEN|DOCEF_DFT_RAW_TYPE;
  state->dft_de_flags[DOCT_CURSOR_MOVEMENT]=DOCEF_LEFT_EXP|DOCEF_RIGHT_EXP;
  state->dft_de_flags[DOCT_ANCHOR]=DOCEF_TAG;
  state->dft_de_flags[DOCT_LINK]=DOCEF_LINK|DOCEF_UNDERLINE|DOCEF_TAG;
  state->dft_de_flags[DOCT_MACRO]=DOCEF_ESC|DOCEF_UNDERLINE|DOCEF_TAG;
  state->dft_de_flags[DOCT_MENU_VAL]=DOCEF_ESC|DOCEF_UNDERLINE|DOCEF_TAG;
  state->dft_de_flags[DOCT_BTTN]=DOCEF_ESC|DOCEF_HAS_BORDER|DOCEF_TAG;
  state->dft_de_flags[DOCT_CHECK_BOX]=DOCEF_CHECK_COLLAPSABLE|DOCEF_DEREF_DATA|DOCEF_TAG|DOCEF_DFT_RAW_TYPE;
  state->dft_de_flags[DOCT_LST]=DOCEF_LST|DOCEF_DEREF_DATA|DOCEF_TAG|DOCEF_DFT_RAW_TYPE;
  state->dft_de_flags[DOCT_HEX_ED]=DOCEF_DEREF_DATA|DOCEF_ZERO_BASED;
  state->dft_de_flags[DOCT_TREE]=DOCEF_TREE|DOCEF_CHECKED_COLLAPSED|DOCEF_CHECK_COLLAPSABLE|DOCEF_UNDERLINE|DOCEF_TAG;
  state->dft_de_flags[DOCT_SPRITE]=DOCEF_TAG;
  state->dft_de_flags[DOCT_INS_BIN]=DOCEF_TAG;
  state->dft_de_flags[DOCT_INS_BIN_SIZE]=DOCEF_TAG;
  state->dft_de_flags[DOCT_SONG]=DOCEF_TAG;
  state->dft_de_flags[DOCT_HTML_CODE]=DOCEF_TAG;
  for(i=0;i<DOCT_TYPES_NUM;i++)
    state->dft_type_flags[i]=state->dft_de_flags[i]&(DOCG_BL_IV_UL|DOCEF_SEL);
  for (i=0;i<DOCT_TYPES_NUM;i++)
    state->dft_de_flags[i]&=~DOCG_BL_IV_UL;

  state->type_flags_form[0]=0;
  for (i=0;i<DOCT_TYPES_NUM;i++)
    if (Bt(&state->dft_de_flags[i],DOCEf_TAG) && i!=DOCT_TEXT || i==DOCT_HEX_ED)
      Bts(state->type_flags_form,i);

      //Don't forget $LK,"cmp_type_flags_src_code",A="MN:cmp_type_flags_src_code"$.
  state->type_flags_nontag_invis[0]=
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

  state->type_flags_data[0]=1<<DOCT_DATA|1<<DOCT_HEX_ED|1<<DOCT_CHECK_BOX;

  state->type_flags_chk_dup[0]=
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

  Bts(state->clean_scan_codes,SC_CURSOR_RIGHT);
  Bts(state->clean_scan_codes,SC_CURSOR_LEFT);
  Bts(state->clean_scan_codes,SC_CURSOR_UP);
  Bts(state->clean_scan_codes,SC_CURSOR_DOWN);
  Bts(state->clean_scan_codes,SC_PAGE_UP);
  Bts(state->clean_scan_codes,SC_PAGE_DOWN);
  Bts(state->clean_scan_codes,SC_ALT);
  Bts(state->clean_scan_codes,SC_CTRL);
  Bts(state->clean_scan_codes,SC_SHIFT);
  Bts(state->clean_scan_codes,SC_CAPS);
  Bts(state->clean_scan_codes,SC_NUM);
  Bts(state->clean_scan_codes,SC_SCROLL);
  Bts(state->clean_scan_codes,SC_HOME);
  Bts(state->clean_scan_codes,SC_END);
  Bts(state->clean_scan_codes,SC_GUI);
  Bts(state->clean_scan_codes,SC_BACKSPACE); //Handled specially
}
