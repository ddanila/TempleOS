//Shared original playback loop; the wrapper supplies the captured focus and ring.
U0 PlaySysMacroCore(I64 n,CTask *task,CJob *macro_head)
{
  U8 *m;
  if(TaskValidate(task)) {
    LBtr(&sys_semas[SEMA_RECORD_MACRO],0);
    m=SysMacro2Str(macro_head);
    try {
      while(n-- && TaskValidate(task)) {
        if(task==Fs) InStr("%s",m);
        else XTalkStrWait(task,"%s",m);
      }
    } catch { Free(m); }
    Free(m);
  }
}
