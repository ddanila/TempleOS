U0 SLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 sl_effect,sl_type;Bool sl_context_ok=TRUE,sl_directory_ok;
U8 *sl_directory;
U0 SLDirMatch(U8 *directory){sl_directory_ok=directory && !StrCmp(directory,sl_directory);}
U0 SLMark(){sl_effect++;}
I64 SLRun(U8 *source)
{
  I64 flags=0,res=0,old_src=Fs->title_src;U8 *title=StrNew(Fs->task_title),*filename=MStrPrint("%C:/Kernel/KTask.HC",Drv2Let);CCmpCtrl *cc;
#ifdef I386_PUBLIC_KERNEL_INCLUDED
  flags=CCF_TARGET_I386;
#endif
  cc=CmpCtrlNew(StrNew(source),flags,filename);Free(filename);
  QueIns(cc,Fs->last_cc);
  try{Lex(cc);res=ExeCmdLine(cc);}
  catch{sl_context_ok=FALSE;Fs->catch_except=TRUE;}
  sl_type=Fs->answer_type;
  if(cc->token!=TK_EOF || cc->error_cnt || cc->warning_cnt || cc->flags&CCF_EXE_BLK ||
      cc->last_stream_blk!=&cc->next_stream_blk || cc->next_stream_blk!=&cc->next_stream_blk ||
      Fs->title_src!=old_src || StrCmp(title,Fs->task_title))sl_context_ok=FALSE;
  QueRem(cc);CmpCtrlDel(cc);Free(title);return res;
}
U0 SLCheck()
{
  I64 *r=CAlloc(9*8),res;U8 *s;
  while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
  sl_effect=0;res=SLRun("#exe{SLMark;StreamPrint(\"6*7;\");}");
  r[0]=res==42 && sl_effect==1 && sl_type==RT_I64;
  r[1]=SLRun("#exe{StreamPrint(\"6*\");StreamPrint(\"7;\");}")==42;
  r[2]=SLRun("6*#exe{StreamPrint(\"7\");};")==42;
  sl_effect=0;res=SLRun("#exe{SLMark;StreamPrint(\"6*\");#exe{SLMark;StreamPrint(\"StreamPrint(\\\"7;\\\");\");}}");
  r[3]=res==42 && sl_effect==2;
  r[4]=SLRun("#exe{StreamPrint(\"0x123456789ABCDEF;\");}")==0x123456789ABCDEF;
  res=SLRun("1.25+#exe{StreamPrint(\"2.5\");};");r[5]=res==0x400E000000000000 && sl_type==RT_F64;
  sl_effect=0;res=SLRun("#exe{SLMark;}");r[6]=res==0 && sl_effect==1;
  sl_directory=MStrPrint("%C:/Kernel",Drv2Let);
  SLRun("SLDirMatch(#exe{StreamDir;});");r[8]=sl_directory_ok;Free(sl_directory);
  r[7]=sl_context_ok;
  s=MStrPrint("EXPORT public-compiler-stream.bin %X 48\n",r);SLLog(s);Free(s);
  SLLog("PUBLIC COMPILER STREAM DONE\n");Sleep(1000);
}
SLCheck;
