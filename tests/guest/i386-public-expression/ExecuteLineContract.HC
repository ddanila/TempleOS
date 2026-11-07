U0 ELLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 el_effect,el_seen,el_token,el_pmt,el_errors;
Bool el_failed,el_titles_ok=TRUE,el_controls_ok=TRUE;
U0 ELSet(I64 value){el_effect=value;}
U0 ELMark(){el_seen=Fs->title_src;}
U0 ELSeed()
{
  Fs->answer=-99;Fs->answer_type=RT_U64;Fs->answer_time=0;Fs->new_answer=FALSE;
}
I64 ELRun(U8 *source,I64 flags=0)
{
  CCmpCtrl *cc;I64 res=0,old_src=Fs->title_src;U8 *old_title=StrNew(Fs->task_title);
#ifdef I386_PUBLIC_KERNEL_INCLUDED
  flags|=CCF_TARGET_I386;
#endif
  cc=CmpCtrlNew(StrNew(source),flags,"C:/Probe/ExecuteLine.HC");cc->pmt_line=57;
  ELLog("EL RUN ");ELLog(source);ELLog("\n");
  el_failed=FALSE;
  try{Lex(cc);res=ExeCmdLine(cc);}
  catch{el_failed=Fs->except_ch=='Compiler';Fs->catch_except=TRUE;}
  el_token=cc->token;el_pmt=cc->pmt_line;el_errors=cc->error_cnt;
  if(!el_failed && (cc->error_cnt || cc->warning_cnt ||
      (cc->token!=TK_EOF && !(flags&CCF_EXE_BLK && cc->token=='}'))))el_controls_ok=FALSE;
  if(!el_failed && (Fs->title_src!=old_src || StrCmp(Fs->task_title,old_title)))el_titles_ok=FALSE;
  CmpCtrlDel(cc);Free(old_title);return res;
}
U0 ELCheck()
{
  I64 *r=CAlloc(16*8),res,used,code_used,old_src=Fs->title_src;
  U8 *old_title=StrNew(Fs->task_title),*s;CDoc *put=DocPut,*doc;
  I64 old_answer=Fs->answer,old_type=Fs->answer_type;F64 old_time=Fs->answer_time;Bool old_new=Fs->new_answer;
  while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
  StrCpy(Fs->task_title,"ExecuteLine contract");Fs->title_src=TTS_CONST;
  used=Fs->data_heap->used_u8s;code_used=Fs->code_heap->used_u8s;
  ELSeed;res=ELRun("6*7;1+2;");
  r[0]=res==3 && Fs->answer==3 && Fs->answer_type==RT_I64 && Fs->new_answer && Fs->answer_time>=0 && !el_pmt;
  ELSeed;res=ELRun("1.25+2.5;");
  r[1]=res==0x400E000000000000 && Fs->answer==res && Fs->answer_type==RT_F64 && Fs->new_answer;
  ELSeed;el_effect=0;res=ELRun("ELSet(17);6*7;");
  r[2]=el_effect==17 && res==42 && Fs->answer==42 && Fs->answer_type==RT_I64;
  ELSeed;res=ELRun(";");
  r[3]=res==0 && Fs->answer==-99 && Fs->answer_type==RT_U64 && !Fs->new_answer && el_pmt==57;
  ELSeed;el_effect=0;res=ELRun("ELSet(91);6*7;",CCF_JUST_LOAD);
  r[4]=res==TRUE && !el_effect && Fs->answer==-99 && !Fs->new_answer && el_pmt==57;
  ELSeed;res=ELRun("6*7;}9;",CCF_EXE_BLK);
  r[5]=res==42 && Fs->answer==42 && el_token=='}' && !el_pmt;
  Fs->title_src=TTS_LOCKED_CONST;el_seen=-1;ELRun("ELMark;");
  r[6]=el_seen==TTS_LOCKED_CONST && Fs->title_src==TTS_LOCKED_CONST && !StrCmp(Fs->task_title,"ExecuteLine contract");
  Fs->title_src=TTS_CONST;el_seen=-1;ELRun("ELMark;");
  r[7]=el_seen==TTS_CUR_LEX && Fs->title_src==TTS_CONST && !StrCmp(Fs->task_title,"ExecuteLine contract");
  r[8]=Fs->data_heap->used_u8s==used;r[9]=Fs->code_heap->used_u8s==code_used;
  doc=DocNew;Fs->put_doc=doc;
  ELSeed;ELRun("6*7;1+;");r[10]=el_failed && el_errors>0;
  r[11]=Fs->title_src==TTS_CONST && !StrCmp(Fs->task_title,"ExecuteLine contract");
  r[12]=Fs->answer==42 && Fs->answer_type==RT_I64 && Fs->new_answer;
  Fs->put_doc=put;DocDel(doc);
  ELSeed;res=ELRun("6*7;");r[13]=res==42 && !el_failed && Fs->answer==42;
  r[14]=sizeof(I64)==8;r[15]=el_controls_ok && el_titles_ok;
  Fs->title_src=old_src;StrCpy(Fs->task_title,old_title);Free(old_title);
  Fs->answer=old_answer;Fs->answer_type=old_type;Fs->answer_time=old_time;Fs->new_answer=old_new;
  s=MStrPrint("EXPORT public-execute-line.bin %X 80\n",r);ELLog(s);Free(s);
  ELLog("PUBLIC EXECUTE LINE DONE\n");Sleep(1000);
}
ELCheck;
