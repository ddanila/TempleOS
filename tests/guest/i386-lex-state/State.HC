I64 LexStateTest()
{
  CCmpCtrl *cc=StateAlloc(sizeof(CCmpCtrl));
  CLexFile *files=StateAlloc(sizeof(CLexFile)*3),*active;
  U8 buffer[32];
  I64 byte,enabled,expected,base_flags=CCF_AOT_COMPILE|CCF_KEEP_AT_SIGN;
  if(!cc || !files) return 1;
  CmpCtrlSeed(cc,base_flags,0,0); active=files; cc->lex_include_stk=active;
  for(enabled=0;enabled<2;enabled++) for(byte=0;byte<256;byte++) {
    cc->flags=base_flags; if(enabled) cc->flags|=CCF_USE_LAST_U16;
    cc->last_U16=0x100+byte; cc->cur_buf_ptr=buffer+3;
    active->next=files+1; active->buf=buffer; active->buf_ptr=buffer+1;
    active->line_num=0x100000004; active->flags=LFSF_DOC;
    active->line_start=buffer+2; active->full_name="borrowed";
    active->doc=0xF1234560; active->cur_entry=0xE1234560; active->depth=-1;
    active->last_U16=99; active->pad[0]=11; active->pad[1]=22; active->pad[2]=33;
    expected=0; if(enabled) expected=byte;
    if(!StatePush(cc) || !cc->lex_prs_stk || cc->lex_prs_stk==active ||
        active->buf_ptr!=buffer+3 || active->last_U16!=expected ||
        (cc->flags&CCF_USE_LAST_U16)!=((expected!=0)*CCF_USE_LAST_U16) ||
        cc->last_U16!=0x100+byte) return 2;
    cc->cur_buf_ptr=buffer+8; cc->last_U16=77;
    cc->flags=base_flags|CCF_UNRESOLVED|CCF_USE_LAST_U16;
    active->next=files+2; active->buf=0; active->line_num=0; active->flags=0;
    active->line_start=0; active->full_name=0; active->doc=0; active->cur_entry=0; active->depth=99;
    active->pad[0]=0; active->pad[1]=0; active->pad[2]=0;
    if(!StatePop(cc,TRUE) || cc->lex_prs_stk || cc->cur_buf_ptr!=buffer+3 ||
        cc->last_U16!=expected ||
        cc->flags!=(base_flags|CCF_UNRESOLVED|((expected!=0)*CCF_USE_LAST_U16)) ||
        active->next!=files+2 || active->buf!=buffer || active->buf_ptr!=buffer+3 ||
        active->line_num!=0x100000004 || active->flags!=LFSF_DOC ||
        active->line_start!=buffer+2 || !active->full_name || active->doc!=0xF1234560 ||
        active->cur_entry!=0xE1234560 || active->depth!=-1 || active->last_U16!=expected ||
        active->pad[0]!=11 || active->pad[1]!=22 || active->pad[2]!=33) return 3;
  }
  for(byte=0;byte<3;byte++) {
    cc->flags=base_flags|CCF_USE_LAST_U16; cc->last_U16='A'+byte; cc->cur_buf_ptr=buffer+byte;
    if(!StatePush(cc)) return 4;
  }
  cc->cur_buf_ptr=buffer+7; cc->last_U16='Z';
  if(!StatePop(cc,FALSE) || cc->cur_buf_ptr!=buffer+7 || cc->last_U16!='Z') return 5;
  if(!StatePop(cc,TRUE) || cc->cur_buf_ptr!=buffer+1 || cc->last_U16!='B') return 6;
  if(!StatePop(cc,TRUE) || cc->cur_buf_ptr!=buffer || cc->last_U16!='A' || cc->lex_prs_stk) return 7;
  StateFree(files); StateFree(cc); return 0;
}
