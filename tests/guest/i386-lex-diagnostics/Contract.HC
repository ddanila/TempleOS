U0 LDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 LDExport(U8 *name,CDoc *d){I64 n;U8 *b=DocSave(d,&n),*s=MStrPrint("EXPORT %s %X %X\n",name,b,n);LDLog(s);Free(s);Sleep(1000);/* Retain exported allocation until guest shutdown. */}
U0 LDCheck(){CDoc *out=DocNew,*put=Fs->put_doc;CCmpCtrl *cc=NULL;U8 *fix=dbg.fix_file_line,*buf,*s;I64 *result,mask=0;Bool raw=Raw(OFF),single=Bt(&sys_semas[SEMA_SINGLE_USER],0),caught=FALSE;
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
LDLog("LEX SERVER READY\n");dbg.fix_file_line=NULL;Fs->put_doc=out;Bts(&sys_semas[SEMA_SINGLE_USER],0);
try {buf=StrNew("bad\nrest");cc=CmpCtrlNew(buf,0,"C:/Probe/Lex.HC");cc->cur_str=StrNew("bad");cc->token=TK_IDENT;
LexWarn(cc);if(cc->warning_cnt==1 && !cc->error_cnt)mask|=1;LDExport("lex-warning.DD",out);
LDLog("LEX BEFORE EXCEPT\n");try {LexExcept(cc);}catch{caught=Fs->except_ch=='Compiler';Fs->catch_except=TRUE;}
LDLog("LEX AFTER EXCEPT\n");if(cc->error_cnt==1 && cc->warning_cnt==1)mask|=2;if(caught)mask|=4;
if(!StrCmp(dbg.fix_file_line,"FL:C:/Probe/Lex.HC,1"))mask|=8;
if(cc->cur_buf_ptr==buf && cc->lex_include_stk->line_start==buf)mask|=16;
LDExport("lex-exception.DD",out);
}catch{Fs->catch_except=TRUE;}
if(cc)CmpCtrlDel(cc);Free(dbg.fix_file_line);dbg.fix_file_line=fix;BEqu(&sys_semas[SEMA_SINGLE_USER],0,single);Fs->put_doc=put;DocDel(out);Raw(raw);
result=MAlloc(8);*result=mask;s=MStrPrint("EXPORT lex-diagnostics-mask.bin %X 8\n",result);LDLog(s);Free(s);LDLog("LEX DIAGNOSTICS DONE\n");Sleep(1000);}
