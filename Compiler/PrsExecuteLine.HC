I64 ExeCmdLine(CCmpCtrl *cc)
{//Terminal JIT-compile-and-execute loop for CCmpCtrl.
  I64 res=0,type,old_title_src=Fs->title_src;
  U8 *ptr,*ptr2,*ptr3,*machine_code=NULL,*old_task_title=StrNew(Fs->task_title);
  F64 t0;
  CDocEntry *doc_e;
  CDoc *doc;
  try {
  if (Fs->title_src!=TTS_LOCKED_CONST)
    Fs->title_src=TTS_CUR_LEX;
  while (cc->token &&
	(cc->token!='}' || !(cc->flags & CCF_EXE_BLK)) ) {
    if (Fs->title_src==TTS_CUR_LEX) {
      ptr2=&Fs->task_title;
      ptr3=ptr2+STR_LEN-1;
      if (cc->lex_include_stk->flags & LFSF_DOC) {
	doc_e=cc->lex_include_stk->cur_entry;
	doc=cc->lex_include_stk->doc;
	while (doc_e!=doc && ptr2<ptr3) {
	  switch (doc_e->type_u8) {
	    case DOCT_TEXT:
	      ptr=doc_e->tag;
	      while (*ptr && ptr2<ptr3)
		*ptr2++=*ptr++;
	      break;
	    case DOCT_TAB:
	    case DOCT_NEW_LINE:
	      *ptr2++='.';
	      break;
	  }
	  doc_e=doc_e->next;
	}
	if (ptr2<ptr3) *ptr2=0;
      } else
	if ((ptr=cc->lex_include_stk->line_start) && *ptr)
	  MemCpy(ptr2,ptr,STR_LEN-1);
    }
    cc->flags&=~CCF_HAS_MISC_DATA;
    machine_code=LexStmt2Bin(cc,&type);
    if (machine_code!=INVALID_PTR) {
      if (!(cc->flags&CCF_JUST_LOAD)) {
	t0=tS;
	res=Call(machine_code);
	Fs->answer=res;
	Fs->answer_type=type;
	Fs->answer_time=tS-t0;
	Fs->new_answer=TRUE;
	cc->pmt_line=0;
      }
      if (!(cc->flags&CCF_HAS_MISC_DATA))
	Free(machine_code);
      machine_code=NULL;
    }
  }
  } catch {
    if (machine_code && machine_code!=INVALID_PTR && !(cc->flags&CCF_HAS_MISC_DATA))
      Free(machine_code);
    if (Fs->title_src!=TTS_LOCKED_CONST) {
      Fs->title_src=old_title_src;
      StrCpy(Fs->task_title,old_task_title);
    }
    Free(old_task_title); //Leave the exception unhandled for the caller.
  }
  if (Fs->title_src!=TTS_LOCKED_CONST) {
    Fs->title_src=old_title_src;
    StrCpy(Fs->task_title,old_task_title);
  }
  Free(old_task_title);
  if (cc->flags&CCF_JUST_LOAD) {
    if (cc->error_cnt)
      return FALSE;
    else
      return TRUE;
  } else
    return res;
}

