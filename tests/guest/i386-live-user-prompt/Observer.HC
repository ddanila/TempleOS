CTask *LPTask;
U8 *LPDirectory;
I64 LPState[12];
U8 *LPDocuments[3];
U0 LPLog(U8 *text){while(*text)OutU8(0xE9,*text++);}
U0 LPExport(U8 *name,U8 *bytes,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,bytes,size);LPLog(s);Free(s);}
Bool LPReady(I64 phase)
{
  if(!LPTask || !TaskValidate(LPTask) ||
      !Bt(&LPTask->task_flags,TASKf_CMD_LINE_PMT) || LPTask->new_answer)return FALSE;
  if(phase==1)return LPTask->answer==42 && LPTask->answer_type==RT_I64;
  if(phase==2)return (LPTask->answer==0x400E000000000000 || LPTask->answer==0x400E000000000001) && LPTask->answer_type==RT_F64;
  return TRUE;
}
U0 LPCapture(I64 phase)
{
  CDoc *doc=LPTask->put_doc;
  I64 size;
  U8 *name,*line;
  Bool unlock;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL)throw('Doc');
  unlock=DocLock(doc);
  LPDocuments[phase]=DocSave(doc,&size);
  if(unlock)DocUnlock(doc);
  LPState[phase*4]=LPTask->answer;LPState[phase*4+1]=LPTask->answer_type;
  LPState[phase*4+2]=LPTask->new_answer;
  LPState[phase*4+3]=Bt(&LPTask->task_flags,TASKf_CMD_LINE_PMT);
  name=MStrPrint("live-prompt-%d.DD",phase);
  LPExport(name,LPDocuments[phase],size);Free(name);
  if(!phase)LPExport("live-prompt-cwd.bin",LPDirectory,StrLen(LPDirectory));
  line=MStrPrint("LIVE PROMPT %d\n",phase);LPLog(line);Free(line);
}
U0 LPRun()
{
  CTask *child;
  I64 phase;
  while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
  LPTask=NULL;
  child=User("U0 LPChildInit(){Cd(\"::/\");DocClear;*(0x%X)(CTask **)=Fs;}LPChildInit;\n",&LPTask);
  if(!child || child==Fs)throw('User');
  while(LPTask!=child)Sleep(1);
  LPDirectory=DirCur(child);
  WinFocus(child);
  for(phase=0;phase<3;phase++) {
    while(!LPReady(phase))Sleep(1);
    Sleep(50);
    if(LPTask!=child || !LPReady(phase))throw('Prompt');
    LPCapture(phase);
  }
  LPExport("live-prompt-state.bin",LPState,sizeof(LPState));
  LPLog("DONE live user prompt\n");
  //Keep captured buffers and the parent's symbol namespace live for host capture.
  while(TRUE)Sleep(1000);
}
