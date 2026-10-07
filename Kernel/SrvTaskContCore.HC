U0 SrvTaskCont()
{//Act as server task in a loop handling commands.
  I64 old_flags=GetRFlags;
  FlushMsgs;
  while (TRUE) {
    SetRFlags(old_flags&~512);
    if (JobsHndlr(old_flags) && Fs->title_src==TTS_TASK_NAME)
      MemCpy(Fs->task_title,Fs->task_name,TASK_NAME_LEN);
    FlushMsgs;
    LBts(&Fs->task_flags,TASKf_IDLE);
    LBts(&Fs->task_flags,TASKf_AWAITING_MSG);
    Yield;
    SetRFlags(old_flags);
  }
}

