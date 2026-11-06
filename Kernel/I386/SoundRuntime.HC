//Share the original recording queue, repeat-enable and semaphore behavior.
#define IsDbgMode NativeIsDebugMode
#include "/Kernel/SoundCaptureCore.HC"

Bool Mute(Bool val)
{//The native replacement for the original PUSHFD/CLI/POPFD region.
  Bool res;
  U32 flags;
  if(val) {
    flags=I386IrqSave;
    Snd;
    res=LBts(&sys_semas[SEMA_MUTE],0);
    I386IrqRestore(flags);
  } else res=LBtr(&sys_semas[SEMA_MUTE],0);
  return res;
}
Bool IsMute() { return Bt(&sys_semas[SEMA_MUTE],0); }
U0 NativeSoundCaptureInit()
{
  QueInit(&scrncast.snd_head);
  scrncast.t0_now=Now;
  scrncast.t0_tS=tS;
  scrncast.ona=scrncast.snd_head.ona=0;
}
