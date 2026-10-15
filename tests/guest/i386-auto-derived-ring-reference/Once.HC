CCtrl *dp_ca,*dp_cb,*dp_cm;CTask *dp_a,*dp_b;I64 dp_mode,dp_order,dp_expected,dp_count,dp_ready,dp_before,dp_num;Bool dp_done,dp_context;
U0 DPBottom(CTask *t){CTask *a=sys_winmgr_task;t->last_task->next_task=t->next_task;t->next_task->last_task=t->last_task;t->next_task=a->next_task;t->last_task=a;a->next_task->last_task=t;a->next_task=t;}
U0 DPUpdate(CCtrl *c){if(dp_done)return;dp_context=dp_context&&Fs==sys_winmgr_task&&Fs!=c->win_task&&!(GetRFlags&0x200);dp_order=dp_order*10+c->left;dp_count++;if(dp_count==1&&dp_mode)DPBottom(c->win_task);}
U0 DPMark(CCtrl *c){dp_done=TRUE;}
U0 DPManager(){dp_cm=CAlloc(sizeof(CCtrl));dp_cm->win_task=sys_winmgr_task;dp_cm->update_derived_vals=&DPMark;QueIns(dp_cm,sys_winmgr_task->last_ctrl);}
U0 DPDetachManager(){QueRem(dp_cm);Free(dp_cm);}
U0 DPDetach(){QueRem(Fs->next_ctrl);}
U0 DPOwner(U8 *data){CCtrl *c=data;c->win_task=Fs;QueIns(c,Fs->last_ctrl);Fs->task_end_cb=&DPDetach;dp_ready++;while(TRUE)Yield;}
U0 DPReset(I64 mode){Suspend(sys_winmgr_task,TRUE);FlushMsgs;dp_before=Fs->data_heap->used_u8s;dp_num=sys_winmgr_task->task_num;dp_mode=mode;dp_order=dp_count=dp_ready=0;dp_done=FALSE;dp_context=TRUE;}
U0 DPControls(){dp_ca=CAlloc(sizeof(CCtrl));dp_cb=CAlloc(sizeof(CCtrl));dp_ca->left=1;dp_cb->left=2;dp_ca->update_derived_vals=dp_cb->update_derived_vals=&DPUpdate;}
U0 DPStart(){DPControls;dp_a=Spawn(&DPOwner,dp_ca,"Hidden A",-1,Fs,8192);dp_b=Spawn(&DPOwner,dp_cb,"Hidden B",-1,Fs,8192);while(dp_ready!=2)Yield;}
U0 DPExpected(){CTask *t=sys_winmgr_task->last_task;dp_expected=0;while(t!=sys_winmgr_task){if(t==dp_a)dp_expected=dp_expected*10+1;if(t==dp_b)dp_expected=dp_expected*10+2;t=t->last_task;}}
Bool DPHidden(CTask *t){return !Bt(&t->display_flags,DISPLAYf_SHOW)&&!Bt(&t->task_flags,TASKf_TASK_LOCK);}
I64 DPState(){I64 m=0;if(dp_context)m|=1;if(dp_count==2&&dp_order==dp_expected)m|=2;if(DPHidden(dp_a)&&DPHidden(dp_b))m|=4;return m;}
I64 DPStop(I64 m){DPDetachManager;Kill(dp_a,TRUE,FALSE);Kill(dp_b,TRUE,FALSE);Free(dp_ca);Free(dp_cb);FlushMsgs;if(sys_winmgr_task->task_num==dp_num)m|=8;if(Fs->data_heap->used_u8s==dp_before)m|=16;return m;}
I64 DPRun(I64 mode){I64 m;DPReset(mode);DPStart;DPExpected;DPManager;Suspend(sys_winmgr_task,FALSE);while(!dp_done)Sleep(1);Suspend(sys_winmgr_task,TRUE);m=DPStop(DPState);Suspend(sys_winmgr_task,FALSE);return m;}
U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 *result=CAlloc(16);
*result=DPRun(0)&15;result[1]=DPRun(1)&15;
U8 *message=MStrPrint("EXPORT auto-derived-ring.bin %X %X\n",result,16);
Report(message);Free(message);
Report("DONE original derived ring\n");
