I64 LPRecoveryTrigger[3],LPRecoveryState[12];
CTask *LPTask;
U8 *LPDirectory;
I64 LPState[12],LPChildAddress;
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
  MemSet(LPRecoveryTrigger,0,sizeof(LPRecoveryTrigger));
  LPTask=NULL;
  child=User("U0 LPChildInit(){Cd(\"::/\");DocClear;*(0x%X)(CTask **)=Fs;}LPChildInit;\n",&LPTask);
  if(!child || child==Fs)throw('User');
  while(LPTask!=child)Sleep(1);
  LPDirectory=DirCur(child);
  LPChildAddress=0;MemCpy(&LPChildAddress,&child,sizeof(child));
  WinFocus(child);
  for(phase=0;phase<3;phase++) {
    while(!LPReady(phase))Sleep(1);
    Sleep(50);
    if(LPTask!=child || !LPReady(phase))throw('Prompt');
    LPCapture(phase);
  }
  LPExport("live-prompt-state.bin",LPState,sizeof(LPState));
  LPExport("live-prompt-child.bin",&LPChildAddress,sizeof(LPChildAddress));
  LPExport("recovery-trigger.bin",LPRecoveryTrigger,sizeof(LPRecoveryTrigger));
  LPLog("DONE live user prompt\n");
  for(phase=0;phase<3;phase++) {
    U8 *ready_doc,*ready_witness,*ready_line;
    Bool ready=FALSE,compile_error_reported=FALSE;
    I64 ready_exception;
    CCmpCtrl *ready_control=LPTask->last_cc;
    if(!phase){ready_witness="Except:Recover:";ready_exception='Recover';}
    else if(phase==1){ready_witness="Except:Compiler:";ready_exception='Compiler';}
    else {ready_witness="Except:Break:";ready_exception='Break';}
    while(!ready) {
      if(phase==2 && !compile_error_reported && LPReady(0) &&
          LPTask->except_ch=='Compiler' && LPTask->last_cc!=ready_control) {
        I64 error_size;
        U8 *error_doc=DocSave(LPTask->put_doc,&error_size);
        LPExport("recovery-compile-error.DD",error_doc,error_size);
        LPLog("RECOVERY COMPILE ERROR\n");compile_error_reported=TRUE;
      }
      if(LPReady(0)) {
        ready_doc=DocSave(LPTask->put_doc);
        ready=StrFind(ready_witness,ready_doc)!=NULL;
        Free(ready_doc);
      }
      if(!ready)Sleep(1);
    }
    ready_line=MStrPrint("RECOVERY READY %d\n",phase);LPLog(ready_line);Free(ready_line);
    while(!LPRecoveryTrigger[phase] || !LPReady(1))Sleep(1);
    Sleep(50);
    if(!LPReady(1))throw('Recovery');
    LPRecoveryState[phase*4]=LPTask->answer;
    LPRecoveryState[phase*4+1]=LPTask->answer_type;
    LPRecoveryState[phase*4+2]=LPTask->new_answer;
    LPRecoveryState[phase*4+3]=Bt(&LPTask->task_flags,TASKf_CMD_LINE_PMT);
    U8 *recovery_doc,*recovery_name,*recovery_line;
    I64 recovery_size;
    recovery_doc=DocSave(LPTask->put_doc,&recovery_size);
    recovery_name=MStrPrint("recovery-%d.DD",phase);
    LPExport(recovery_name,recovery_doc,recovery_size);
    recovery_line=MStrPrint("RECOVERY PHASE %d\n",phase);LPLog(recovery_line);
    Free(recovery_name);Free(recovery_line);
  }
  LPExport("recovery-state.bin",LPRecoveryState,sizeof(LPRecoveryState));
  LPLog("DONE live recovery\n");
  while(TaskValidate(child))Sleep(1);
  LPLog("LIVE USER RETIRED\n");
  //Keep exported parent-owned observations live for capture.
  while(TRUE)Sleep(1000);
}
