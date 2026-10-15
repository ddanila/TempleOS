CTask *pl_old,*pl_client,*pl_inner,*pl_slot;I64 pl_mode,pl_before;Bool pl_caught,pl_returned,pl_clean;
U0 PLAbort(){throw('PuStop',TRUE);}
U0 PLHold(U8 *data){while(TRUE)Yield;}
U0 PLPrior(){pl_old=Spawn(&PLHold,NULL,"Old popup",-1,Fs,8192);Fs->popup_task=pl_old;}
I64 PLPriorFinish(I64 ok){Fs->popup_task=NULL;if(TaskValidate(pl_old))Kill(pl_old);return ok;}
I64 PLPrevious(Bool retire=FALSE){I64 r,ok;PLPrior;if(retire)r=PopUp("Kill(pl_old);42;",Fs);else r=PopUp("42;",Fs);ok=r==42;if(retire)ok&=!Fs->popup_task;else ok&=Fs->popup_task==pl_old;return PLPriorFinish(ok);}
U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 *v=CAlloc(16);v[0]=PLPrevious;v[1]=PLPrevious(TRUE);
U8 *line=MStrPrint("EXPORT popup-owner.bin %X %X\n",v,16);Report(line);Free(line);
Report("DONE original popup ownership\n");
